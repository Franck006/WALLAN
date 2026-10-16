-- Table des communautés
CREATE TABLE public.communaute (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nom VARCHAR(100) NOT NULL,
    slug VARCHAR(100) NOT NULL UNIQUE,
    description TEXT NOT NULL,
    regles TEXT,
    categorie VARCHAR(20) NOT NULL
        CHECK (categorie IN ('PAYS', 'TECHNOLOGIE')),

    pays_id BIGINT REFERENCES public.pays(id),
    technologie_id BIGINT REFERENCES public.technologie(id),

    cree_par UUID NOT NULL REFERENCES public.profiles(id),
    active BOOLEAN NOT NULL DEFAULT TRUE,
    date_creation TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT communaute_categorie_reference_check CHECK  (
        (categorie = 'PAYS'
            AND pays_id IS NOT NULL
            AND technologie_id IS NULL)
        OR
        (categorie = 'TECHNOLOGIE'
            AND technologie_id IS NOT NULL
            AND pays_id IS NULL)
    )
);

-- Membres des communautés
CREATE TABLE public.adhesion_communaute (
    utilisateur_id UUID NOT NULL
        REFERENCES public.profiles(id) ON DELETE CASCADE,

    communaute_id BIGINT NOT NULL
        REFERENCES public.communaute(id) ON DELETE CASCADE,

    role VARCHAR(20) NOT NULL DEFAULT 'MEMBRE'
        CHECK (role IN ('MEMBRE', 'MODERATEUR')),

    date_adhesion TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    PRIMARY KEY (utilisateur_id, communaute_id)
);

-- Activer RLS
ALTER TABLE public.communaute ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.adhesion_communaute ENABLE ROW LEVEL SECURITY;

-- Consultation publique des communautés
CREATE POLICY "Lecture publique communautes"
ON public.communaute
FOR SELECT TO anon, authenticated
USING (true);

-- Consultation publique des adhésions
CREATE POLICY "Lecture publique adhesions"
ON public.adhesion_communaute
FOR SELECT TO anon, authenticated
USING (true);

-- Un membre peut rejoindre une communauté
CREATE POLICY "Rejoindre une communaute"
ON public.adhesion_communaute
FOR INSERT TO authenticated
WITH CHECK (
    utilisateur_id = (SELECT auth.uid())
    AND role = 'MEMBRE'
    AND EXISTS (
        SELECT 1
        FROM public.communaute c
        WHERE c.id = communaute_id
          AND c.active = TRUE
    )
);

-- Un membre peut quitter une communauté
CREATE POLICY "Quitter une communaute"
ON public.adhesion_communaute
FOR DELETE TO authenticated
USING (utilisateur_id = (SELECT auth.uid()));