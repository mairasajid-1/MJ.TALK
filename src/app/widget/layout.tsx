import type { Metadata } from "next";
import "./widget.css";

export const metadata: Metadata = {
  title: "Chat Widget",
  description: "Embedded chat widget",
};

export default function WidgetLayout({ children }: { children: React.ReactNode }) {
  return <>{children}</>;
}
