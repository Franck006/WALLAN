-- Messages échangés dans les espaces de mentorat
CREATE TABLE public.message_mentorat (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    espace_id BIGINT NOT NULL
        REFERENCES public.espace_mentorat(id) ON DELETE CASCADE,

    auteur_id UUID NOT NULL
        REFERENCES public.profiles(id),

    contenu TEXT NOT NULL,
    date_creation TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    date_maj TIMESTAMPTZ,
    supprime_le TIMESTAMPTZ,

    CONSTRAINT message_contenu_non_vide
        CHECK (LENGTH(TRIM(contenu)) > 0)
);

-- Optimiser la récupération des messages
CREATE INDEX idx_message_mentorat_espace_date
ON public.message_mentorat(espace_id, date_creation DESC);

-- Activer RLS
ALTER TABLE public.message_mentorat
ENABLE ROW LEVEL SECURITY;

-- Lecture réservée au mentor et aux membres acceptés
CREATE POLICY "Lire messages mentorat"
ON public.message_mentorat
FOR SELECT TO authenticated
USING (
    supprime_le IS NULL
    AND EXISTS (
        SELECT 1
        FROM public.espace_mentorat e
        WHERE e.id = espace_id
        AND (
            e.mentor_id = (SELECT auth.uid())
            OR EXISTS (
                SELECT 1
                FROM public.membre_espace m
                WHERE m.espace_id = e.id
                  AND m.utilisateur_id = (SELECT auth.uid())
                  AND m.statut = 'ACCEPTE'
            )
        )
    )
);

-- Publication réservée au mentor et aux membres acceptés
CREATE POLICY "Envoyer messages mentorat"
ON public.message_mentorat
FOR INSERT TO authenticated
WITH CHECK (
    auteur_id = (SELECT auth.uid())
    AND EXISTS (
        SELECT 1
        FROM public.espace_mentorat e
        WHERE e.id = espace_id
          AND e.actif = TRUE
          AND (
              e.mentor_id = (SELECT auth.uid())
              OR EXISTS (
                  SELECT 1
                  FROM public.membre_espace m
                  WHERE m.espace_id = e.id
                    AND m.utilisateur_id = (SELECT auth.uid())
                    AND m.statut = 'ACCEPTE'
              )
          )
    )
);

-- L'auteur peut modifier son message
CREATE POLICY "Modifier messages mentorat"
ON public.message_mentorat
FOR UPDATE TO authenticated
USING (
    auteur_id = (SELECT auth.uid())
    AND supprime_le IS NULL
)
WITH CHECK (
    auteur_id = (SELECT auth.uid())
);