-- Questions et signalements de bugs
CREATE TABLE public.question (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    auteur_id UUID NOT NULL
        REFERENCES public.profiles(id),

    titre VARCHAR(200) NOT NULL,
    description TEXT NOT NULL,

    -- Informations techniques
    message_erreur TEXT,
    extrait_code TEXT,
    etapes_reproduction TEXT,
    solutions_tentees TEXT,

    statut VARCHAR(20) NOT NULL DEFAULT 'OUVERTE'
        CHECK (statut IN ('OUVERTE', 'RESOLUE')),

    date_creation TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    date_maj TIMESTAMPTZ,
    supprime_le TIMESTAMPTZ
);

-- Technologies associées aux questions
CREATE TABLE public.question_technologie (
    question_id BIGINT NOT NULL
        REFERENCES public.question(id) ON DELETE CASCADE,

    technologie_id BIGINT NOT NULL
        REFERENCES public.technologie(id),

    PRIMARY KEY (question_id, technologie_id)
);

-- Tags associés aux questions
CREATE TABLE public.question_tag (
    question_id BIGINT NOT NULL
        REFERENCES public.question(id) ON DELETE CASCADE,

    tag_id BIGINT NOT NULL
        REFERENCES public.tag(id),

    PRIMARY KEY (question_id, tag_id)
);

-- Réponses proposées par les développeurs
CREATE TABLE public.reponse (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    question_id BIGINT NOT NULL
        REFERENCES public.question(id) ON DELETE CASCADE,

    auteur_id UUID NOT NULL
        REFERENCES public.profiles(id),

    contenu TEXT NOT NULL,
    extrait_code TEXT,

    date_creation TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    date_maj TIMESTAMPTZ,
    supprime_le TIMESTAMPTZ
);

-- Réponse acceptée par l'auteur de la question
ALTER TABLE public.question
ADD COLUMN reponse_acceptee_id BIGINT
REFERENCES public.reponse(id)
ON DELETE SET NULL;

-- Index
CREATE INDEX idx_question_auteur
ON public.question(auteur_id);

CREATE INDEX idx_question_statut
ON public.question(statut);

CREATE INDEX idx_reponse_question
ON public.reponse(question_id);

-- Activer RLS
ALTER TABLE public.question ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.question_technologie ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.question_tag ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reponse ENABLE ROW LEVEL SECURITY;

-- Lecture publique des questions
CREATE POLICY "Lecture questions"
ON public.question
FOR SELECT TO anon, authenticated
USING (supprime_le IS NULL);

-- Publier une question
CREATE POLICY "Creer question"
ON public.question
FOR INSERT TO authenticated
WITH CHECK (auteur_id = (SELECT auth.uid()));

-- Modifier sa question
CREATE POLICY "Modifier question"
ON public.question
FOR UPDATE TO authenticated
USING (auteur_id = (SELECT auth.uid()))
WITH CHECK (auteur_id = (SELECT auth.uid()));

-- Lecture des technologies
CREATE POLICY "Lecture technologies questions"
ON public.question_technologie
FOR SELECT TO anon, authenticated
USING (true);

-- Associer des technologies à sa question
CREATE POLICY "Gestion technologies questions"
ON public.question_technologie
FOR ALL TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.question q
        WHERE q.id = question_id
        AND q.auteur_id = (SELECT auth.uid())
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.question q
        WHERE q.id = question_id
        AND q.auteur_id = (SELECT auth.uid())
    )
);

-- Lecture des tags
CREATE POLICY "Lecture tags questions"
ON public.question_tag
FOR SELECT TO anon, authenticated
USING (true);

-- Associer des tags à sa question
CREATE POLICY "Gestion tags questions"
ON public.question_tag
FOR ALL TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.question q
        WHERE q.id = question_id
        AND q.auteur_id = (SELECT auth.uid())
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.question q
        WHERE q.id = question_id
        AND q.auteur_id = (SELECT auth.uid())
    )
);

-- Lecture publique des réponses
CREATE POLICY "Lecture reponses"
ON public.reponse
FOR SELECT TO anon, authenticated
USING (
    supprime_le IS NULL
    AND EXISTS (
        SELECT 1 FROM public.question q
        WHERE q.id = question_id
    )
);

-- Publier une réponse
CREATE POLICY "Creer reponse"
ON public.reponse
FOR INSERT TO authenticated
WITH CHECK (
    auteur_id = (SELECT auth.uid())
    AND EXISTS (
        SELECT 1 FROM public.question q
        WHERE q.id = question_id
    )
);

-- Modifier sa réponse
CREATE POLICY "Modifier reponse"
ON public.reponse
FOR UPDATE TO authenticated
USING (auteur_id = (SELECT auth.uid()))
WITH CHECK (auteur_id = (SELECT auth.uid()));