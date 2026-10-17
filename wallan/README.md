# WALLAN

WALLAN est une plateforme communautaire pour développeurs africains : publications, entraide, mentorat, communautés, collaboration et opportunités.

Stack : Next.js 16 (App Router), TypeScript, React 19, Tailwind CSS 4, Supabase Auth/PostgreSQL et Docker. Avant de contribuer, lire [ARCHITECTURE.md](./ARCHITECTURE.md) puis [docs/REPARTITION_TACHES.md](./docs/REPARTITION_TACHES.md).

## Prérequis

- Git ;
- Node.js 24 et npm 11, comme dans le `Dockerfile` ;
- Docker Desktop avec le moteur WSL 2 sous Windows ;
- une distribution WSL 2 si les commandes sont exécutées depuis WSL.

```powershell
git --version
node --version
npm --version
docker --version
docker compose version
```

Sous WSL, conserver de préférence le dépôt dans le système de fichiers Linux : les montages depuis `/mnt/c` peuvent être plus lents.

## Installation après clonage

```powershell
git clone https://github.com/Franck006/WALLAN.git
cd WALLAN
npm ci
Copy-Item .env.example .env.local
```

Sous Bash/WSL : `cp .env.example .env.local`. `npm ci` respecte exactement `package-lock.json`.

## Configuration de l'environnement

Le frontend attend :

```dotenv
NEXT_PUBLIC_SUPABASE_URL=
NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY=
```

Pour Supabase Cloud, copier l'URL et la clé publique/publishable depuis les paramètres API du projet dans `.env.local`. Pour Supabase local déjà démarré, utiliser les valeurs affichées par `npx supabase status`.

Les variables `NEXT_PUBLIC_*` sont publiques. Ne jamais y placer de clé `service_role`, mot de passe ou autre secret. `.env.local` est ignoré par Git.

## Démarrer l'application

Avec Docker Compose :

```powershell
docker compose up --build
```

Ouvrir <http://localhost:3000>. Pour l'arrière-plan et les logs :

```powershell
docker compose up --build -d
docker compose logs -f wallan
```

Arrêter sans supprimer les volumes :

```powershell
docker compose down
```

Sans Docker :

```powershell
npm run dev
```

Pour simuler la production : `npm run build`, puis `npm run start`.

## Supabase local facultatif

Le dépôt contient `supabase/config.toml`, 26 migrations et trois suites pgTAP. Le premier démarrage peut télécharger plusieurs images Docker : ne le faire que lorsque la tâche l'autorise.

```powershell
npx supabase start
npx supabase status
```

Ports configurés : API `54321`, PostgreSQL `54322`, Studio <http://127.0.0.1:54323> et serveur d'e-mails <http://127.0.0.1:54324>.

```powershell
npx supabase stop
```

Ne jamais lancer `supabase db push`, `db reset` ou une opération destructive sans autorisation explicite. `db reset` détruit les données de la base locale.

## Vérifications

Sans démarrer Supabase :

```powershell
npx tsc --noEmit
npm run lint
```

Si Supabase local est déjà actif et autorisé :

```powershell
npx supabase test db
```

Les suites actuelles couvrent 41 assertions : mentorat (12), modération/administration (16) et corrections d'audit (13). Les tests RLS ne doivent ni contourner les politiques ni désactiver les triggers.

## Flux de travail

`main` reste stable, `develop` sert à l'intégration et le travail se fait sur de petites branches `feature/<module>-<sujet>`. Chaque développeur possède le frontend, les services, repositories, validations et tests de ses modules. Les changements transversaux sont coordonnés avant modification.

Une migration partagée ou déployée n'est jamais modifiée : une correction utilise une nouvelle migration chronologiquement postérieure. Aucun agent ne crée de commit ou ne pousse sans demande explicite.

## Problèmes courants

- Variables Supabase : vérifier les deux noms exacts dans `.env.local`, puis redémarrer Next.js.
- Port 3000 occupé : arrêter l'autre serveur et vérifier `docker compose ps`.
- Docker indisponible : vérifier Docker Desktop, WSL 2 et l'intégration de la distribution.
- Rechargement absent : Compose active déjà le polling ; reconstruire avec `docker compose up --build` après un changement de configuration.
- Dépendances Docker incohérentes : reconstruire avant d'envisager la suppression destructive du volume `wallan_node_modules`.
- CLI Supabase bloqué : vérifier les droits du profil utilisateur et l'antivirus ; ne pas basculer vers une commande Cloud.

## À confirmer manuellement

- droits des membres dans Supabase Cloud ;
- protections GitHub de `main` et `develop` ;
- procédure de déploiement et environnements ;
- canal de validation des changements transversaux.
