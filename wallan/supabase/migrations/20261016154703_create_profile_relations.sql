-- Ajouter le pays et la spécialisation au profil
ALTER TABLE public.profiles
ADD COLUMN pays_id BIGINT REFERENCES public.pays(id),
ADD COLUMN ville VARCHAR(100),
ADD COLUMN niveau_declare VARCHAR(20)
    CHECK (niveau_declare IN (
        'DEBUTANT', 'JUNIOR', 'INTERMEDIAIRE',
        'CONFIRME', 'SENIOR'
    )),
ADD COLUMN specialisation_id BIGINT
    REFERENCES public.specialisation(id);

-- Technologies maîtrisées par un développeur
CREATE TABLE public.profil_technologie (
    utilisateur_id UUID NOT NULL
        REFERENCES public.profiles(id) ON DELETE CASCADE,
    technologie_id BIGINT NOT NULL
        REFERENCES public.technologie(id),

    PRIMARY KEY (utilisateur_id, technologie_id)
);

-- Centres d'intérêt d'un développeur
CREATE TABLE public.profil_centre_interet (
    utilisateur_id UUID NOT NULL
        REFERENCES public.profiles(id) ON DELETE CASCADE,
    centre_interet_id BIGINT NOT NULL
        REFERENCES public.centre_interet(id),

    PRIMARY KEY (utilisateur_id, centre_interet_id)
);

-- Sécuriser les tables d'association
ALTER TABLE public.profil_technologie ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profil_centre_interet ENABLE ROW LEVEL SECURITY;

-- Consultation publique des compétences
CREATE POLICY "Lecture publique technologies"
ON public.profil_technologie
FOR SELECT TO anon, authenticated
USING (true);

-- Un membre gère ses propres compétences
CREATE POLICY "Gestion technologies personnelles"
ON public.profil_technologie
FOR ALL TO authenticated
USING ((SELECT auth.uid()) = utilisateur_id)
WITH CHECK ((SELECT auth.uid()) = utilisateur_id);

-- Consultation publique des centres d'intérêt
CREATE POLICY "Lecture publique centres interet"
ON public.profil_centre_interet
FOR SELECT TO anon, authenticated
USING (true);

-- Un membre gère ses propres centres d'intérêt
CREATE POLICY "Gestion centres interet personnels"
ON public.profil_centre_interet
FOR ALL TO authenticated
USING ((SELECT auth.uid()) = utilisateur_id)
WITH CHECK ((SELECT auth.uid()) = utilisateur_id);