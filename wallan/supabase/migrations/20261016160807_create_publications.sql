-- Publications des développeurs
CREATE TABLE public.publication (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    auteur_id UUID NOT NULL
        REFERENCES public.profiles(id),

    communaute_id BIGINT
        REFERENCES public.communaute(id),

    contenu TEXT NOT NULL,
    lien_url VARCHAR(500),
    image_url VARCHAR(500),

    date_creation TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    date_maj TIMESTAMPTZ,
    supprime_le TIMESTAMPTZ
);

-- Commentaires des publications
CREATE TABLE public.commentaire (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    publication_id BIGINT NOT NULL
        REFERENCES public.publication(id) ON DELETE CASCADE,

    auteur_id UUID NOT NULL
        REFERENCES public.profiles(id),

    contenu TEXT NOT NULL,
    date_creation TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    supprime_le TIMESTAMPTZ
);

-- Réactions aux publications
CREATE TABLE public.reaction (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    publication_id BIGINT NOT NULL
        REFERENCES public.publication(id) ON DELETE CASCADE,

    utilisateur_id UUID NOT NULL
        REFERENCES public.profiles(id),

    type VARCHAR(20) NOT NULL
        CHECK (type IN ('JAIME', 'UTILE', 'BRAVO')),

    date_creation TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    UNIQUE (publication_id, utilisateur_id)
);

-- Index
CREATE INDEX idx_publication_auteur
ON public.publication(auteur_id);

CREATE INDEX idx_publication_communaute
ON public.publication(communaute_id);

CREATE INDEX idx_commentaire_publication
ON public.commentaire(publication_id);

-- Activer RLS
ALTER TABLE public.publication ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.commentaire ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reaction ENABLE ROW LEVEL SECURITY;

-- Lecture des publications non supprimées
CREATE POLICY "Lecture publications"
ON public.publication
FOR SELECT TO anon, authenticated
USING (supprime_le IS NULL);

-- Création de publications
CREATE POLICY "Creer publication"
ON public.publication
FOR INSERT TO authenticated
WITH CHECK (
    auteur_id = (SELECT auth.uid())
    AND (
        communaute_id IS NULL
        OR EXISTS (
            SELECT 1
            FROM public.adhesion_communaute ac
            WHERE ac.communaute_id = publication.communaute_id
              AND ac.utilisateur_id = (SELECT auth.uid())
        )
    )
);

-- Modification de ses publications
CREATE POLICY "Modifier publication"
ON public.publication
FOR UPDATE TO authenticated
USING (auteur_id = (SELECT auth.uid()))
WITH CHECK (auteur_id = (SELECT auth.uid()));

-- Lecture des commentaires non supprimés
CREATE POLICY "Lecture commentaires"
ON public.commentaire
FOR SELECT TO anon, authenticated
USING (
    supprime_le IS NULL
    AND EXISTS (
        SELECT 1 FROM public.publication p
        WHERE p.id = publication_id
    )
);

-- Ajouter un commentaire
CREATE POLICY "Ajouter commentaire"
ON public.commentaire
FOR INSERT TO authenticated
WITH CHECK (
    auteur_id = (SELECT auth.uid())
    AND EXISTS (
        SELECT 1
        FROM public.publication p
        WHERE p.id = publication_id
          AND (
              p.communaute_id IS NULL
              OR EXISTS (
                  SELECT 1
                  FROM public.adhesion_communaute ac
                  WHERE ac.communaute_id = p.communaute_id
                    AND ac.utilisateur_id = (SELECT auth.uid())
              )
          )
    )
);

-- Modifier ses commentaires
CREATE POLICY "Modifier commentaire"
ON public.commentaire
FOR UPDATE TO authenticated
USING (auteur_id = (SELECT auth.uid()))
WITH CHECK (auteur_id = (SELECT auth.uid()));

-- Lecture des réactions
CREATE POLICY "Lecture reactions"
ON public.reaction
FOR SELECT TO anon, authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.publication p
        WHERE p.id = publication_id
    )
);

-- Ajouter sa réaction
CREATE POLICY "Ajouter reaction"
ON public.reaction
FOR INSERT TO authenticated
WITH CHECK (
    utilisateur_id = (SELECT auth.uid())
    AND EXISTS (
        SELECT 1 FROM public.publication p
        WHERE p.id = publication_id
    )
);

-- Modifier sa réaction
CREATE POLICY "Modifier reaction"
ON public.reaction
FOR UPDATE TO authenticated
USING (utilisateur_id = (SELECT auth.uid()))
WITH CHECK (utilisateur_id = (SELECT auth.uid()));

-- Retirer sa réaction
CREATE POLICY "Supprimer reaction"
ON public.reaction
FOR DELETE TO authenticated
USING (utilisateur_id = (SELECT auth.uid()));