-- =====================================================
-- WALLAN : intégrité de l'entraide, du mentorat et des notifications
-- =====================================================

-- Une réponse acceptée doit appartenir à la question concernée et rester
-- visible. Les champs d'identité et de création d'une question sont immuables.
CREATE OR REPLACE FUNCTION public.protect_question_fields()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
    IF NEW.id IS DISTINCT FROM OLD.id
       OR NEW.auteur_id IS DISTINCT FROM OLD.auteur_id
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

CREATE TRIGGER trg_protect_question_fields
BEFORE UPDATE ON public.question
FOR EACH ROW
EXECUTE FUNCTION public.protect_question_fields();

-- Une réponse ne peut pas être déplacée vers une autre question ni attribuée
-- à un autre auteur après sa création.
CREATE OR REPLACE FUNCTION public.protect_reponse_fields()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
    IF NEW.id IS DISTINCT FROM OLD.id
       OR NEW.question_id IS DISTINCT FROM OLD.question_id
       OR NEW.auteur_id IS DISTINCT FROM OLD.auteur_id
       OR NEW.date_creation IS DISTINCT FROM OLD.date_creation
    THEN
        RAISE EXCEPTION 'Modification non autorisée des champs protégés de la réponse';
    END IF;

    -- Une réponse déjà choisie comme réponse acceptée ne peut pas être masquée.
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

    IF OLD.supprime_le IS NOT NULL THEN
        RAISE EXCEPTION 'Réponse déjà supprimée';
    END IF;

    IF NEW.supprime_le IS NOT NULL THEN
        NEW.supprime_le := pg_catalog.now();
    END IF;

    NEW.date_maj := pg_catalog.now();
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_protect_reponse_fields
BEFORE UPDATE ON public.reponse
FOR EACH ROW
EXECUTE FUNCTION public.protect_reponse_fields();

-- L'espace, l'auteur et la date d'origine d'un message sont immuables.
CREATE OR REPLACE FUNCTION public.protect_message_mentorat_fields()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
    IF NEW.id IS DISTINCT FROM OLD.id
       OR NEW.espace_id IS DISTINCT FROM OLD.espace_id
       OR NEW.auteur_id IS DISTINCT FROM OLD.auteur_id
       OR NEW.date_creation IS DISTINCT FROM OLD.date_creation
    THEN
        RAISE EXCEPTION 'Modification non autorisée des champs protégés du message';
    END IF;

    IF OLD.supprime_le IS NOT NULL THEN
        RAISE EXCEPTION 'Message déjà supprimé';
    END IF;

    IF NEW.supprime_le IS NOT NULL THEN
        NEW.supprime_le := pg_catalog.now();
    END IF;

    NEW.date_maj := pg_catalog.now();
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_protect_message_mentorat_fields
BEFORE UPDATE ON public.message_mentorat
FOR EACH ROW
EXECUTE FUNCTION public.protect_message_mentorat_fields();

-- L'auteur ne peut modifier son message que s'il appartient toujours à
-- l'espace, ou s'il en est le mentor. L'espace peut être archivé sans perdre
-- la possibilité de corriger ou supprimer ses propres messages.
DROP POLICY IF EXISTS "Modifier messages mentorat"
ON public.message_mentorat;

CREATE POLICY "Modifier messages mentorat"
ON public.message_mentorat
FOR UPDATE TO authenticated
USING (
    auteur_id = (SELECT auth.uid())
    AND supprime_le IS NULL
    AND EXISTS (
        SELECT 1
        FROM public.espace_mentorat e
        WHERE e.id = message_mentorat.espace_id
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
)
WITH CHECK (
    auteur_id = (SELECT auth.uid())
    AND EXISTS (
        SELECT 1
        FROM public.espace_mentorat e
        WHERE e.id = message_mentorat.espace_id
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

-- Un mentor peut répondre à une demande, mais ne peut jamais changer
-- l'espace, l'identité du demandeur ou la date de la demande.
CREATE OR REPLACE FUNCTION public.protect_membre_espace_fields()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
    IF NEW.espace_id IS DISTINCT FROM OLD.espace_id
       OR NEW.utilisateur_id IS DISTINCT FROM OLD.utilisateur_id
       OR NEW.date_demande IS DISTINCT FROM OLD.date_demande
    THEN
        RAISE EXCEPTION 'Modification non autorisée de l’identité de la demande de mentorat';
    END IF;

    IF NEW.statut IS DISTINCT FROM OLD.statut THEN
        NEW.date_reponse := pg_catalog.now();
    ELSE
        NEW.date_reponse := OLD.date_reponse;
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_protect_membre_espace_fields
BEFORE UPDATE ON public.membre_espace
FOR EACH ROW
EXECUTE FUNCTION public.protect_membre_espace_fields();

-- Le destinataire peut uniquement changer l'état lu/non lu. Le contenu et
-- les métadonnées de la notification restent sous le contrôle du serveur.
CREATE OR REPLACE FUNCTION public.protect_notification_fields()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
    IF NEW.id IS DISTINCT FROM OLD.id
       OR NEW.destinataire_id IS DISTINCT FROM OLD.destinataire_id
       OR NEW.type IS DISTINCT FROM OLD.type
       OR NEW.reference_id IS DISTINCT FROM OLD.reference_id
       OR NEW.date_creation IS DISTINCT FROM OLD.date_creation
    THEN
        RAISE EXCEPTION 'Seul le statut de lecture d’une notification peut être modifié';
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_protect_notification_fields
BEFORE UPDATE ON public.notification
FOR EACH ROW
EXECUTE FUNCTION public.protect_notification_fields();
