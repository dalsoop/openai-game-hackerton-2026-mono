"use client";
import { useState } from "react";

const styles = {
  wrap: { display: "flex", gap: "0.5rem", alignItems: "center" } as const,
  input: {
    background: "#1a1f2a",
    border: "1px solid #252b38",
    borderRadius: 8,
    color: "#e8e6e1",
    padding: "0.6rem 1rem",
    fontSize: "1rem",
    outline: "none",
    flex: 1,
    maxWidth: 220,
  } as const,
  btn: {
    background: "#2f6bff",
    color: "#fff",
    border: "none",
    borderRadius: 8,
    padding: "0.6rem 1.2rem",
    fontSize: "0.9rem",
    fontWeight: 700,
    cursor: "pointer",
  } as const,
};

interface Props {
  initial: string;
  onConfirm: (name: string) => void;
}

export default function NicknameInput({ initial, onConfirm }: Props) {
  const [value, setValue] = useState(initial || "");

  function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    const trimmed = value.trim();
    if (trimmed) onConfirm(trimmed);
  }

  return (
    <form onSubmit={handleSubmit} style={styles.wrap}>
      <input
        style={styles.input}
        value={value}
        onChange={(e) => setValue(e.target.value)}
        placeholder="닉네임을 입력하세요"
        maxLength={16}
      />
      <button type="submit" style={styles.btn}>
        접속
      </button>
    </form>
  );
}
