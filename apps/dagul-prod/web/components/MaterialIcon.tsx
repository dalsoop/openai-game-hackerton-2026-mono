import type { JSX } from "react";

export function MaterialIcon({ name }: { name: string }): JSX.Element {
  return <span className="material-symbols-outlined" aria-hidden="true">{name}</span>;
}
