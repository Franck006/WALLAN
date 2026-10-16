-- =====================================================
-- WALLAN : anonymisation lors de la suppression d'un compte
-- =====================================================
-- Les contributions publiques sont conservées avec un auteur NULL.
-- Les requêtes d'affichage doivent utiliser une jointure LEFT JOIN vers
-- profiles et afficher COALESCE(profiles.nom_affiche, 'Utilisateur supprimé').
-- Les données personnelles et privées restent supprimées par cascade.

-- =====================================================
-- 1. Contributions publiques et objets collectifs conservés
-- =====================================================

-- Une communauté survit à la suppression de son créateur.
ALTER TABLE public.communaute
    ALTER COLUMN cree_par DROP NOT NULL,
    DROP CONSTRAINT communaute_cree_par_fkey,
    ADD CONSTRAINT communaute_cree_par_fkey
        FOREIGN KEY (cree_par) REFERENCES public.profiles(id)
        ON DELETE SET NULL;

-- Publications et commentaires sont anonymisés, mais conservés.
ALTER TABLE public.publication
    ALTER COLUMN auteur_id DROP NOT NULL,
    DROP CONSTRAINT publication_auteur_id_fkey,
    ADD CONSTRAINT publication_auteur_id_fkey
        FOREIGN KEY (auteur_id) REFERENCES public.profiles(id)
        ON DELETE SET NULL;

ALTER TABLE public.commentaire
    ALTER COLUMN auteur_id DROP NOT NULL,
    DROP CONSTRAINT commentaire_auteur_id_fkey,
    ADD CONSTRAINT commentaire_auteur_id_fkey
        FOREIGN KEY (auteur_id) REFERENCES public.profiles(id)
        ON DELETE SET NULL;

-- Les questions et réponses, y compris les réponses acceptées, sont conservées.
ALTER TABLE public.question
    ALTER COLUMN auteur_id DROP NOT NULL,
    DROP CONSTRAINT question_auteur_id_fkey,
    ADD CONSTRAINT question_auteur_id_fkey
        FOREIGN KEY (auteur_id) REFERENCES public.profiles(id)
        ON DELETE SET NULL;

ALTER TABLE public.reponse
    ALTER COLUMN auteur_id DROP NOT NULL,
    DROP CONSTRAINT reponse_auteur_id_fkey,
    ADD CONSTRAINT reponse_auteur_id_fkey
        FOREIGN KEY (auteur_id) REFERENCES public.profiles(id)
        ON DELETE SET NULL;

-- Les projets collectifs et leurs discussions publiques restent disponibles.
ALTER TABLE public.projet_collaboratif
    ALTER COLUMN createur_id DROP NOT NULL,
    DROP CONSTRAINT projet_collaboratif_createur_id_fkey,
    ADD CONSTRAINT projet_collaboratif_createur_id_fkey
        FOREIGN KEY (createur_id) REFERENCES public.profiles(id)
        ON DELETE SET NULL;

ALTER TABLE public.revue_code
    ALTER COLUMN auteur_id DROP NOT NULL,
    DROP CONSTRAINT revue_code_auteur_id_fkey,
    ADD CONSTRAINT revue_code_auteur_id_fkey
        FOREIGN KEY (auteur_id) REFERENCES public.profiles(id)
        ON DELETE SET NULL;

ALTER TABLE public.commentaire_revue
    ALTER COLUMN auteur_id DROP NOT NULL,
    DROP CONSTRAINT commentaire_revue_auteur_id_fkey,
    ADD CONSTRAINT commentaire_revue_auteur_id_fkey
        FOREIGN KEY (auteur_id) REFERENCES public.profiles(id)
        ON DELETE SET NULL;

-- Une opportunité publiée reste utile même après le départ de son auteur.
ALTER TABLE public.opportunite
    ALTER COLUMN publie_par DROP NOT NULL,
    DROP CONSTRAINT opportunite_publie_par_fkey,
    ADD CONSTRAINT opportunite_publie_par_fkey
        FOREIGN KEY (publie_par) REFERENCES public.profiles(id)
        ON DELETE SET NULL;

-- Un signalement traité est conservé pour l'audit, sans conserver l'identité
-- d'un administrateur dont le compte a été supprimé.
ALTER TABLE public.signalement
    DROP CONSTRAINT signalement_traite_par_fkey,
    ADD CONSTRAINT signalement_traite_par_fkey
        FOREIGN KEY (traite_par) REFERENCES public.profiles(id)
        ON DELETE SET NULL;

-- =====================================================
-- 2. Données personnelles ou privées supprimées
-- =====================================================

-- Les réactions sont personnelles et n'ont pas besoin de survivre seules.
ALTER TABLE public.reaction
    DROP CONSTRAINT reaction_utilisateur_id_fkey,
    ADD CONSTRAINT reaction_utilisateur_id_fkey
        FOREIGN KEY (utilisateur_id) REFERENCES public.profiles(id)
        ON DELETE CASCADE;

-- La suppression d'une offre de mentorat supprime son espace privé, puis les
-- membres, exercices, soumissions et messages liés grâce aux cascades enfants.
ALTER TABLE public.espace_mentorat
    DROP CONSTRAINT espace_mentorat_mentor_id_fkey,
    ADD CONSTRAINT espace_mentorat_mentor_id_fkey
        FOREIGN KEY (mentor_id)
        REFERENCES public.offre_mentorat(utilisateur_id)
        ON DELETE CASCADE;

-- Si un mentoré supprime son compte, ses travaux et messages privés sont
-- supprimés même lorsque l'espace appartient à un autre mentor.
ALTER TABLE public.soumission_exercice
    DROP CONSTRAINT soumission_exercice_utilisateur_id_fkey,
    ADD CONSTRAINT soumission_exercice_utilisateur_id_fkey
        FOREIGN KEY (utilisateur_id) REFERENCES public.profiles(id)
        ON DELETE CASCADE;

ALTER TABLE public.message_mentorat
    DROP CONSTRAINT message_mentorat_auteur_id_fkey,
    ADD CONSTRAINT message_mentorat_auteur_id_fkey
        FOREIGN KEY (auteur_id) REFERENCES public.profiles(id)
        ON DELETE CASCADE;

-- Les adhésions aux projets collectifs sont des données personnelles ; le
-- projet lui-même reste conservé et anonymisé via createur_id.
ALTER TABLE public.membre_projet
    DROP CONSTRAINT membre_projet_utilisateur_id_fkey,
    ADD CONSTRAINT membre_projet_utilisateur_id_fkey
        FOREIGN KEY (utilisateur_id) REFERENCES public.profiles(id)
        ON DELETE CASCADE;

-- Le signalement est une démarche privée de son auteur.
ALTER TABLE public.signalement
    DROP CONSTRAINT signalement_signaleur_id_fkey,
    ADD CONSTRAINT signalement_signaleur_id_fkey
        FOREIGN KEY (signaleur_id) REFERENCES public.profiles(id)
        ON DELETE CASCADE;

-- Les autres données personnelles possèdent déjà les cascades nécessaires :
-- profil_technologie, profil_centre_interet, lien_profil, projet personnel,
-- disponibilite, adhesion_communaute, offre_mentorat, membre_espace et
-- notification. user_roles et profiles sont déjà liés à auth.users en cascade.

-- =====================================================
-- 3. Triggers compatibles avec l'anonymisation par SET NULL
-- =====================================================

-- Les utilisateurs ordinaires restent incapables de changer l'auteur grâce
-- aux politiques RLS. L'exception OLD non NULL -> NEW NULL permet uniquement
-- à l'action référentielle de PostgreSQL d'anonymiser une contribution.
CREATE OR REPLACE FUNCTION public.protect_publication_fields()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
    IF (
        NEW.auteur_id IS DISTINCT FROM OLD.auteur_id
        AND NOT (OLD.auteur_id IS NOT NULL AND NEW.auteur_id IS NULL)
       )
       OR NEW.communaute_id IS DISTINCT FROM OLD.communaute_id
       OR NEW.date_creation IS DISTINCT FROM OLD.date_creation
    THEN
        RAISE EXCEPTION 'Modification non autorisée des champs protégés';
    END IF;

    IF OLD.supprime_le IS NOT NULL
       AND NOT (OLD.auteur_id IS NOT NULL AND NEW.auteur_id IS NULL)
    THEN
        RAISE EXCEPTION 'Publication déjà supprimée';
    END IF;

    IF NEW.supprime_le IS NOT NULL AND OLD.supprime_le IS NULL THEN
        NEW.supprime_le := pg_catalog.now();
    END IF;

    NEW.date_maj := pg_catalog.now();
    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.protect_commentaire_fields()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
    IF (
        NEW.auteur_id IS DISTINCT FROM OLD.auteur_id
        AND NOT (OLD.auteur_id IS NOT NULL AND NEW.auteur_id IS NULL)
       )
       OR NEW.publication_id IS DISTINCT FROM OLD.publication_id
       OR NEW.date_creation IS DISTINCT FROM OLD.date_creation
    THEN
        RAISE EXCEPTION 'Modification non autorisée des champs protégés';
    END IF;

    IF OLD.supprime_le IS NOT NULL
       AND NOT (OLD.auteur_id IS NOT NULL AND NEW.auteur_id IS NULL)
    THEN
        RAISE EXCEPTION 'Commentaire déjà supprimé';
    END IF;

    IF NEW.supprime_le IS NOT NULL AND OLD.supprime_le IS NULL THEN
        NEW.supprime_le := pg_catalog.now();
    END IF;

    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.protect_question_fields()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
    IF NEW.id IS DISTINCT FROM OLD.id
       OR (
           NEW.auteur_id IS DISTINCT FROM OLD.auteur_id
           AND NOT (OLD.auteur_id IS NOT NULL AND NEW.auteur_id IS NULL)
       )
       OR NEW.date_creation IS DISTINCT FROM OLD.date_creation
    THEN
        RAISE EXCEPTION 'Modification non autorisée des champs protégés de la question';
    END IF;

    IF NEW.reponse_acceptee_id IS NOT NULL
       AND NOT EXISTS (
           SELECT 1
           FROM public.reponse r
           WHERE r.id = NEW.reponse_acceptee_id
             AND r.question_id = OLD.id
             AND r.supprime_le IS NULL
       )
    THEN
        RAISE EXCEPTION 'La réponse acceptée doit appartenir à la question et ne pas être supprimée';
    END IF;

    IF NEW.supprime_le IS NOT NULL AND OLD.supprime_le IS NULL THEN
        NEW.supprime_le := pg_catalog.now();
    END IF;

    NEW.date_maj := pg_catalog.now();
    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.protect_reponse_fields()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
    IF NEW.id IS DISTINCT FROM OLD.id
       OR NEW.question_id IS DISTINCT FROM OLD.question_id
       OR (
           NEW.auteur_id IS DISTINCT FROM OLD.auteur_id
           AND NOT (OLD.auteur_id IS NOT NULL AND NEW.auteur_id IS NULL)
       )
       OR NEW.date_creation IS DISTINCT FROM OLD.date_creation
    THEN
        RAISE EXCEPTION 'Modification non autorisée des champs protégés de la réponse';
    END IF;

    IF OLD.supprime_le IS NULL
       AND NEW.supprime_le IS NOT NULL
       AND EXISTS (
           SELECT 1
           FROM public.question q
           WHERE q.id = OLD.question_id
             AND q.reponse_acceptee_id = OLD.id
       )
    THEN
        RAISE EXCEPTION 'Une réponse acceptée ne peut pas être supprimée';
    END IF;

    IF OLD.supprime_le IS NOT NULL
       AND NOT (OLD.auteur_id IS NOT NULL AND NEW.auteur_id IS NULL)
    THEN
        RAISE EXCEPTION 'Réponse déjà supprimée';
    END IF;

    IF NEW.supprime_le IS NOT NULL AND OLD.supprime_le IS NULL THEN
        NEW.supprime_le := pg_catalog.now();
    END IF;

    NEW.date_maj := pg_catalog.now();
    RETURN NEW;
END;
$$;

-- =====================================================
-- 4. Index nécessaires aux actions référentielles
-- =====================================================
-- PostgreSQL doit retrouver rapidement les lignes liées pendant la suppression
-- transactionnelle d'un profil.
CREATE INDEX IF NOT EXISTS idx_communaute_createur
ON public.communaute(cree_par);

CREATE INDEX IF NOT EXISTS idx_commentaire_auteur
ON public.commentaire(auteur_id);

CREATE INDEX IF NOT EXISTS idx_reaction_utilisateur
ON public.reaction(utilisateur_id);

CREATE INDEX IF NOT EXISTS idx_reponse_auteur
ON public.reponse(auteur_id);

CREATE INDEX IF NOT EXISTS idx_espace_mentorat_mentor
ON public.espace_mentorat(mentor_id);

CREATE INDEX IF NOT EXISTS idx_soumission_exercice_utilisateur
ON public.soumission_exercice(utilisateur_id);

CREATE INDEX IF NOT EXISTS idx_message_mentorat_auteur
ON public.message_mentorat(auteur_id);

CREATE INDEX IF NOT EXISTS idx_membre_projet_utilisateur
ON public.membre_projet(utilisateur_id);

CREATE INDEX IF NOT EXISTS idx_revue_code_auteur
ON public.revue_code(auteur_id);

CREATE INDEX IF NOT EXISTS idx_commentaire_revue_auteur
ON public.commentaire_revue(auteur_id);

CREATE INDEX IF NOT EXISTS idx_opportunite_publie_par
ON public.opportunite(publie_par);

CREATE INDEX IF NOT EXISTS idx_signalement_signaleur
ON public.signalement(signaleur_id);

CREATE INDEX IF NOT EXISTS idx_signalement_traite_par
ON public.signalement(traite_par);
