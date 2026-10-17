import Link from "next/link";
import type { ReactNode } from "react";

export function AuthShell({ children }: { children: ReactNode }) {
  return (
    <main className="grid min-h-dvh bg-ivory-100 lg:grid-cols-2">
      <section className="relative hidden overflow-hidden bg-forest-500 p-12 text-ivory-50 lg:flex lg:flex-col lg:justify-between" aria-label="Présentation de WALLAN">
        <div aria-hidden="true" className="absolute inset-0 opacity-20 [background-image:linear-gradient(45deg,transparent_45%,#e8bd77_45%,#e8bd77_55%,transparent_55%),linear-gradient(-45deg,transparent_45%,#e8bd77_45%,#e8bd77_55%,transparent_55%)] [background-size:48px_48px]" />
        <Link href="/" className="relative w-fit rounded-lg font-heading text-3xl font-extrabold tracking-tight focus-visible:outline-none focus-visible:ring-3 focus-visible:ring-gold-400 focus-visible:ring-offset-2 focus-visible:ring-offset-forest-500">
          WALLAN<span className="text-solar-500">.</span>
        </Link>

        <div className="relative max-w-xl">
          <div className="mb-6 inline-flex rounded-full border border-gold-400/20 bg-gold-400/15 px-3 py-1.5 text-xs font-medium text-gold-400">
            Le savoir nous unit
          </div>
          <h2 className="font-heading text-4xl font-bold leading-tight">
            Rejoignez la communauté des développeurs africains
          </h2>
          <p className="mt-4 text-lg leading-relaxed text-ivory-50/75">
            Apprenez, partagez et avancez avec des développeurs qui comprennent vos défis.
          </p>
          <ul className="mt-8 space-y-4 text-sm text-ivory-50/85">
            {[
              "Obtenez des réponses à vos questions techniques",
              "Trouvez des mentors adaptés à votre parcours",
              "Découvrez des opportunités tech en Afrique",
            ].map((benefit) => (
              <li key={benefit} className="flex items-start gap-3">
                <span aria-hidden="true" className="mt-0.5 flex size-6 shrink-0 items-center justify-center rounded-full bg-gold-400/20 text-gold-400">✓</span>
                <span className="leading-6">{benefit}</span>
              </li>
            ))}
          </ul>
        </div>

        <p className="relative max-w-sm font-mono text-xs leading-relaxed text-ivory-50/60">
          {"// Une communauté pensée pour apprendre, transmettre et construire ensemble."}
        </p>
      </section>

      <section className="flex items-center justify-center px-4 py-12 sm:px-6 lg:p-12">
        {children}
      </section>
    </main>
  );
}
