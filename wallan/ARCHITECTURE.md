# Architecture de WALLAN

Ce document définit l’organisation du code applicatif. Son objectif est de permettre à plusieurs développeurs de travailler en parallèle en limitant les dépendances implicites et les conflits Git.

## Principes généraux

- `src/app` décrit la navigation et les points d’entrée HTTP de Next.js.
- `src/modules` contient le code propre à chaque domaine métier.
- `src/components` contient uniquement les composants partagés par plusieurs domaines.
- `src/lib` regroupe les intégrations techniques transversales.
- Une route ou un composant reste aussi mince que possible : il orchestre le module concerné sans réimplémenter ses règles métier.
- Les composants sont des Server Components par défaut. La directive `"use client"` n’est ajoutée qu’aux frontières nécessitant des événements, des hooks React ou des API du navigateur.

## Dossiers principaux

### `src/app`

Ce dossier suit l’App Router de Next.js 16.

- `(auth)` regroupera les écrans d’authentification. Les parenthèses créent un groupe d’organisation et ne font pas partie de l’URL.
- `(main)` regroupera les écrans principaux de l’application.
- `admin` accueillera l’interface d’administration.
- `api` accueillera les futurs Route Handlers, répartis par domaine.
- `layout.tsx`, `page.tsx` et `globals.css` restent les fichiers racine existants.

Un dossier placé dans `app` n’expose aucune route tant qu’il ne contient pas de fichier `page.tsx` ou `route.ts`. Les dossiers préparés dans cette architecture sont donc non fonctionnels jusqu’à l’implémentation explicite de ces fichiers.

Les fichiers spécifiques à une seule route peuvent être colocalisés plus tard dans des dossiers privés préfixés par `_`, par exemple `_components` ou `_lib`.

### `src/modules`

Chaque module représente un domaine fonctionnel autonome :

- `auth` : inscription, connexion et sessions ;
- `profils` : profils, compétences, projets personnels et disponibilités ;
- `entraide` : questions, réponses, tags et résolution ;
- `mentorat` : offres, espaces, exercices, soumissions et messages ;
- `administration` : signalements, modération et gestion administrative ;
- `publications` : publications, commentaires et réactions ;
- `communautes` : communautés, adhésions et rôles communautaires ;
- `collaboration` : projets collaboratifs et revues de code ;
- `opportunites` : création et publication des opportunités ;
- `notifications` : consultation et gestion des notifications.

Un module utilise la structure suivante :

```text
module/
├── components/
├── services/
├── repositories/
├── schemas/
└── types/
```

#### `components`

Contient les composants React propres au domaine. Ils affichent les données et délèguent les opérations aux services ou aux actions serveur prévues par le module. Un composant réutilisable par plusieurs domaines doit être déplacé dans `src/components`.

#### `services`

Contient les cas d’usage et règles métier. Un service orchestre les validations, les autorisations applicatives et les repositories. Il ne contient pas de JSX et ne dépend pas d’un composant React.

Les politiques RLS restent la source d’autorité côté base ; une vérification dans un service améliore l’expérience utilisateur mais ne remplace jamais la sécurité PostgreSQL.

#### `repositories`

Contient l’accès aux données Supabase : requêtes, mutations et conversion des résultats. Un repository ne contient ni rendu, ni règle de présentation, ni logique métier complexe.

Les repositories serveur utilisent le client de `src/lib/supabase/server.ts`. Un accès navigateur, lorsqu’il est réellement nécessaire, utilise `src/lib/supabase/client.ts`. Une clé `service_role` ne doit jamais être importée ou exposée dans le code client.

#### `schemas`

Contient les schémas Zod du module pour valider les entrées de formulaires, paramètres, corps de requêtes et données externes. La validation est effectuée à la frontière qui reçoit la donnée, puis les types validés sont transmis aux services.

Aucune dépendance n’est ajoutée dans cette étape : les fichiers Zod seront créés lorsque la bibliothèque sera effectivement introduite et validée dans le projet.

#### `types`

Contient les types TypeScript propres au domaine : modèles de lecture, commandes de service et résultats métier. Les types réellement transversaux vont dans `src/types`.

### `src/components`

- `ui` contient les primitives visuelles génériques : boutons, champs, boîtes de dialogue ou indicateurs.
- `layout` contient les éléments de structure partagés : navigation, en-tête, pied de page ou conteneurs.

Ces composants ne doivent pas importer directement un repository métier. Ils reçoivent leurs données et leurs actions par propriétés ou par une interface explicitement prévue.

### `src/hooks`

Contient uniquement les hooks React réutilisés par plusieurs modules. Un hook spécifique à un domaine reste dans ce module, au plus près de ses composants. Tout fichier utilisant des hooks React côté navigateur appartient à une frontière marquée `"use client"`.

### `src/types`

Contient les types transversaux stables. Éviter d’y placer tous les types par défaut : un type utilisé par un seul module doit rester dans `src/modules/<module>/types`.

### `src/lib`

Contient les intégrations et utilitaires techniques partagés. Les clients Supabase existants restent dans `src/lib/supabase` :

- `server.ts` pour les Server Components, services serveur, actions serveur et Route Handlers ;
- `client.ts` pour les Client Components qui doivent réellement communiquer avec Supabase depuis le navigateur.

## Frontend, services et repositories

Le flux recommandé est le suivant :

```text
Page ou Route Handler → composant / action → service → repository → Supabase
```

- Le frontend gère le rendu, les interactions et les états d’interface.
- Le service exprime le cas d’usage et coordonne les règles métier.
- Le repository encapsule la persistance et les détails de Supabase.
- Le schéma valide les données à l’entrée du système.

Une page peut lire directement un service serveur, mais elle ne doit pas reconstruire une requête Supabase complexe ni dupliquer une règle métier.

## Règles d’importation

- Utiliser l’alias `@/` pour les imports depuis `src`.
- Un module peut importer `src/components`, `src/hooks`, `src/types` et `src/lib`.
- Un module ne doit pas importer les fichiers internes d’un autre module sans contrat explicite.
- Lorsqu’un partage entre modules est nécessaire, exposer une petite API publique depuis le module propriétaire ou déplacer l’élément réellement transversal.
- Éviter les dépendances circulaires. Le domaine propriétaire de la donnée reste responsable de son repository.
- `app` peut importer les modules ; les modules ne doivent pas importer `app`.
- Les composants partagés ne doivent pas dépendre d’un module métier précis.

## Séparation serveur et client

- Les fichiers sont serveur par défaut dans l’App Router.
- Ajouter `"use client"` uniquement dans le plus petit composant nécessitant une interaction navigateur.
- Ne jamais importer un repository serveur ou `src/lib/supabase/server.ts` depuis une frontière client.
- Ne transmettre aux Client Components que des données sérialisables.
- Garder les secrets et opérations privilégiées exclusivement côté serveur.
- Les variables exposées avec le préfixe `NEXT_PUBLIC_` doivent être considérées comme publiques.
- Les Route Handlers valident leurs entrées avant d’appeler un service et ne contiennent pas directement les règles métier.

## Conventions de nommage

- Dossiers et fichiers non composants : `kebab-case`, par exemple `mot-de-passe-oublie` ou `creer-exercice.ts`.
- Composants React et types exportés : `PascalCase`, par exemple `ExerciseCard` ou `MentoratSpace`.
- Fonctions, variables et hooks : `camelCase`, avec le préfixe `use` pour les hooks.
- Schémas Zod : suffixe `Schema`, par exemple `createExerciseSchema`.
- Services : nom orienté cas d’usage, par exemple `createExercise` ou `moderatePublication`.
- Repositories : nom orienté ressource et opération, sans vocabulaire d’interface.
- Constantes globales : `UPPER_SNAKE_CASE` uniquement lorsqu’elles sont réellement constantes.
- Éviter les fichiers génériques `utils.ts`, `helpers.ts` ou `types.ts` trop volumineux ; préférer un nom décrivant leur responsabilité.

## Travail parallèle et Git

- Attribuer clairement un ou plusieurs modules à chaque développeur.
- Limiter les modifications transversales et les annoncer avant de les commencer.
- Préférer de petits changements cohérents afin de faciliter la revue et l’intégration.
- Ne pas reformater un fichier sans lien avec la tâche en cours.
- Ne pas modifier simultanément les fichiers racine partagés sans coordination, notamment `layout.tsx`, `globals.css`, les configurations et les clients Supabase.
- Ajouter une migration au lieu de modifier une migration déjà partagée ou déployée.
- Synchroniser régulièrement la branche de travail et résoudre les conflits dans le module propriétaire.
- Vérifier TypeScript, ESLint et les tests du module avant intégration.
- Ne jamais versionner `.env.local`, des clés privées ou une clé Supabase `service_role`.

## Évolution de l’architecture

Cette structure prépare les frontières sans imposer d’abstraction prématurée. Un dossier vide peut disparaître s’il ne devient pas utile. Toute nouvelle dépendance entre modules doit être justifiée par un cas d’usage concret et documentée lorsqu’elle modifie les règles ci-dessus.
