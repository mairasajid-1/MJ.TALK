import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "../globals.css";
import "./widget.css";

const inter = Inter({ 
  subsets: ["latin"], 
  variable: "--font-inter", 
  weight: ["400", "500", "600"] 
});

export const metadata: Metadata = {
  title: "Chat Widget",
  description: "Embedded chat widget",
};

export default function WidgetLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className={inter.variable}>
      <body className={inter.className} suppressHydrationWarning>
        {children}
      </body>
    </html>
  );
}
