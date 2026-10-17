# Répartition des tâches et conventions d'équipe

Ce document complète [ARCHITECTURE.md](../ARCHITECTURE.md). Toute personne ou tout agent lit les deux documents avant de modifier le projet. Chaque développeur possède le parcours complet de ses modules : frontend, services, repositories, validations, types et tests. Il ne modifie pas le module de l'autre sans accord.

Les tables citées correspondent aux 26 migrations actuelles ; cette description n'autorise pas la modification d'une migration existante.

## Développeur 1

| Module | Objectif et fonctionnalités | Tables | Code et livrables |
|---|---|---|---|
| Auth et profils | Sessions, inscription/connexion, récupération, profil public, compétences, liens, projets personnels et disponibilités | `profiles`, `user_roles`, `profil_technologie`, `profil_centre_interet`, `lien_profil`, `projet`, `projet_technologie`, `disponibilite`; référentiels associés | `src/modules/auth`, `src/modules/profils`, `(auth)`, API auth/profils ; écrans, services, repositories, validations et tests |
| Mentorat | Offres, espaces, adhésions, messages, exercices, soumissions et retours | `offre_mentorat`, `offre_mentorat_domaine`, `espace_mentorat`, `membre_espace`, `message_mentorat`, `exercice`, `soumission_exercice` | `src/modules/mentorat`, route et API mentorat ; parcours mentor/mentoré et tests RLS |
| Entraide | Questions, tags/technologies, réponses, réponse acceptée et suppression logique | `question`, `question_technologie`, `question_tag`, `reponse` | `src/modules/entraide`, route questions et API entraide ; validations et tests d'accès |
| Administration | Signalements, modération logique, historique, comptes, communautés et opportunités administrées | `signalement`, `action_moderation`, `user_roles`, avec accès coordonné aux contenus | `src/modules/administration`, `src/app/admin`, API administration ; interface, audit et tests positifs/négatifs |

## Développeur 2

| Module | Objectif et fonctionnalités | Tables | Code et livrables |
|---|---|---|---|
| Publications/feed | Publications, commentaires, réactions, fil et suppression logique | `publication`, `commentaire`, `reaction` | `src/modules/publications`, route feed, API publications ; composants, services, validations et tests de visibilité |
| Communautés | Découverte, adhésion, départ et rôles locaux | `communaute`, `adhesion_communaute` | `src/modules/communautes`, route/API communautés ; parcours, rôles et tests RLS |
| Collaboration | Projets collectifs, candidatures, membres, revues et commentaires | `projet_collaboratif`, `membre_projet`, `revue_code`, `commentaire_revue` | `src/modules/collaboration`, route projets, API collaboration ; validations et tests d'appartenance |
| Opportunités | Brouillon, publication, modification, archivage et catalogue | `opportunite`, `type_opportunite`, `pays` | `src/modules/opportunites`, route/API opportunités ; validations chronologiques et tests |
| Notifications | Liste, état lu/non lu et liens vers les ressources | `notification` | `src/modules/notifications`; contrat d'émission partagé, affichage, repository et tests. Toute future route API est coordonnée. |

## Dépendances et sujets transversaux

Profils et référentiels alimentent la plupart des modules. Administration modère publications/communautés/opportunités. Notifications consomme des événements de plusieurs domaines. Ces croisements utilisent un contrat public convenu ; un module n'importe pas les fichiers internes d'un autre.

Coordonner avant de modifier : `layout.tsx`, `globals.css`, composants UI, hooks/types partagés, clients Supabase, variables d'environnement, dépendances npm, migrations, RLS, triggers, fonctions `SECURITY DEFINER`, privilèges et navigation.

## Conventions

- Frontend : rendu et interactions, jamais l'unique barrière d'autorisation.
- Services : cas d'usage et règles métier, sans JSX.
- Repositories : accès Supabase ; les RLS restent l'autorité.
- Validations : `src/modules/<module>/schemas`, à chaque frontière d'entrée, après ajout explicite de Zod.
- Server Components par défaut ; `"use client"` uniquement à la plus petite frontière interactive.
- Changements minimaux, ciblés, sans refactorisation hors périmètre.
- Commentaires en français uniquement pour une règle complexe ou une décision de sécurité utile.

## Sécurité Supabase

- Ne jamais modifier une migration partagée/déployée ; ajouter une migration corrective.
- Examiner RLS, triggers, privilèges et fonctions de sécurité avant une évolution.
- Ne jamais contourner les RLS ou désactiver les protections dans les tests.
- Ne jamais exposer `service_role`, JWT, mot de passe ou secret dans Git, les logs ou `NEXT_PUBLIC_*`.
- Ne jamais exécuter `supabase db push`, `db reset` ou une opération destructive sans autorisation explicite et cible confirmée.
- Préserver le blocage des comptes `SUSPENDU`/`SUPPRIME`, les identités et les champs d'audit.

## Git

- `main` : stable, après validation commune.
- `develop` : intégration des travaux revus.
- `feature/<module>-<sujet>` ou `fix/<module>-<sujet>` : branches courtes de chaque développeur.

Synchronisation recommandée :

```bash
git fetch origin
git switch develop
git pull --ff-only origin develop
git switch feature/<module>-<sujet>
git rebase develop
```

Un merge peut remplacer le rebase si l'équipe le décide. Ne jamais réécrire une branche partagée sans accord. Résoudre les conflits avec le propriétaire du module, particulièrement pour migrations, sécurité et configuration.

Commits : `type(module): description concise`, avec `feat`, `fix`, `test`, `docs` ou `chore`. Une demande de fusion décrit le périmètre, les fichiers sensibles, toute nouvelle migration, les vérifications et les tests manuels restants. Un agent ne commit, ne pousse et ne fusionne que sur demande explicite.

## Vérifications et définition de fini

```bash
npx tsc --noEmit
npm run lint
```

Si Supabase local est déjà disponible et autorisé : `npx supabase test db`. La vérification ne déclenche jamais un accès Cloud, `db push` ou `db reset`.

Le travail est prêt lorsque le périmètre est respecté, les entrées validées, la séparation composant/service/repository conservée, les autorisations garanties en base, les tests réussis ou signalés non exécutés, la documentation à jour et aucun secret inclus.
