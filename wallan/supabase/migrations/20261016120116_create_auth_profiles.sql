-- Profil public lié à Supabase Auth
CREATE TABLE public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    username VARCHAR(30) UNIQUE NOT NULL,
    nom_affiche VARCHAR(80) NOT NULL,
    avatar_url TEXT,
    bio TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Rôles et statuts des utilisateurs
CREATE TYPE public.user_role AS ENUM ('MEMBRE', 'ADMIN');
CREATE TYPE public.user_status AS ENUM ('ACTIF', 'SUSPENDU', 'SUPPRIME');

CREATE TABLE public.user_roles (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    role public.user_role NOT NULL DEFAULT 'MEMBRE',
    statut public.user_status NOT NULL DEFAULT 'ACTIF',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Activer la sécurité
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;

-- Consultation des profils publics
CREATE POLICY "Profils publics consultables"
ON public.profiles
FOR SELECT
TO anon, authenticated
USING (true);

-- Modification de son propre profil
CREATE POLICY "Modifier son profil"
ON public.profiles
FOR UPDATE
TO authenticated
USING ((SELECT auth.uid()) = id)
WITH CHECK ((SELECT auth.uid()) = id);

-- Consultation de son propre rôle
CREATE POLICY "Consulter son rôle"
ON public.user_roles
FOR SELECT
TO authenticated
USING ((SELECT auth.uid()) = user_id);