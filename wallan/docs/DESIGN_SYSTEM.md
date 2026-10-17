# Design System WALLAN

> Référence normative de toutes les interfaces WALLAN — version initiale du 17 octobre 2026.

## 1. Statut et lecture

Ce document formalise l'identité observée dans `bolt-reference/project` et complète les cas que la maquette ne couvre pas. Il s'applique aux interfaces publiques, authentifiées et administratives.

- **[BOLT]** : règle ou valeur directement observée dans la maquette ; elle doit être conservée.
- **[COMPLÉMENT]** : convention ajoutée pour rendre le système complet sans créer une nouvelle charte.
- **[ACCESSIBILITÉ]** : correction obligatoire lorsqu'une pratique Bolt ne satisfait pas le contraste, le clavier ou la sémantique.

Priorité en cas de conflit : accessibilité, présent document, imitation ponctuelle de Bolt. Toute nouvelle couleur, police, échelle d'espacement ou famille d'arrondis exige d'abord une mise à jour de ce document.

## 2. Audit de la maquette

**[BOLT]** L'analyse couvre les pages landing, authentification, configuration de profil, fil, profil, questions, mentorat, communautés, opportunités et notifications, ainsi que `Layout.tsx`, `ui.tsx`, `index.css` et `tailwind.config.js`.

L'identité est constante : fond ivoire, surfaces blanches, vert forêt structurant, orange solaire pour les actions saillantes, or en accent, texte anthracite, titres Sora, corps Inter, code JetBrains Mono, cartes arrondies, bordures légères, icônes Lucide et motifs africains géométriques discrets.

**[COMPLÉMENT]** Bolt ne définit pas complètement : tokens sémantiques et contrastes, échelles normatives, focus clavier, états complets, tableaux/pagination, skeletons/alertes, interfaces de collaboration et d'administration, responsive détaillé, WCAG et conventions Tailwind CSS 4.

## 3. Principes

1. Chaleureux et crédible : ivoire pour le fond, forêt pour la confiance et la structure.
2. Communautaire : personnes et contributions priment sur les métriques.
3. Dense mais respirable : cartes compactes, formulaires plus espacés.
4. Orange avec intention : action importante ou sélection, jamais décoration omniprésente.
5. Le code est un contenu de premier rang, traité dans une surface dédiée.
6. La couleur ne porte jamais seule un sens.

## 4. Fondations

### 4.1 Couleurs extraites

**[BOLT]** Ces palettes exactes sont les seules couleurs de marque autorisées.

| Palette | 50 | 100 | 200 | 300 | 400 | 500/défaut | 600 | 700 | 800 | 900 |
|---|---|---|---|---|---|---|---|---|---|---|
| `forest` | `#E8F0EE` | `#C9DDD8` | `#9BC0B6` | `#6DA394` | `#3F8772` | `#164A41` | `#123D36` | `#0E302B` | `#0A2320` | `#061714` |
| `solar` | `#FFF1E9` | `#FFE0D0` | `#FFC2A1` | `#FFA572` | `#FF8F4F` | `#FF7A36` | `#E5651F` | `#CC5115` | `#B23E0D` | `#992E06` |
| `gold` | `#FDF6EC` | `#FAE8D0` | `#F4D1A1` | `#EDBB72` | `#E8BD77` | `#D9A55E` | `#C68D48` | `#B37533` | `#A05E22` | `#8D4815` |
| `anthracite` | `#E5E5E7` | `#C9C9CD` | `#A2A2A8` | `#7A7A82` | `#51515B` | `#363640` | `#2D2D37` | `#20212B` | `#1A1B24` | `#131420` |

Ivoire : `ivory-50 #FFFEFB`, `ivory-100/default #FFF9F0`, `ivory-200 #FFF3E0`, `ivory-300 #FFE9CC`, `ivory-400 #FFDDB3`, `ivory-500 #FFD099`.

### 4.2 Tokens sémantiques

**[COMPLÉMENT]** Les composants consomment des rôles, pas des teintes arbitraires.

| Rôle | Valeur | Usage |
|---|---|---|
| canvas | `#FFF9F0` | fond global |
| surface / surface-subtle | `#FFFFFF` / `#FFFEFB` | cartes, contrôles / zones secondaires |
| text | `#20212B` | texte principal |
| text-muted | `rgba(32,33,43,.60)` | texte secondaire |
| text-subtle | `rgba(32,33,43,.45)` | métadonnée non essentielle, `14px` min. |
| brand / brand-hover | `#164A41` / `#123D36` | structure, liens, action institutionnelle |
| accent / accent-hover | `#FF7A36` / `#E5651F` | action saillante, sélection |
| highlight | `#E8BD77` | accent or |
| border / border-subtle | `rgba(32,33,43,.10)` / `.06` | contrôles / séparateurs |
| focus | `#3F8772` | anneau de focus |
| success / fond | `#15803D` / `#F0FDF4` | résolu, accepté |
| warning / fond | `#B45309` / `#FFFBEB` | attention, attente |
| danger / fond | `#B91C1C` / `#FEF2F2` | erreur, rejet, suppression |
| info / fond | `#164A41` / `#E8F0EE` | information neutre |

**[ACCESSIBILITÉ]** L'ivoire/blanc sur `solar-500` ne contraste pas assez pour du texte normal : un bouton solaire emploie donc un libellé anthracite. Sur forêt, utiliser l'ivoire ; sur or, l'anthracite. Les opacités `.30/.40` vues dans Bolt sont réservées aux décorations ou informations redondantes. Aucun mode sombre automatique n'est autorisé avant définition d'une palette complète.

### 4.3 Typographie

**[BOLT]** Titres : Sora 600–800. Corps/interface : Inter 400–700. Code : JetBrains Mono 400–600. Fall-backs : `system-ui, sans-serif` et `ui-monospace, monospace`.

| Style | Mobile | `md+` | Interligne | Graisse |
|---|---:|---:|---:|---:|
| Display | `36px` | `60px` | 1.08 | Sora 800 |
| H1 | `30px` | `36px` | 1.2 | Sora 700 |
| H2 | `24px` | `30px` | 1.25 | Sora 700 |
| H3 | `18px` | `20px` | 1.35 | Sora 600 |
| H4 | `16px` | `18px` | 1.4 | Sora 600 |
| Corps large | `18px` | `18px` | 1.65 | Inter 400 |
| Corps | `16px` | `16px` | 1.6 | Inter 400 |
| Compact | `14px` | `14px` | 1.5 | Inter 400/500 |
| Légende | `12px` | `12px` | 1.4 | Inter 500 |
| Code | `14px` | `14px` | 1.7 | Mono 400 |

Limiter les lignes à `65–75ch`. Ne pas sauter de niveau de titre. `12px` est réservé aux badges et métadonnées complémentaires.

### 4.4 Espacement et grille

**[BOLT/COMPLÉMENT]** Base `4px`; valeurs autorisées : `0, 2, 4, 6, 8, 12, 16, 20, 24, 32, 40, 48, 64, 80, 96px`.

- écart interne : compact `8–12px`, normal `16px`, carte `20–24px`, formulaire `24–32px` ;
- cartes espacées de `12–16px`, blocs de `24–32px`, sections marketing de `64–80px` ;
- header `64px`; contrôle et cible tactile `44px` minimum ;
- conteneur large `1280px` (`max-w-7xl`), gouttière `16px`, puis `24px` à `lg` ;
- contenu focalisé `1024px` (`max-w-5xl`), formulaire `448–672px` ;
- layout sidebar : `minmax(0,1fr) 300px`, gap `24px` ; détail compact `280px`.

### 4.5 Formes et élévation

Rayons **[BOLT]** : `6px` micro-contrôle, `8px` tag/navigation, `12px` bouton/champ/code, `16px` carte/panneau, `24px` hero/CTA, `9999px` avatar et pilule.

Carte : bordure `1px solid rgba(32,33,43,.06)`, ombre `0 1px 2px rgba(32,33,43,.05)`. Carte interactive au hover/focus : bordure forêt 20 %, ombre `0 10px 24px rgba(32,33,43,.08)`. Les champs gardent une bordure `2px` afin d'éviter tout déplacement au focus.

### 4.6 Icônes, avatars et motifs

**[BOLT]** Lucide uniquement : `16px` dans bouton/métadonnée, `18–20px` en navigation, `24–32px` en état vide. Icône seule : nom accessible et tooltip si ambiguë.

Avatars ronds : `16, 32, 36, 40/44, 56, 88px`, `object-cover`; initiales sur `forest-50` si image absente. Alt utile ou vide si le nom adjacent est redondant. Les motifs kente/tissage restent limités aux hero, auth, bannières et CTA, opacité `10–20 %`, jamais derrière un texte long.

## 5. Composants

### 5.1 Boutons

**[BOLT]** `inline-flex`, centré, gap `8px`, rayon `12px`, texte medium.

| Taille | Hauteur | Padding | Texte | Icône |
|---|---:|---|---:|---:|
| sm | `36px` visuel, cible `44px` | `6px 12px` | `12px` | `14–16px` |
| md | `44px` | `10px 20px` | `14px` | `16–18px` |
| lg | `48px` | `12px 24px` | `16px` | `18–20px` |

- primary : forêt/ivoire, hover `forest-600` ;
- accent : solaire/anthracite, hover `solar-600` ;
- outline : bordure forêt 20 %, texte forêt, hover `forest-50` ;
- ghost : transparent/anthracite, hover forêt 5 % + texte forêt ;
- danger **[COMPLÉMENT]** : danger/blanc, seulement pour destruction confirmée ;
- link **[COMPLÉMENT]** : forêt sans conteneur, souligné au hover/focus.

États obligatoires : hover, active `scale(.98)`, `focus-visible` anneau `3px` focus avec offset `2px`, disabled opacité `.5`, loading avec spinner et largeur conservée. Loading porte `aria-busy` et un libellé précis (« Publication… »).

### 5.2 Navigation et liens

Un lien navigue, un bouton agit. Liens de contenu forêt, soulignés au hover/focus. **[BOLT]** Header sticky de `64px`, ivoire 90 %, blur, bordure basse. Actif : texte forêt + fond forêt 5 %; onglet : bordure basse `2px`.

À `lg`, navigation complète. Sous `lg`, tiroir droit de `288px` max avec overlay anthracite 30–40 %. Il piège le focus, ferme avec `Escape`, restaure le focus et bloque le scroll. Un statut de notification doit être annoncé, pas seulement montré par un point orange.

### 5.3 Cartes, listes et code

**[BOLT]** Carte standard : blanche, rayon `16px`, padding `20px` (`24px` en détail). Une carte interactive a un état focus visible. Types : contenu social, annuaire, statistique, sélection (bordure `2px` + coche) et liste compacte avec séparateurs.

Bloc de code : `anthracite-800`, barre `anthracite-900/50`, ivoire 90 %, rayon `12px`, padding `16px`, scroll horizontal, police mono `14px`. Afficher langage et Copier; annoncer « Copié » via `aria-live`.

### 5.4 Formulaires

**[BOLT]** Champ blanc, hauteur `44px` min., padding `12px 16px`, rayon `12px`, bordure anthracite 10 % de `2px`, texte `14px`; label au-dessus, `14px` medium, marge `6px`; focus bordure forêt + anneau forêt 10–15 %.

**[COMPLÉMENT]** Label lié par `for/id`; placeholder jamais utilisé comme label. Aide/compteur relié par `aria-describedby`. Erreur : bordure et message danger, icône, `aria-invalid`, valeur conservée. Disabled : `anthracite-50`; readonly : surface subtile. Radios/checkboxes sous `fieldset/legend`, cible `44px`. Switch uniquement pour effet immédiat. Préférer le select natif. Formulaire long : étapes avec texte (« Étape 2 sur 5 »). En échec, focus sur le résumé d'erreurs.

### 5.5 Tags, badges et statuts

**[BOLT]** Tag : rayon `8px`, padding horizontal `10px` et vertical `4px`, texte `12px`, fond forêt 5 %, texte forêt, bordure forêt 10 %. Badge : pilule comparable. Tags = taxonomies/filtres; badges = états/comptes.

- ouvert/info : forêt + `forest-50` ;
- attente : warning + fond warning ;
- accepté/résolu/actif : success + fond success ;
- refusé/erreur/suspendu : danger + fond danger ;
- archivé/neutre : anthracite 60 % + `anthracite-50`.

Écrire le statut en toutes lettres, éventuellement avec icône `12–14px`.

### 5.6 États système

**[COMPLÉMENT]**

- skeleton calé sur la géométrie finale, `anthracite-50`, animation `1.5s`, désactivée en reduced motion ;
- spinner pour attente courte, toujours nommé ;
- empty state : icône dans carré `64px`/rayon `16px`, titre Sora `18px`, texte court, une action max.; distinguer vide et aucun résultat ;
- erreur page : explication non technique, Réessayer et retour, jamais de trace/Supabase ;
- alerte inline : fond pâle, bordure, icône, titre; `role=alert` seulement si urgent ;
- toast : bas-droite desktop, bas-centre mobile, durée min. `5s`, pause au hover, fermeture; erreur persistante; région `aria-live` ;
- succès structurant : confirmation inline/page, pas seulement un toast.

### 5.7 Modales et menus

**[BOLT]** Modale centrée, overlay anthracite 40 % + blur, largeur `512px`, rayon `16px`, `max-height:90vh`, padding `24px`. **[ACCESSIBILITÉ]** Utiliser `<dialog>` ou équivalent conforme : titre associé, focus piégé, `Escape`, restauration du focus. Ne pas fermer par overlay si des données risquent d'être perdues. Une confirmation destructive nomme la cible. Sur petit mobile, une modale complexe devient plein écran. Menus : options `40–44px` et navigation clavier.

### 5.8 Tableaux et pagination

**[COMPLÉMENT]** Réserver les tableaux aux données comparables. En-tête `14px/600` sur ivoire ou `anthracite-50`, lignes `52–60px`, séparateurs subtils, nombres à droite, actions en dernière colonne. Mobile : colonnes essentielles puis cartes/détails extensibles. Pagination avec Précédent/Suivant, page courante et filtres dans l'URL. Tri avec `aria-sort`; sélection en masse comptée et destruction confirmée.

## 6. Responsive

**[BOLT]** Breakpoints Tailwind : `sm 640`, `md 768`, `lg 1024`, `xl 1280`, `2xl 1536px`. Conception mobile-first.

| Zone | `<640px` | `640–1023px` | `≥1024px` |
|---|---|---|---|
| Gouttière | `16px` | `16–24px` | `24px` |
| Navigation | logo/actions/menu | idem | complète |
| Cartes | 1 colonne | 2 si possible | 2–4 selon contenu |
| Sidebar | panneau explicite | panneau/accordéon | colonne `280–300px` |
| Filtres | empilés/tiroir | 2 colonnes | ligne ou panneau |
| Modale | marge `16px`/plein écran | contrainte | `448–672px` |

Une fonctionnalité ne disparaît jamais avec la sidebar : la déplacer vers un bouton ou accordéon. Employer `min-width:0`, ellipsis seulement pour métadonnées, scroll explicite pour code/tableaux. Tester à `320, 375, 768, 1024, 1280px` et zoom 200 %.

Structures autorisées : catalogue (titre, filtres, résultats, pagination), détail (retour, contenu, métadonnées, associé), social (composeur, flux, découverte), gestion (indicateurs, filtres, tableau, panneau), formulaire centré, marketing (hero, preuves, communauté, CTA).

## 7. Conventions par module

### Mentorat

**[BOLT]** Conserver annuaire, cartes mentor, onglets demandes/espaces/gestion, statuts et espace collectif. **[COMPLÉMENT]** Exercices : échéance, progression, état. Soumissions : brouillon, remis, commenté, validé. Identifier clairement échange privé/collectif.

### Entraide

**[BOLT]** Technologie, statut, vues, auteur, réponses, réponse acceptée verte et éditeur sombre. **[COMPLÉMENT]** Vote utile distinct de l'acceptation; seul l'auteur voit Accepter. Réponse acceptée = icône + texte + bordure/fond. Recherche/filtres dans l'URL.

### Collaboration

**[COMPLÉMENT]** Réutiliser les cartes annuaire : titre, résumé, technologies, rôles, maturité, membres, activité. Détail : aperçu, besoins, membres, candidatures, revues. Statuts projet : brouillon neutre, recrutement forêt, en cours solaire/anthracite, terminé succès, archivé neutre. Candidatures : attente/acceptée/refusée. Revues : blocs de code existants et commentaires, sans nouveau thème.

### Administration

**[COMPLÉMENT]** Même identité, densité légèrement accrue : navigation latérale à `lg`, breadcrumb/titre, métriques, filtres, tableau, panneau détail. Rouge seulement pour risque/destruction. Décision : cible, motif, auteur, date, statut. Audit chronologique. Suspension/suppression/modération exigent motif, confirmation et retour persistant. Ne jamais révéler de donnée sensible pour une commodité UI.

### Autres modules

- publications : auteur/contenu/actions, commentaires dessous ;
- communautés : carte catalogue, Globe/Hash, membres, adhésion ;
- opportunités : type, organisation, lieu, modalité, échéance, statut; expirée visuellement distincte ;
- notifications : groupes temporels, non lu sur `forest-50`, indicateur + texte accessible, « Tout marquer comme lu » ;
- profils : bannière forêt/motif, avatar chevauchant, identité, bio, compétences, projets, disponibilités.

## 8. Accessibilité

**[ACCESSIBILITÉ]** Cible minimale : WCAG 2.2 AA.

- contraste `4.5:1` texte normal, `3:1` grand texte et composants ;
- clavier complet, ordre logique, focus toujours visible ;
- régions sémantiques, un H1/page, boutons pour actions et liens pour navigation ;
- cibles `44×44px` ou espacement équivalent ;
- labels persistants, erreurs reliées, résumé d'erreurs ;
- alt pertinent, décorations ignorées, identité jamais transmise seulement par drapeau ;
- `aria-live=polite` pour résultats, `role=alert` pour urgence ;
- respecter `prefers-reduced-motion` ;
- `<html lang="fr">`, changements de langue indiqués, dates/nombres localisés ;
- utilisation à zoom 200 % sans perte ni scroll horizontal global ;
- tout état coloré est doublé par texte ou icône ;
- erreurs d'authentification sans divulgation de compte ou donnée sensible.

## 9. Mouvement

**[BOLT]** `fade-in 300ms ease-out`, `slide-up 400ms ease-out` depuis `12px`, `slide-in-right 300ms ease-out` depuis `20px`. **[COMPLÉMENT]** Micro-interaction `120–180ms`, composant `200–300ms`, panneau `300–400ms`. Animer seulement opacité et transform. En reduced motion, supprimer translations/scales non essentielles.

## 10. Next.js 16 et Tailwind CSS 4

### Polices et architecture

Utiliser `next/font/google` au layout racine pour Sora, Inter et JetBrains Mono avec variables `--font-sora`, `--font-inter`, `--font-jetbrains-mono`; ne pas reprendre l'`@import` Google bloquant de Bolt. Déclarer `lang="fr"`. Server Components par défaut; client seulement pour interaction/focus/état navigateur.

Primitives génériques dans `src/components/ui`, layout/navigation dans `src/components/layout`, styles métier dans `src/modules/<module>/components`. Variantes typées (`variant`, `size`, `status`), attributs HTML natifs transmis, aucune couleur libre par module.

### Tokens Tailwind 4

Tailwind 4 est CSS-first. Déclarer toute la palette du §4.1 avec `@theme` dans `globals.css`, puis les rôles sémantiques dans `:root` :

```css
@import "tailwindcss";

@theme {
  --color-forest-50: #e8f0ee;
  --color-forest-500: #164a41;
  --color-forest-600: #123d36;
  --color-solar-500: #ff7a36;
  --color-solar-600: #e5651f;
  --color-ivory-50: #fffefb;
  --color-ivory-100: #fff9f0;
  --color-gold-400: #e8bd77;
  --color-anthracite-700: #20212b;
  --color-anthracite-800: #1a1b24;
  --font-heading: var(--font-sora);
  --font-body: var(--font-inter);
  --font-mono: var(--font-jetbrains-mono);
}
```

Ne pas recopier partout les longues chaînes Bolt : créer une primitive lorsqu'elle est réellement partagée, sans ajouter de dépendance uniquement pour assembler des classes.

Utiliser `next/image` avec dimensions, `next/link` pour naviguer, l'URL pour recherche/filtres/page/onglet partageable, et `loading.tsx`, `error.tsx`, `not-found.tsx` au segment pertinent. Les mutations affichent un pending local et un retour accessible. Ne coder aucune valeur isolée si un token existe.

## 11. Checklist de revue

- [ ] Tokens et primitives du présent document utilisés.
- [ ] Hiérarchie claire et un seul H1.
- [ ] Loading, vide, erreur, succès et disabled traités.
- [ ] Hover, active et `focus-visible` présents.
- [ ] Clavier, ordre du focus et lecteur d'écran vérifiés.
- [ ] Contrastes AA, notamment solaire/anthracite.
- [ ] Tests à `320, 768, 1024, 1280px` et zoom 200 %.
- [ ] Aucune fonction perdue lorsque la sidebar disparaît.
- [ ] Textes/noms longs, vide et erreur réseau testés.
- [ ] Composants partagés sans couplage métier.
- [ ] Aucun choix visuel ne contourne sécurité ou autorisations.
- [ ] Toute divergence Bolt justifiée par accessibilité ou complément documenté.

## 12. Synthèse

**Repris de Bolt :** palettes forêt/solaire/ivoire/or/anthracite, Sora/Inter/JetBrains Mono, motifs, cartes et contrôles arrondis, bordures légères, boutons, formulaires, tags/badges, code sombre, header sticky, tiroir mobile, conteneurs et sidebars, grilles, avatars, empty states, modales, toasts et animations.

**Ajouté :** tokens sémantiques, échelles normatives, contraste corrigé du solaire, focus clavier, variantes danger/link, états complets, skeletons/alertes, tableaux/pagination, modales accessibles, responsive détaillé, conventions collaboration/administration, WCAG 2.2 AA, reduced motion et intégration Next.js 16/Tailwind CSS 4.
