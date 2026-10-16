-- Opportunités : emplois, stages, bourses, hackathons...
CREATE TABLE public.opportunite (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    titre VARCHAR(200) NOT NULL,
    type_id BIGINT NOT NULL REFERENCES public.type_opportunite(id),
    pays_id BIGINT REFERENCES public.pays(id),
    description TEXT NOT NULL,
    lien_officiel VARCHAR(500) NOT NULL,
    date_debut DATE,
    date_fin DATE,
    date_limite DATE,
    source VARCHAR(200) NOT NULL,
    date_derniere_verification DATE NOT NULL,
    statut_publication VARCHAR(20) NOT NULL DEFAULT 'BROUILLON'
        CHECK (statut_publication IN ('BROUILLON', 'PUBLIE', 'ARCHIVE')),
    publie_par UUID NOT NULL REFERENCES public.profiles(id),
    date_creation TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    date_maj TIMESTAMPTZ
);

-- Signalements de contenus
CREATE TABLE public.signalement (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    signaleur_id UUID NOT NULL REFERENCES public.profiles(id),
    type_cible VARCHAR(30) NOT NULL
        CHECK (type_cible IN (
            'PUBLICATION', 'COMMENTAIRE', 'QUESTION',
            'REPONSE', 'PROFIL', 'MESSAGE'
        )),
    cible_id TEXT NOT NULL,
    motif VARCHAR(300) NOT NULL,
    statut VARCHAR(20) NOT NULL DEFAULT 'OUVERT'
        CHECK (statut IN ('OUVERT', 'TRAITE', 'REJETE')),
    traite_par UUID REFERENCES public.profiles(id),
    date_creation TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Notifications des membres
CREATE TABLE public.notification (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    destinataire_id UUID NOT NULL
        REFERENCES public.profiles(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL,
    reference_id TEXT,
    lu BOOLEAN NOT NULL DEFAULT FALSE,
    date_creation TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index
CREATE INDEX idx_opportunite_statut
ON public.opportunite(statut_publication);

CREATE INDEX idx_signalement_statut
ON public.signalement(statut);

CREATE INDEX idx_notification_destinataire
ON public.notification(destinataire_id, lu, date_creation DESC);

-- Activer RLS
ALTER TABLE public.opportunite ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.signalement ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification ENABLE ROW LEVEL SECURITY;

-- Opportunités publiées visibles publiquement
CREATE POLICY "Lecture opportunites publiees"
ON public.opportunite
FOR SELECT TO anon, authenticated
USING (statut_publication = 'PUBLIE');

-- Un membre peut effectuer un signalement
CREATE POLICY "Creer signalement"
ON public.signalement
FOR INSERT TO authenticated
WITH CHECK (
    signaleur_id = (SELECT auth.uid())
    AND statut = 'OUVERT'
    AND traite_par IS NULL
);

-- Un membre consulte ses signalements
CREATE POLICY "Consulter ses signalements"
ON public.signalement
FOR SELECT TO authenticated
USING (signaleur_id = (SELECT auth.uid()));

-- Un membre consulte ses notifications
CREATE POLICY "Consulter ses notifications"
ON public.notification
FOR SELECT TO authenticated
USING (destinataire_id = (SELECT auth.uid()));

-- Un membre marque ses notifications comme lues
CREATE POLICY "Modifier ses notifications"
ON public.notification
FOR UPDATE TO authenticated
USING (destinataire_id = (SELECT auth.uid()))
WITH CHECK (destinataire_id = (SELECT auth.uid()));