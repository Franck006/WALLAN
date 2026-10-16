-- Projets collaboratifs
CREATE TABLE public.projet_collaboratif (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    createur_id UUID NOT NULL
        REFERENCES public.profiles(id),

    titre VARCHAR(150) NOT NULL,
    description TEXT NOT NULL,
    url_depot VARCHAR(500),
    url_demo VARCHAR(500),

    statut VARCHAR(20) NOT NULL DEFAULT 'OUVERT'
        CHECK (statut IN ('OUVERT', 'EN_COURS', 'TERMINE')),

    date_creation TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    date_maj TIMESTAMPTZ
);

-- Participants aux projets
CREATE TABLE public.membre_projet (
    projet_id BIGINT NOT NULL
        REFERENCES public.projet_collaboratif(id) ON DELETE CASCADE,

    utilisateur_id UUID NOT NULL
        REFERENCES public.profiles(id),

    role VARCHAR(100) NOT NULL,
    statut VARCHAR(20) NOT NULL DEFAULT 'EN_ATTENTE'
        CHECK (statut IN ('EN_ATTENTE', 'ACCEPTE', 'REFUSE')),

    date_demande TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    PRIMARY KEY (projet_id, utilisateur_id)
);

-- Demandes de revue de code
CREATE TABLE public.revue_code (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    projet_id BIGINT NOT NULL
        REFERENCES public.projet_collaboratif(id) ON DELETE CASCADE,

    auteur_id UUID NOT NULL
        REFERENCES public.profiles(id),

    titre VARCHAR(200) NOT NULL,
    description TEXT NOT NULL,
    url_pull_request VARCHAR(500) NOT NULL,

    statut VARCHAR(20) NOT NULL DEFAULT 'OUVERTE'
        CHECK (statut IN ('OUVERTE', 'RESOLUE', 'FERMEE')),

    date_creation TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Commentaires sur les revues
CREATE TABLE public.commentaire_revue (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    revue_id BIGINT NOT NULL
        REFERENCES public.revue_code(id) ON DELETE CASCADE,

    auteur_id UUID NOT NULL
        REFERENCES public.profiles(id),

    contenu TEXT NOT NULL,
    date_creation TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index
CREATE INDEX idx_projet_collaboratif_createur
ON public.projet_collaboratif(createur_id);

CREATE INDEX idx_revue_code_projet
ON public.revue_code(projet_id);

CREATE INDEX idx_commentaire_revue
ON public.commentaire_revue(revue_id);

-- Activer RLS
ALTER TABLE public.projet_collaboratif ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.membre_projet ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.revue_code ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.commentaire_revue ENABLE ROW LEVEL SECURITY;

-- Consultation publique des projets
CREATE POLICY "Lecture projets collaboratifs"
ON public.projet_collaboratif
FOR SELECT TO anon, authenticated
USING (true);

-- Création d'un projet
CREATE POLICY "Creer projet collaboratif"
ON public.projet_collaboratif
FOR INSERT TO authenticated
WITH CHECK (createur_id = (SELECT auth.uid()));

-- Modification par le créateur
CREATE POLICY "Modifier projet collaboratif"
ON public.projet_collaboratif
FOR UPDATE TO authenticated
USING (createur_id = (SELECT auth.uid()))
WITH CHECK (createur_id = (SELECT auth.uid()));

-- Consultation des participants
CREATE POLICY "Lecture membres projets"
ON public.membre_projet
FOR SELECT TO anon, authenticated
USING (statut = 'ACCEPTE');

-- Demander à rejoindre un projet
CREATE POLICY "Rejoindre projet"
ON public.membre_projet
FOR INSERT TO authenticated
WITH CHECK (
    utilisateur_id = (SELECT auth.uid())
    AND statut = 'EN_ATTENTE'
);

-- Consultation publique des revues
CREATE POLICY "Lecture revues code"
ON public.revue_code
FOR SELECT TO anon, authenticated
USING (true);

-- Un membre accepté peut demander une revue
CREATE POLICY "Creer revue code"
ON public.revue_code
FOR INSERT TO authenticated
WITH CHECK (
    auteur_id = (SELECT auth.uid())
    AND (
        EXISTS (
            SELECT 1
            FROM public.projet_collaboratif p
            WHERE p.id = projet_id
              AND p.createur_id = (SELECT auth.uid())
        )
        OR EXISTS (
            SELECT 1
            FROM public.membre_projet m
            WHERE m.projet_id = revue_code.projet_id
              AND m.utilisateur_id = (SELECT auth.uid())
              AND m.statut = 'ACCEPTE'
        )
    )
);

-- Lecture des commentaires
CREATE POLICY "Lecture commentaires revues"
ON public.commentaire_revue
FOR SELECT TO anon, authenticated
USING (true);

-- Publier un commentaire
CREATE POLICY "Commenter revue"
ON public.commentaire_revue
FOR INSERT TO authenticated
WITH CHECK (auteur_id = (SELECT auth.uid()));