"use client";

import { useState, useEffect, useRef, useCallback } from "react";
import {
  MessageCircle, X, Send, User,
  RotateCcw, Volume2, VolumeX, Minimize2, UserCheck,
} from "lucide-react";
import { cn, generateSessionId } from "@/lib/utils";
import type { ChatMessage, PreChatFormData } from "@/types";
import { useTypingIndicator } from "@/hooks/use-typing-indicator";

/* ─── types ─── */
export interface WidgetConfig {
  id: string;
  name: string;
  widget_color: string;
  avatar_url: string | null;
  pre_chat_form_enabled: boolean;
  escalation_keyword: string;
  status: "active" | "inactive";
}

type UIMessage = {
  id: string;
  role: "user" | "assistant" | "admin";
  content: string;
  timestamp: Date;
  status?: "sending" | "sent" | "failed"; // Phase 4: delivery state
};

interface WidgetAppProps {
  config: WidgetConfig;
  /** Absolute base URL for API calls. The component ignores this and always
   *  derives the origin from window.location so it works on localhost AND prod. */
  apiUrl?: string;
}

/* ─── tiny markdown renderer ─── */
function renderMarkdown(text: string): string {
  return text
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/\*\*(.+?)\*\*/g, "<strong>$1</strong>")
    .replace(/\*(.+?)\*/g, "<em>$1</em>")
    .replace(/`(.+?)`/g, '<code style="background:#f1f5f9;padding:1px 4px;border-radius:3px;font-size:0.85em">$1</code>')
    .replace(/\[(.+?)\]\((.+?)\)/g, '<a href="$2" target="_blank" rel="noopener" style="color:inherit;text-decoration:underline">$1</a>')
    .replace(/\n/g, "<br/>");
}

/* ─── soft ping via Web Audio ─── */
function playPing() {
  try {
    const AudioCtx = window.AudioContext || (window as unknown as { webkitAudioContext: typeof AudioContext }).webkitAudioContext;
    const ctx  = new AudioCtx();
    const osc  = ctx.createOscillator();
    const gain = ctx.createGain();
    osc.connect(gain);
    gain.connect(ctx.destination);
    osc.frequency.setValueAtTime(880, ctx.currentTime);
    osc.frequency.exponentialRampToValueAtTime(440, ctx.currentTime + 0.2);
    gain.gain.setValueAtTime(0.15, ctx.currentTime);
    gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.35);
    osc.start(ctx.currentTime);
    osc.stop(ctx.currentTime + 0.35);
  } catch { /* silent */ }
}

/* ─── component ─── */
export function WidgetApp({ config }: WidgetAppProps) {
  // Always use the iframe's own origin for API calls — works on localhost + Vercel
  const getApiBase = () =>
    typeof window !== "undefined" ? window.location.origin : "";

  const [isOpen, setIsOpen]           = useState(false);
  const [isMinimized, setIsMinimized] = useState(false);
  const [messages, setMessages]       = useState<UIMessage[]>([]);
  const [input, setInput]             = useState("");
  const [isTyping, setIsTyping]       = useState(false);
  const [conversationId, setConversationId] = useState<string | null>(null);
  const [unreadCount, setUnreadCount] = useState(0);
  const [soundEnabled, setSoundEnabled] = useState(true);
  const [sessionId] = useState(() => {
    if (typeof window === "undefined") return generateSessionId();
    const stored = sessionStorage.getItem(`si_${config.id}`);
    if (stored) return stored;
    const id = generateSessionId();
    sessionStorage.setItem(`si_${config.id}`, id);
    return id;
  });
  const [showPreChat, setShowPreChat] = useState(config.pre_chat_form_enabled);
  const [preChatData, setPreChatData] = useState<PreChatFormData>({ name: "", email: "" });
  const [isEscalated, setIsEscalated] = useState(false);
  const [escalationPending, setEscalationPending] = useState(false);
  const [error, setError]             = useState<string | null>(null);
  const [hasNewMessage, setHasNewMessage] = useState(false);
  // Phase 3: agent typing indicator visible in widget
  const [agentIsTyping, setAgentIsTyping] = useState(false);
  // Phase 4: chat state for UX feedback
  const [chatState, setChatState] = useState<
    "idle" | "ai_responding" | "human_requested" | "waiting_agent" | "agent_joined" | "resolved"
  >("idle");
  const [sendRetryFn, setSendRetryFn] = useState<(() => void) | null>(null);

  const messagesEndRef = useRef<HTMLDivElement>(null);
  const inputRef       = useRef<HTMLTextAreaElement>(null);
  const abortRef       = useRef<AbortController | null>(null);

  // Phase 3: typing indicator hook
  const { onKeystroke: typingKeystroke, onSend: typingSend } = useTypingIndicator({
    conversationId,
    selfRole: "user",
    watchRole: "admin",
    onRemoteTyping: setAgentIsTyping,
  });

  const scrollToBottom = useCallback(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  }, []);

  useEffect(() => { scrollToBottom(); }, [messages, scrollToBottom]);

  /* ── Restore session ── */
  useEffect(() => {
    const storedConvId = sessionStorage.getItem(`conv_${config.id}`);
    if (storedConvId) setConversationId(storedConvId);
    const storedMsgs = sessionStorage.getItem(`msgs_${config.id}`);
    if (storedMsgs) {
      try {
        const parsed = JSON.parse(storedMsgs);
        setMessages(parsed.map((m: UIMessage) => ({ ...m, timestamp: new Date(m.timestamp) })));
        setShowPreChat(false);
      } catch { /* ignore */ }
    }
    const storedEscalated = sessionStorage.getItem(`esc_${config.id}`);
    if (storedEscalated === "1") setIsEscalated(true);
  }, [config.id]);

  /* ── Supabase Realtime — admin messages ── */
  useEffect(() => {
    if (!conversationId) return;
    let channel: { unsubscribe: () => void } | null = null;

    const setup = async () => {
      const { createBrowserClient } = await import("@supabase/ssr");
      const supabase = createBrowserClient(
        process.env.NEXT_PUBLIC_SUPABASE_URL!,
        process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
      );
      channel = supabase
        .channel(`widget_msgs:${conversationId}`)
        .on(
          "postgres_changes",
          { event: "INSERT", schema: "public", table: "messages", filter: `conversation_id=eq.${conversationId}` },
          (payload: { new: { id: string; role: string; content: string; created_at: string } }) => {
            const row = payload.new;
            if (row.role !== "admin") return;
            const newMsg: UIMessage = { id: row.id, role: "admin", content: row.content, timestamp: new Date(row.created_at) };
            setMessages((prev) => {
              if (prev.some((m) => m.id === row.id)) return prev;
              return [...prev, newMsg];
            });
            if (!isOpen) { setUnreadCount((c) => c + 1); setHasNewMessage(true); }
            setChatState("agent_joined");
            if (soundEnabled) playPing();
          }
        )
        .subscribe();
    };

    setup().catch(console.error);
    return () => { channel?.unsubscribe(); };
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [conversationId]);

  /* ── Persist messages ── */
  useEffect(() => {
    if (messages.length > 0) sessionStorage.setItem(`msgs_${config.id}`, JSON.stringify(messages));
  }, [messages, config.id]);

  /* ── Persist escalation state ── */
  useEffect(() => {
    if (isEscalated) sessionStorage.setItem(`esc_${config.id}`, "1");
  }, [isEscalated, config.id]);

  /* ── postMessage API ── */
  useEffect(() => {
    const handler = (e: MessageEvent) => {
      if (e.data?.type === "SUPPORTAI_OPEN")  handleOpen();
      if (e.data?.type === "SUPPORTAI_CLOSE") setIsOpen(false);
    };
    window.addEventListener("message", handler);
    return () => window.removeEventListener("message", handler);
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  useEffect(() => {
    if (isOpen) { setUnreadCount(0); setHasNewMessage(false); setTimeout(() => inputRef.current?.focus(), 150); }
  }, [isOpen]);

  /* ── Auto-resize textarea ── */
  const handleInputChange = (e: React.ChangeEvent<HTMLTextAreaElement>) => {
    setInput(e.target.value);
    e.target.style.height = "auto";
    e.target.style.height = Math.min(e.target.scrollHeight, 120) + "px";
    typingKeystroke();
  };

  /* ── Init conversation ── */
  const initConversation = async (visitor?: PreChatFormData) => {
    const api = getApiBase();
    const browserInfo = typeof navigator !== "undefined" ? navigator.userAgent.slice(0, 100) : undefined;
    const pageUrl = typeof window !== "undefined" ? window.location.href : undefined;

    const res = await fetch(`${api}/api/conversations`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        chatbotId: config.id, sessionId,
        visitorName: visitor?.name || null, visitorEmail: visitor?.email || null,
        pageUrl, browserInfo,
      }),
    });

    if (res.status === 429) {
      const data = await res.json().catch(() => ({}));
      // Free plan chat limit reached — show a friendly message
      const limitMsg = data.message ?? "This service has reached its monthly chat limit. Please try again next month or contact support.";
      throw new Error(`LIMIT_REACHED:${limitMsg}`);
    }

    if (!res.ok) throw new Error("Failed to start conversation");
    const data = await res.json();
    const convId = data.conversation.id;
    setConversationId(convId);
    sessionStorage.setItem(`conv_${config.id}`, convId);
    return convId;
  };

  /* ── Send message ── */
  const sendMessage = async (text: string, convId: string) => {
    const api = getApiBase();

    // Persist user message
    await fetch(`${api}/api/messages`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ conversationId: convId, role: "user", content: text }),
    });

    const history = messages.filter((m) => m.role !== "admin");
    const apiMessages: ChatMessage[] = [
      ...history.map((m) => ({ role: m.role as "user" | "assistant", content: m.content })),
      { role: "user" as const, content: text },
    ];

    setIsTyping(true);
    setChatState("ai_responding");
    setError(null);
    setSendRetryFn(null);
    abortRef.current = new AbortController();

    try {
      const res = await fetch(`${api}/api/chat`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          messages: apiMessages,
          chatbotId: config.id,
          conversationId: convId,
          sessionId,
        }),
        signal: abortRef.current.signal,
      });

      if (!res.ok) {
        let errMsg = `Error ${res.status}`;
        try { const j = await res.json(); errMsg = j.error ?? errMsg; } catch { /* ignore */ }
        throw new Error(errMsg);
      }

      const contentType = res.headers.get("content-type") || "";
      
      if (contentType.includes("text/event-stream")) {
        const tempId = `ai_${Date.now()}`;
        let fullText = "";
        
        setMessages((prev) => [
          ...prev,
          { id: tempId, role: "assistant" as const, content: "", timestamp: new Date() },
        ]);
        
        setIsTyping(false);

        const reader = res.body?.getReader();
        const decoder = new TextDecoder();

        if (reader) {
          while (true) {
            const { done, value } = await reader.read();
            if (done) break;
            const chunk = decoder.decode(value, { stream: true });
            fullText += chunk;
            setMessages((prev) =>
              prev.map((m) => m.id === tempId ? { ...m, content: fullText } : m)
            );
          }
        }

        const keyword = config.escalation_keyword ?? "ESCALATE";
        if (fullText.toUpperCase().includes(keyword.toUpperCase())) {
          setIsEscalated(true);
          setChatState("waiting_agent");
        } else {
          setChatState("idle");
        }
        if (soundEnabled && fullText) playPing();
        
      } else {
        const replyText = await res.text();
        if (!replyText.trim()) throw new Error("Empty response from AI");

        setMessages((prev) => [
          ...prev,
          { id: `ai_${Date.now()}`, role: "assistant" as const, content: replyText, timestamp: new Date() },
        ]);

        const keyword = config.escalation_keyword ?? "ESCALATE";
        if (replyText.toUpperCase().includes(keyword.toUpperCase())) {
          setIsEscalated(true);
          setChatState("waiting_agent");
        } else {
          setChatState("idle");
        }
        if (soundEnabled) playPing();
      }
      
      setIsTyping(false);

    } catch (err: unknown) {
      if (err instanceof Error && err.name === "AbortError") return;
      setIsTyping(false);
      setChatState("idle");
      const errMsg = err instanceof Error ? err.message : "Something went wrong.";
      setError(errMsg);
      // Store retry function
      setSendRetryFn(() => () => sendMessage(text, convId));
    } finally {
      setIsTyping(false);
    }
  };

  const handleSend = async () => {
    const text = input.trim();
    if (!text || isTyping) return;
    const msgId = `user_${Date.now()}`;
    setMessages((prev) => [...prev, { id: msgId, role: "user", content: text, timestamp: new Date(), status: "sending" }]);
    setInput("");
    if (inputRef.current) inputRef.current.style.height = "auto";
    typingSend();
    try {
      let convId = conversationId;
      if (!convId) convId = await initConversation();
      // Mark as sent
      setMessages((prev) => prev.map((m) => m.id === msgId ? { ...m, status: "sent" } : m));
      await sendMessage(text, convId!);
    } catch (err) {
      // Mark as failed
      setMessages((prev) => prev.map((m) => m.id === msgId ? { ...m, status: "failed" } : m));
      const errMsg = err instanceof Error ? err.message : "Message failed to send.";
      if (errMsg.startsWith("LIMIT_REACHED:")) {
        setError(errMsg.replace("LIMIT_REACHED:", ""));
      } else {
        setError("Message failed to send.");
      }
      setSendRetryFn(() => () => {
        setMessages((prev) => prev.map((m) => m.id === msgId ? { ...m, status: "sending" } : m));
        setError(null);
        sendMessage(text, conversationId!).catch(() => {
          setMessages((prev) => prev.map((m) => m.id === msgId ? { ...m, status: "failed" } : m));
        });
      });
    }
  };

  const handlePreChatSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      await initConversation(preChatData);
      setShowPreChat(false);
      setMessages([{ id: "welcome", role: "assistant", content: `Hi ${preChatData.name || "there"}! 👋 How can I help you today?`, timestamp: new Date() }]);
    } catch (err) {
      const msg = err instanceof Error ? err.message : "";
      if (msg.startsWith("LIMIT_REACHED:")) {
        setError(msg.replace("LIMIT_REACHED:", ""));
      } else {
        setError("Failed to start chat. Please try again.");
      }
    }
  };

  const handleOpen = () => {
    setIsOpen(true);
    setIsMinimized(false);
    if (!config.pre_chat_form_enabled && messages.length === 0 && !conversationId) {
      setMessages([{ id: "welcome", role: "assistant", content: `Hi! 👋 I'm ${config.name}. How can I help you today?`, timestamp: new Date() }]);
    }
  };

  const handleReset = () => {
    abortRef.current?.abort();
    setMessages([]); setConversationId(null); setIsEscalated(false);
    setEscalationPending(false);
    setError(null); setInput(""); setShowPreChat(config.pre_chat_form_enabled);
    sessionStorage.removeItem(`conv_${config.id}`);
    sessionStorage.removeItem(`msgs_${config.id}`);
    sessionStorage.removeItem(`esc_${config.id}`);
    if (!config.pre_chat_form_enabled) {
      setMessages([{ id: "welcome", role: "assistant", content: `Hi! 👋 I'm ${config.name}. How can I help you today?`, timestamp: new Date() }]);
    }
  };

  /* ── Request human agent ── */
  const handleRequestHuman = async () => {
    if (escalationPending || isEscalated) return;
    setEscalationPending(true);
    setError(null);

    try {
      let convId = conversationId;
      if (!convId) convId = await initConversation();

      const api = getApiBase();
      const res = await fetch(`${api}/api/chat/escalate`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          chatbotId: config.id,
          sessionId,
          conversationId: convId,
          visitorName: preChatData.name || null,
          visitorEmail: preChatData.email || null,
          pageUrl: typeof window !== "undefined" ? window.location.href : undefined,
          browserInfo: typeof navigator !== "undefined" ? navigator.userAgent.slice(0, 100) : undefined,
        }),
      });

      if (!res.ok) throw new Error("Failed to reach support");

      const data = await res.json();
      if (data.conversationId) {
        setConversationId(data.conversationId);
        sessionStorage.setItem(`conv_${config.id}`, data.conversationId);
      }

      setIsEscalated(true);
      setChatState("waiting_agent");
      // System message added by the API is picked up via Realtime — no need to push manually
    } catch {
      setError("Could not connect to support. Please try again.");
    } finally {
      setEscalationPending(false);
    }
  };

  const color       = config.widget_color;
  const mutedColor  = `${color}15`; // Very subtle background
  const fmt = (d: Date) => d.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" });

  /* ══════════════════ RENDER ══════════════════ */
  return (
    <div className="fixed bottom-6 right-6 z-[2147483647] flex flex-col items-end gap-3 font-sans select-none">

      {/* ── Chat window ── */}
      {isOpen && !isMinimized && (
        <div
          className="flex flex-col overflow-hidden border shadow-2xl"
          style={{ 
            width: "380px", 
            height: "600px", 
            background: "#ffffff",
            borderRadius: "12px",
            borderColor: "#e5e7eb",
            animation: "widgetSlideIn 0.3s cubic-bezier(0.16, 1, 0.3, 1)" 
          }}
        >
          {/* Header - Clean & Minimal */}
          <div 
            className="flex items-center justify-between px-5 py-4 border-b flex-shrink-0"
            style={{ 
              background: "#ffffff",
              borderColor: "#f3f4f6"
            }}
          >
            <div className="flex items-center gap-3">
              <div className="w-9 h-9 rounded-lg flex items-center justify-center flex-shrink-0"
                style={{ background: mutedColor }}>
                {config.avatar_url
                  // eslint-disable-next-line @next/next/no-img-element
                  ? <img src={config.avatar_url} alt="Bot" className="w-full h-full rounded-lg object-cover" />
                  : <MessageCircle className="w-4.5 h-4.5" style={{ color }} />}
              </div>
              <div className="flex-1 min-w-0">
                <p className="font-medium text-sm text-gray-900 leading-tight">{config.name}</p>
                <div className="flex items-center gap-1.5 mt-0.5">
                  <span 
                    className="w-1.5 h-1.5 rounded-full flex-shrink-0"
                    style={{ 
                      background: chatState === "agent_joined" ? "#10b981" : "#94a3b8",
                      opacity: chatState === "ai_responding" || chatState === "waiting_agent" ? 0.6 : 1
                    }} 
                  />
                  <span className="text-gray-500 text-xs font-normal">
                    {escalationPending ? "Connecting..." :
                     chatState === "ai_responding" ? "Typing..." :
                     chatState === "waiting_agent" ? "Connecting to agent..." :
                     chatState === "agent_joined" ? "Agent online" :
                     isEscalated ? "Waiting for agent..." :
                     "Online"}
                  </span>
                </div>
              </div>
            </div>
            <div className="flex items-center gap-1">
              <button 
                onClick={() => setSoundEnabled((s) => !s)} 
                className="w-8 h-8 flex items-center justify-center rounded-md hover:bg-gray-100 transition-colors"
                title={soundEnabled ? "Mute" : "Unmute"}
              >
                {soundEnabled ? 
                  <Volume2 className="w-4 h-4 text-gray-500" /> : 
                  <VolumeX className="w-4 h-4 text-gray-500" />
                }
              </button>
              <button 
                onClick={() => setIsMinimized(true)} 
                className="w-8 h-8 flex items-center justify-center rounded-md hover:bg-gray-100 transition-colors"
                title="Minimize"
              >
                <Minimize2 className="w-4 h-4 text-gray-500" />
              </button>
              <button 
                onClick={handleReset} 
                className="w-8 h-8 flex items-center justify-center rounded-md hover:bg-gray-100 transition-colors"
                title="New chat"
              >
                <RotateCcw className="w-4 h-4 text-gray-500" />
              </button>
              <button 
                onClick={() => setIsOpen(false)} 
                className="w-8 h-8 flex items-center justify-center rounded-md hover:bg-gray-100 transition-colors"
                title="Close"
              >
                <X className="w-4 h-4 text-gray-500" />
              </button>
            </div>
          </div>

          {/* Pre-chat form */}
          {showPreChat ? (
            <div className="flex-1 overflow-y-auto px-6 py-6" style={{ background: "#fafafa" }}>
              <div className="mb-6">
                <h3 className="font-semibold text-gray-900 text-base mb-2">Start a conversation</h3>
                <p className="text-gray-600 text-sm">We typically reply within a few minutes.</p>
              </div>
              {error && (
                <div className="mb-4 text-sm text-red-600 bg-red-50 border border-red-100 rounded-lg px-4 py-3">
                  {error}
                </div>
              )}
              <form onSubmit={handlePreChatSubmit} className="space-y-4">
                <div>
                  <label className="text-sm font-medium text-gray-700 block mb-2">Name</label>
                  <input 
                    type="text" 
                    value={preChatData.name} 
                    onChange={(e) => setPreChatData((p) => ({ ...p, name: e.target.value }))} 
                    placeholder="Your name" 
                    required 
                    className="w-full border border-gray-300 bg-white rounded-lg px-3.5 py-2.5 text-sm text-gray-900 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-gray-900 focus:border-transparent transition-shadow" 
                  />
                </div>
                <div>
                  <label className="text-sm font-medium text-gray-700 block mb-2">Email</label>
                  <input 
                    type="email" 
                    value={preChatData.email} 
                    onChange={(e) => setPreChatData((p) => ({ ...p, email: e.target.value }))} 
                    placeholder="you@example.com" 
                    required 
                    className="w-full border border-gray-300 bg-white rounded-lg px-3.5 py-2.5 text-sm text-gray-900 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-gray-900 focus:border-transparent transition-shadow" 
                  />
                </div>
                <button 
                  type="submit" 
                  className="w-full py-2.5 rounded-lg text-white font-medium text-sm transition-all hover:opacity-90 active:scale-[0.99] mt-2"
                  style={{ background: "#18181b" }}
                >
                  Start chat
                </button>
              </form>
            </div>
          ) : (
            <>
              {/* Messages - Clean minimal style */}
              <div className="flex-1 overflow-y-auto px-5 py-5 space-y-4" style={{ scrollBehavior: "smooth", background: "#fafafa" }}>
                {messages.map((msg, i) => {
                  const isUser = msg.role === "user";
                  const showTime = i === messages.length - 1 || Math.abs(messages[i + 1].timestamp.getTime() - msg.timestamp.getTime()) > 60000;
                  return (
                    <div key={msg.id} className={cn("flex gap-2.5", isUser ? "justify-end" : "justify-start")}>
                      {!isUser && (
                        <div className="w-7 h-7 rounded-lg flex items-center justify-center flex-shrink-0 mt-0.5"
                          style={{ background: mutedColor }}>
                          {msg.role === "admin"
                            ? <User className="w-3.5 h-3.5" style={{ color }} />
                            : config.avatar_url
                              // eslint-disable-next-line @next/next/no-img-element
                              ? <img src={config.avatar_url} alt="" className="w-full h-full rounded-lg object-cover" />
                              : <MessageCircle className="w-3.5 h-3.5" style={{ color }} />}
                        </div>
                      )}
                      <div className={cn("flex flex-col max-w-[75%]", isUser && "items-end")}>
                        <div
                          className={cn(
                            "px-3.5 py-2.5 text-sm leading-relaxed break-words",
                            isUser 
                              ? "bg-gray-900 text-white rounded-2xl rounded-tr-md" 
                              : "bg-white text-gray-900 rounded-2xl rounded-tl-md border border-gray-200",
                            msg.role === "admin" && "!bg-blue-600 !text-white !border-blue-500"
                          )}
                          {...(isUser ? {} : { dangerouslySetInnerHTML: { __html: renderMarkdown(msg.content) } })}
                        >
                          {isUser ? msg.content : undefined}
                        </div>
                        {showTime && (
                          <span className="text-xs text-gray-400 mt-1 px-1">{fmt(msg.timestamp)}</span>
                        )}
                      </div>
                    </div>
                  );
                })}

                {/* Typing indicator - minimal */}
                {(isTyping || agentIsTyping) && (
                  <div className="flex gap-2.5 justify-start">
                    <div className="w-7 h-7 rounded-lg flex items-center justify-center flex-shrink-0"
                      style={{ background: mutedColor }}>
                      {agentIsTyping
                        ? <User className="w-3.5 h-3.5" style={{ color }} />
                        : <MessageCircle className="w-3.5 h-3.5" style={{ color }} />}
                    </div>
                    <div className="bg-white border border-gray-200 rounded-2xl rounded-tl-md px-4 py-3">
                      <div className="flex gap-1 items-center h-4">
                        {[0, 1, 2].map((i) => (
                          <div 
                            key={i} 
                            className="w-1.5 h-1.5 rounded-full typing-dot bg-gray-400"
                          />
                        ))}
                      </div>
                    </div>
                  </div>
                )}

                {error && (
                  <div className="bg-red-50 border border-red-200 rounded-lg px-4 py-3">
                    <p className="text-sm text-red-800 font-medium mb-1">Something went wrong</p>
                    <p className="text-sm text-red-600">{error}</p>
                    <div className="flex items-center gap-2 mt-2">
                      {sendRetryFn && (
                        <button 
                          onClick={() => { sendRetryFn(); }} 
                          className="text-sm text-red-700 hover:text-red-900 font-medium"
                        >
                          Retry
                        </button>
                      )}
                      <button 
                        onClick={() => setError(null)} 
                        className="text-sm text-red-600 hover:text-red-800"
                      >
                        Dismiss
                      </button>
                    </div>
                  </div>
                )}

                {/* Chat state indicators */}
                {chatState === "waiting_agent" && (
                  <div className="bg-blue-50 border border-blue-200 rounded-lg px-4 py-3">
                    <p className="text-sm font-medium text-blue-900 mb-1">Connecting to support</p>
                    <p className="text-sm text-blue-700">A team member will join shortly.</p>
                  </div>
                )}

                {chatState === "agent_joined" && (
                  <div className="bg-green-50 border border-green-200 rounded-lg px-4 py-3">
                    <p className="text-sm font-medium text-green-900">Agent connected</p>
                    <p className="text-sm text-green-700 mt-0.5">You're now chatting with a team member.</p>
                  </div>
                )}

                {isEscalated && chatState !== "waiting_agent" && chatState !== "agent_joined" && (
                  <div className="bg-blue-50 border border-blue-200 rounded-lg px-4 py-3">
                    <p className="text-sm text-blue-800">A team member has been notified and will join shortly.</p>
                  </div>
                )}

                {!isEscalated && messages.length > 0 && (
                  <div className="flex justify-center">
                    <button
                      onClick={handleRequestHuman}
                      disabled={escalationPending}
                      className="flex items-center gap-2 text-sm px-4 py-2 rounded-lg border border-gray-300 bg-white text-gray-700 font-medium transition-all hover:bg-gray-50 active:scale-95 disabled:opacity-50 disabled:cursor-not-allowed"
                    >
                      {escalationPending ? (
                        <>
                          <span className="w-3.5 h-3.5 rounded-full border-2 border-gray-400 border-t-transparent animate-spin" />
                          Connecting...
                        </>
                      ) : (
                        <>
                          <UserCheck className="w-3 h-3" />
                          Talk to a Human Agent
                        </>
                      )}
                    </button>
                  </div>
                )}

                <div ref={messagesEndRef} />
              </div>

              {/* Input bar - Clean & Minimal */}
              <div className="border-t px-4 py-3.5 flex-shrink-0" style={{ background: "#ffffff", borderColor: "#f3f4f6" }}>
                <div className="flex items-end gap-2.5">
                  <textarea
                    ref={inputRef}
                    value={input}
                    onChange={handleInputChange}
                    onKeyDown={(e) => { if (e.key === "Enter" && !e.shiftKey) { e.preventDefault(); handleSend(); } }}
                    placeholder="Type a message…"
                    rows={1}
                    className="flex-1 resize-none rounded-lg border bg-white px-3.5 py-2.5 text-sm focus:outline-none focus:ring-1 focus:border-gray-400 placeholder:text-gray-400 transition-all text-gray-900"
                    style={{ 
                      maxHeight: "120px", 
                      minHeight: "40px", 
                      lineHeight: "1.5",
                      borderColor: "#e5e7eb"
                    }}
                  />
                  <button
                    onClick={handleSend}
                    disabled={!input.trim() || isTyping}
                    className="w-10 h-10 rounded-lg flex items-center justify-center flex-shrink-0 transition-all disabled:opacity-40 hover:bg-gray-800 active:scale-[0.97] mb-0.5"
                    style={{ background: "#18181b" }}
                  >
                    <Send className="w-4 h-4 text-white" />
                  </button>
                </div>

                <p className="text-center text-xs text-gray-300 mt-3 select-none">
                  Powered by <span className="font-medium text-gray-400">MJ.TALK</span>
                </p>
              </div>
            </>
          )}
        </div>
      )}

      {/* ── Minimized pill - Clean & Minimal ── */}
      {isOpen && isMinimized && (
        <button
          onClick={() => setIsMinimized(false)}
          className="flex items-center gap-2.5 rounded-full px-4 py-3 bg-white border shadow-lg transition-all hover:shadow-xl active:scale-[0.98]"
          style={{ borderColor: "#e5e7eb" }}
        >
          <div className="w-6 h-6 rounded-lg flex items-center justify-center" style={{ background: mutedColor }}>
            <MessageCircle className="w-3.5 h-3.5" style={{ color }} />
          </div>
          <span className="text-sm font-medium text-gray-900">{config.name}</span>
          {unreadCount > 0 && (
            <span className="bg-red-500 text-white text-xs font-semibold rounded-full min-w-[20px] h-5 flex items-center justify-center px-1.5">
              {unreadCount > 9 ? "9+" : unreadCount}
            </span>
          )}
        </button>
      )}

      {/* ── Launcher button - Clean & Minimal ── */}
      {!isOpen && (
        <div className="relative">
          {hasNewMessage && (
            <div className="absolute inset-0 rounded-full animate-ping opacity-40 bg-gray-900" />
          )}
          <button
            onClick={handleOpen}
            className="w-14 h-14 rounded-full shadow-lg flex items-center justify-center transition-all hover:shadow-xl hover:scale-105 active:scale-95 bg-white border"
            style={{ borderColor: "#e5e7eb" }}
            aria-label="Open chat"
          >
            <MessageCircle className="w-6 h-6 text-gray-900" />
          </button>
          {unreadCount > 0 && (
            <div className="absolute -top-1 -right-1 min-w-[20px] h-5 bg-red-500 text-white text-xs font-semibold rounded-full flex items-center justify-center px-1.5 shadow-md">
              {unreadCount > 9 ? "9+" : unreadCount}
            </div>
          )}
        </div>
      )}

      <style>{`
        @keyframes widgetSlideIn {
          from { opacity: 0; transform: translateY(12px) scale(0.97); }
          to   { opacity: 1; transform: translateY(0) scale(1); }
        }
        .typing-dot {
          animation: typingBounce 1.4s ease-in-out infinite;
        }
        .typing-dot:nth-child(2) { animation-delay: 0.2s; }
        .typing-dot:nth-child(3) { animation-delay: 0.4s; }
        @keyframes typingBounce {
          0%, 60%, 100% { transform: translateY(0); }
          30% { transform: translateY(-4px); }
        }
      `}</style>
    </div>
  );
}
