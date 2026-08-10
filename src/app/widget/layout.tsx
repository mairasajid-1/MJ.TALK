import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Chat Widget",
  description: "Embedded chat widget",
};

export default function WidgetLayout({ children }: { children: React.ReactNode }) {
  return (
    <div style={{ 
      background: "transparent",
      minHeight: "100vh",
      width: "100%"
    }}>
      {children}
      <style jsx global>{`
        html, body {
          background: transparent !important;
          overflow: hidden;
        }
      `}</style>
    </div>
  );
}
