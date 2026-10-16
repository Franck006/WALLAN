-- Offre de mentorat
CREATE TABLE public.offre_mentorat (
    utilisateur_id UUID PRIMARY KEY
        REFERENCES public.profiles(id) ON DELETE CASCADE,

    description TEXT NOT NULL,
    niveau_experience VARCHAR(100),
    disponibilites VARCHAR(300) NOT NULL,
    accepte_demandes BOOLEAN NOT NULL DEFAULT TRUE,
    date_maj TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Domaines de compétence du mentor
CREATE TABLE public.offre_mentorat_domaine (
    utilisateur_id UUID NOT NULL
        REFERENCES public.offre_mentorat(utilisateur_id) ON DELETE CASCADE,

    technologie_id BIGINT NOT NULL
        REFERENCES public.technologie(id),

    PRIMARY KEY (utilisateur_id, technologie_id)
);

-- Espaces collectifs créés par les mentors
CREATE TABLE public.espace_mentorat (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    mentor_id UUID NOT NULL
        REFERENCES public.offre_mentorat(utilisateur_id),

    nom VARCHAR(150) NOT NULL,
    description TEXT NOT NULL,
    actif BOOLEAN NOT NULL DEFAULT TRUE,
    date_creation TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Membres des espaces
CREATE TABLE public.membre_espace (
    espace_id BIGINT NOT NULL
        REFERENCES public.espace_mentorat(id) ON DELETE CASCADE,

    utilisateur_id UUID NOT NULL
        REFERENCES public.profiles(id) ON DELETE CASCADE,

    statut VARCHAR(20) NOT NULL DEFAULT 'EN_ATTENTE'
        CHECK (statut IN ('EN_ATTENTE', 'ACCEPTE', 'REFUSE')),

    date_demande TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    date_reponse TIMESTAMPTZ,

    PRIMARY KEY (espace_id, utilisateur_id)
);

-- Exercices proposés par les mentors
CREATE TABLE public.exercice (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    espace_id BIGINT NOT NULL
        REFERENCES public.espace_mentorat(id) ON DELETE CASCADE,

    titre VARCHAR(200) NOT NULL,
    description TEXT NOT NULL,
    date_creation TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Travaux soumis par les membres
CREATE TABLE public.soumission_exercice (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    exercice_id BIGINT NOT NULL
        REFERENCES public.exercice(id) ON DELETE CASCADE,

    utilisateur_id UUID NOT NULL
        REFERENCES public.profiles(id),

    url_depot VARCHAR(500),
    commentaire TEXT,
    retour_mentor TEXT,

    date_soumission TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    UNIQUE (exercice_id, utilisateur_id),

    CHECK (
        url_depot IS NOT NULL
        OR commentaire IS NOT NULL
    )
);

-- Sécurité
ALTER TABLE public.offre_mentorat ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.offre_mentorat_domaine ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.espace_mentorat ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.membre_espace ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exercice ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.soumission_exercice ENABLE ROW LEVEL SECURITY;

-- Lecture publique des offres et espaces
CREATE POLICY "Lecture offres mentorat"
ON public.offre_mentorat
FOR SELECT TO anon, authenticated
USING (true);

CREATE POLICY "Lecture domaines mentorat"
ON public.offre_mentorat_domaine
FOR SELECT TO anon, authenticated
USING (true);

CREATE POLICY "Lecture espaces mentorat"
ON public.espace_mentorat
FOR SELECT TO anon, authenticated
USING (actif = TRUE);

-- Un membre peut créer son offre de mentorat
CREATE POLICY "Creer offre mentorat"
ON public.offre_mentorat
FOR INSERT TO authenticated
WITH CHECK (utilisateur_id = (SELECT auth.uid()));

-- Un mentor peut modifier son offre
CREATE POLICY "Modifier offre mentorat"
ON public.offre_mentorat
FOR UPDATE TO authenticated
USING (utilisateur_id = (SELECT auth.uid()))
WITH CHECK (utilisateur_id = (SELECT auth.uid()));

-- Gestion de ses domaines de mentorat
CREATE POLICY "Gestion domaines mentorat"
ON public.offre_mentorat_domaine
FOR ALL TO authenticated
USING (utilisateur_id = (SELECT auth.uid()))
WITH CHECK (utilisateur_id = (SELECT auth.uid()));

-- Création d'espaces par le mentor
CREATE POLICY "Creer espace mentorat"
ON public.espace_mentorat
FOR INSERT TO authenticated
WITH CHECK (mentor_id = (SELECT auth.uid()));

-- Gestion des espaces par leur mentor
CREATE POLICY "Modifier espace mentorat"
ON public.espace_mentorat
FOR UPDATE TO authenticated
USING (mentor_id = (SELECT auth.uid()))
WITH CHECK (mentor_id = (SELECT auth.uid()));

-- Voir ses demandes ou les membres de son espace
CREATE POLICY "Consulter membres espace"
ON public.membre_espace
FOR SELECT TO authenticated
USING (
    utilisateur_id = (SELECT auth.uid())
    OR EXISTS (
        SELECT 1 FROM public.espace_mentorat e
        WHERE e.id = espace_id
        AND e.mentor_id = (SELECT auth.uid())
    )
);

-- Demander à rejoindre un espace
CREATE POLICY "Rejoindre espace mentorat"
ON public.membre_espace
FOR INSERT TO authenticated
WITH CHECK (
    utilisateur_id = (SELECT auth.uid())
    AND statut = 'EN_ATTENTE'
);

-- Le mentor accepte ou refuse les demandes
CREATE POLICY "Gerer demandes espace"
ON public.membre_espace
FOR UPDATE TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.espace_mentorat e
        WHERE e.id = espace_id
        AND e.mentor_id = (SELECT auth.uid())
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.espace_mentorat e
        WHERE e.id = espace_id
        AND e.mentor_id = (SELECT auth.uid())
    )
);

-- Voir les exercices d'un espace
CREATE POLICY "Lecture exercices"
ON public.exercice
FOR SELECT TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.espace_mentorat e
        WHERE e.id = espace_id
        AND (
            e.mentor_id = (SELECT auth.uid())
            OR EXISTS (
                SELECT 1 FROM public.membre_espace m
                WHERE m.espace_id = e.id
                AND m.utilisateur_id = (SELECT auth.uid())
                AND m.statut = 'ACCEPTE'
            )
        )
    )
);

-- Le mentor crée des exercices
CREATE POLICY "Creer exercice"
ON public.exercice
FOR INSERT TO authenticated
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.espace_mentorat e
        WHERE e.id = espace_id
        AND e.mentor_id = (SELECT auth.uid())
    )
);

-- Le membre soumet son travail
CREATE POLICY "Soumettre exercice"
ON public.soumission_exercice
FOR INSERT TO authenticated
WITH CHECK (
    utilisateur_id = (SELECT auth.uid())
    AND EXISTS (
        SELECT 1
        FROM public.exercice ex
        JOIN public.membre_espace m
          ON m.espace_id = ex.espace_id
        WHERE ex.id = exercice_id
        AND m.utilisateur_id = (SELECT auth.uid())
        AND m.statut = 'ACCEPTE'
    )
);

-- Consulter sa soumission ou les travaux de ses mentorés
CREATE POLICY "Lecture soumissions"
ON public.soumission_exercice
FOR SELECT TO authenticated
USING (
    utilisateur_id = (SELECT auth.uid())
    OR EXISTS (
        SELECT 1
        FROM public.exercice ex
        JOIN public.espace_mentorat e
          ON e.id = ex.espace_id
        WHERE ex.id = exercice_id
        AND e.mentor_id = (SELECT auth.uid())
    )
);