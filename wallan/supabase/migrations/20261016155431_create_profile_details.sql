-- Liens externes du profil
CREATE TABLE public.lien_profil (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    utilisateur_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    type VARCHAR(20) NOT NULL CHECK (type IN (
        'GITHUB', 'PORTFOLIO', 'LINKEDIN', 'GITLAB',
        'BEHANCE', 'DRIBBBLE', 'SITE', 'AUTRE'
    )),
    url VARCHAR(500) NOT NULL,
    libelle VARCHAR(60),
    ordre SMALLINT DEFAULT 0
);

-- Projets personnels
CREATE TABLE public.projet (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    utilisateur_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    titre VARCHAR(120) NOT NULL,
    description_courte VARCHAR(500) NOT NULL,
    url_depot VARCHAR(500),
    url_demo VARCHAR(500),
    date_creation TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT projet_lien_obligatoire
        CHECK (url_depot IS NOT NULL OR url_demo IS NOT NULL)
);

-- Technologies utilisées dans les projets
CREATE TABLE public.projet_technologie (
    projet_id BIGINT NOT NULL REFERENCES public.projet(id) ON DELETE CASCADE,
    technologie_id BIGINT NOT NULL REFERENCES public.technologie(id),
    PRIMARY KEY (projet_id, technologie_id)
);

-- Disponibilités des développeurs
CREATE TABLE public.disponibilite (
    utilisateur_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    type VARCHAR(20) NOT NULL CHECK (
        type IN ('COLLABORATION', 'MENTORAT', 'AUTRE')
    ),
    precision VARCHAR(200),
    PRIMARY KEY (utilisateur_id, type)
);

-- Activer RLS
ALTER TABLE public.lien_profil ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.projet ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.projet_technologie ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.disponibilite ENABLE ROW LEVEL SECURITY;

-- Lecture publique
CREATE POLICY "Lecture publique liens"
ON public.lien_profil FOR SELECT
TO anon, authenticated USING (true);

CREATE POLICY "Lecture publique projets"
ON public.projet FOR SELECT
TO anon, authenticated USING (true);

CREATE POLICY "Lecture publique technologies projets"
ON public.projet_technologie FOR SELECT
TO anon, authenticated USING (true);

CREATE POLICY "Lecture publique disponibilites"
ON public.disponibilite FOR SELECT
TO anon, authenticated USING (true);

-- Modification de ses liens
CREATE POLICY "Gestion liens personnels"
ON public.lien_profil FOR ALL
TO authenticated
USING ((SELECT auth.uid()) = utilisateur_id)
WITH CHECK ((SELECT auth.uid()) = utilisateur_id);

-- Modification de ses projets
CREATE POLICY "Gestion projets personnels"
ON public.projet FOR ALL
TO authenticated
USING ((SELECT auth.uid()) = utilisateur_id)
WITH CHECK ((SELECT auth.uid()) = utilisateur_id);

-- Gestion des technologies de ses projets
CREATE POLICY "Gestion technologies projets personnels"
ON public.projet_technologie FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.projet p
        WHERE p.id = projet_id
        AND p.utilisateur_id = (SELECT auth.uid())
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.projet p
        WHERE p.id = projet_id
        AND p.utilisateur_id = (SELECT auth.uid())
    )
);

-- Gestion de ses disponibilités
CREATE POLICY "Gestion disponibilites personnelles"
ON public.disponibilite FOR ALL
TO authenticated
USING ((SELECT auth.uid()) = utilisateur_id)
WITH CHECK ((SELECT auth.uid()) = utilisateur_id);