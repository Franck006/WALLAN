-- Table temporaire pour tester PostgreSQL
CREATE TABLE public.wallan_health_check (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    message TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Activer la sécurité
ALTER TABLE public.wallan_health_check
ENABLE ROW LEVEL SECURITY;

-- Autoriser la lecture de cette table de test
CREATE POLICY "health_check_select"
ON public.wallan_health_check
FOR SELECT
TO anon, authenticated
USING (true);

-- Insérer une donnée de test
INSERT INTO public.wallan_health_check (message)
VALUES ('WALLAN est connecté à PostgreSQL !');