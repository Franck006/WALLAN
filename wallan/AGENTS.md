<!-- BEGIN:nextjs-agent-rules -->

## This is NOT the Next.js you know

This version has breaking changes — APIs, conventions, and file structure may all differ from your training data. Read the relevant guide in `node_modules/next/dist/docs/` (resolved from this file's directory; in monorepos the `next` package may not be visible from the repo root) before writing any code. Heed deprecation notices.

This block is written and re-added by `next dev` — verify at `node_modules/next/dist/server/lib/generate-agent-files.js`. Removing it from a diff only re-creates the uncommitted change; committing it with your work keeps the tree clean.

<!-- END:nextjs-agent-rules -->

## Règles du projet WALLAN

Avant toute modification, lire intégralement `ARCHITECTURE.md` et `docs/REPARTITION_TACHES.md`, puis les migrations et tests du module concerné.

- Respecter les modules attribués ; ne pas modifier celui de l'autre développeur sans accord.
- Ne jamais modifier une migration partagée ou déployée ; créer une migration corrective.
- Ne jamais lancer `supabase db push`, `db reset` ou une opération destructive sans autorisation explicite.
- Ne jamais exposer de secret, clé `service_role` ou donnée réelle dans le code, les logs ou `NEXT_PUBLIC_*`.
- Faire des changements minimaux et ciblés, sans refactorisation hors périmètre.
- Commenter en français uniquement une règle métier complexe ou une décision de sécurité utile.
- Exécuter TypeScript, ESLint et les tests pertinents, puis signaler tout test non exécuté.
- Ne créer aucun commit et ne pousser aucune branche sans demande explicite.
