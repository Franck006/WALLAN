CREATE TABLE public.pays (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code_iso CHAR(2) NOT NULL UNIQUE,
    nom VARCHAR(100) NOT NULL
);

CREATE TABLE public.technologie (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nom VARCHAR(80) NOT NULL,
    slug VARCHAR(80) NOT NULL UNIQUE,
    categorie VARCHAR(30) NOT NULL
        CHECK (categorie IN (
            'LANGAGE', 'FRAMEWORK', 'BIBLIOTHEQUE',
            'OUTIL', 'PLATEFORME', 'AUTRE'
        ))
);

CREATE TABLE public.tag (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    libelle VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE public.specialisation (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    libelle VARCHAR(80) NOT NULL UNIQUE
);

CREATE TABLE public.centre_interet (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    libelle VARCHAR(80) NOT NULL UNIQUE
);

CREATE TABLE public.type_opportunite (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    libelle VARCHAR(50) NOT NULL UNIQUE
);

-- Activer RLS sur les référentiels
ALTER TABLE public.pays ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.technologie ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tag ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.specialisation ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.centre_interet ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.type_opportunite ENABLE ROW LEVEL SECURITY;

-- Autoriser la lecture publique
CREATE POLICY "Lecture publique" ON public.pays
FOR SELECT TO anon, authenticated USING (true);

CREATE POLICY "Lecture publique" ON public.technologie
FOR SELECT TO anon, authenticated USING (true);

CREATE POLICY "Lecture publique" ON public.tag
FOR SELECT TO anon, authenticated USING (true);

CREATE POLICY "Lecture publique" ON public.specialisation
FOR SELECT TO anon, authenticated USING (true);

CREATE POLICY "Lecture publique" ON public.centre_interet
FOR SELECT TO anon, authenticated USING (true);

CREATE POLICY "Lecture publique" ON public.type_opportunite
FOR SELECT TO anon, authenticated USING (true);