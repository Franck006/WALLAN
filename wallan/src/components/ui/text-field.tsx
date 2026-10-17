import type { InputHTMLAttributes } from "react";

type TextFieldProps = InputHTMLAttributes<HTMLInputElement> & {
  label: string;
  error?: string;
  hint?: string;
};

export function TextField({
  id,
  label,
  error,
  hint,
  className = "",
  ...props
}: TextFieldProps) {
  const errorId = error ? `${id}-error` : undefined;
  const hintId = hint ? `${id}-hint` : undefined;
  const describedBy = [errorId, hintId].filter(Boolean).join(" ") || undefined;

  return (
    <div className="w-full">
      <label htmlFor={id} className="mb-1.5 block text-sm font-medium text-anthracite-700">
        {label}
      </label>
      <input
        {...props}
        id={id}
        aria-describedby={describedBy}
        aria-invalid={Boolean(error)}
        className={`min-h-11 w-full rounded-xl border-2 bg-white px-4 py-2.5 text-sm text-anthracite-700 outline-none transition-[border-color,box-shadow] placeholder:text-anthracite-300 focus:border-forest-500 focus:ring-3 focus:ring-forest-400/15 disabled:bg-anthracite-50 ${
          error ? "border-red-700 focus:border-red-700 focus:ring-red-700/10" : "border-anthracite-700/10"
        } ${className}`}
      />
      {error ? (
        <p id={errorId} className="mt-1.5 flex items-start gap-1.5 text-sm text-red-700">
          <span aria-hidden="true">●</span>
          {error}
        </p>
      ) : hint ? (
        <p id={hintId} className="mt-1.5 text-sm text-anthracite-700/60">
          {hint}
        </p>
      ) : null}
    </div>
  );
}
