import type { ButtonHTMLAttributes, ReactNode } from "react";

type ButtonProps = ButtonHTMLAttributes<HTMLButtonElement> & {
  children: ReactNode;
  loading?: boolean;
  loadingLabel?: string;
};

export function Button({
  children,
  className = "",
  disabled,
  loading = false,
  loadingLabel = "Chargement…",
  ...props
}: ButtonProps) {
  return (
    <button
      {...props}
      disabled={disabled || loading}
      aria-busy={loading}
      className={`inline-flex min-h-12 items-center justify-center gap-2 rounded-xl bg-solar-500 px-6 py-3 text-base font-semibold text-anthracite-700 transition-[background-color,transform,box-shadow] duration-150 hover:bg-solar-600 active:scale-[0.98] focus-visible:outline-none focus-visible:ring-3 focus-visible:ring-forest-400 focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50 ${className}`}
    >
      {loading ? (
        <>
          <span
            aria-hidden="true"
            className="size-4 animate-spin rounded-full border-2 border-anthracite-700/25 border-t-anthracite-700"
          />
          {loadingLabel}
        </>
      ) : (
        children
      )}
    </button>
  );
}
