-- =====================================================
-- WALLAN : corrections prioritaires issues de l'audit final
-- =====================================================

-- Un administrateur actif doit voir les lignes qu'il administre. Cette
-- politique complète le droit UPDATE(statut) existant sans accorder le droit
-- de modifier la colonne role, qui reste révoqué aux clients authentifiés.
CREATE POLICY "Admin consulter roles utilisateurs"
ON public.user_roles
FOR SELECT TO authenticated
USING ((SELECT public.is_active_admin()));

-- Un commentaire ou une réaction ne doit plus rester accessible directement
-- lorsque sa publication parente a été masquée.
DROP POLICY "Lecture commentaires"
ON public.commentaire;

CREATE POLICY "Lecture commentaires"
ON public.commentaire
FOR SELECT TO anon, authenticated
USING (
    supprime_le IS NULL
    AND EXISTS (
        SELECT 1
        FROM public.publication p
        WHERE p.id = commentaire.publication_id
          AND p.supprime_le IS NULL
    )
);

DROP POLICY "Lecture reactions"
ON public.reaction;

CREATE POLICY "Lecture reactions"
ON public.reaction
FOR SELECT TO anon, authenticated
USING (
    EXISTS (
        SELECT 1
        FROM public.publication p
        WHERE p.id = reaction.publication_id
          AND p.supprime_le IS NULL
    )
);

-- Vérifier et normaliser la cible d'un nouveau signalement. SECURITY DEFINER
-- permet le contrôle d'existence sans dépendre de la visibilité RLS de la
-- cible ; la fonction ne renvoie ni ne modifie aucun contenu métier.
CREATE FUNCTION public.validate_signalement_target()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    cible_bigint BIGINT;
    cible_uuid UUID;
    cible_existe BOOLEAN := FALSE;
BEGIN
    IF NEW.type_cible IN ('PUBLICATION', 'COMMENTAIRE', 'QUESTION', 'REPONSE', 'MESSAGE') THEN
        IF NEW.cible_id !~ '^[0-9]+$' THEN
            RAISE EXCEPTION 'Identifiant de cible invalide pour le signalement';
        END IF;

        cible_bigint := NEW.cible_id::BIGINT;
        NEW.cible_id := cible_bigint::TEXT;

        CASE NEW.type_cible
            WHEN 'PUBLICATION' THEN
                SELECT EXISTS (
                    SELECT 1 FROM public.publication p WHERE p.id = cible_bigint
                ) INTO cible_existe;
            WHEN 'COMMENTAIRE' THEN
                SELECT EXISTS (
                    SELECT 1 FROM public.commentaire c WHERE c.id = cible_bigint
                ) INTO cible_existe;
            WHEN 'QUESTION' THEN
                SELECT EXISTS (
                    SELECT 1 FROM public.question q WHERE q.id = cible_bigint
                ) INTO cible_existe;
            WHEN 'REPONSE' THEN
                SELECT EXISTS (
                    SELECT 1 FROM public.reponse r WHERE r.id = cible_bigint
                ) INTO cible_existe;
            WHEN 'MESSAGE' THEN
                SELECT EXISTS (
                    SELECT 1 FROM public.message_mentorat m WHERE m.id = cible_bigint
                ) INTO cible_existe;
        END CASE;
    ELSIF NEW.type_cible = 'PROFIL' THEN
        BEGIN
            cible_uuid := NEW.cible_id::UUID;
        EXCEPTION
            WHEN invalid_text_representation THEN
                RAISE EXCEPTION 'Identifiant de profil invalide pour le signalement';
        END;

        NEW.cible_id := cible_uuid::TEXT;
        SELECT EXISTS (
            SELECT 1 FROM public.profiles p WHERE p.id = cible_uuid
        ) INTO cible_existe;
    END IF;

    IF NOT cible_existe THEN
        RAISE EXCEPTION 'La cible du signalement n’existe pas';
    END IF;

    RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.validate_signalement_target() FROM PUBLIC;

CREATE TRIGGER trg_validate_signalement_target
BEFORE INSERT ON public.signalement
FOR EACH ROW
EXECUTE FUNCTION public.validate_signalement_target();

-- Conserver les signalements déjà traités, mais empêcher qu'un même membre
-- ouvre plusieurs fois le même signalement sur une cible identique.
CREATE UNIQUE INDEX uq_signalement_ouvert_par_cible
ON public.signalement(signaleur_id, type_cible, cible_id)
WHERE statut = 'OUVERT';

-- Accélérer la résolution des cibles dans les politiques de modération.
CREATE INDEX idx_signalement_type_cible
ON public.signalement(type_cible, cible_id);

-- Les politiques des exercices filtrent fréquemment par espace. L'unicité de
-- soumission couvre déjà exercice_id en première colonne et ne nécessite pas
-- d'index supplémentaire.
CREATE INDEX idx_exercice_espace
ON public.exercice(espace_id);

-- Les contraintes NOT VALID protègent immédiatement les nouvelles écritures
-- sans bloquer le déploiement si des données historiques doivent être nettoyées.
ALTER TABLE public.exercice
    ADD CONSTRAINT exercice_titre_non_vide
        CHECK (LENGTH(BTRIM(titre)) > 0) NOT VALID,
    ADD CONSTRAINT exercice_description_non_vide
        CHECK (LENGTH(BTRIM(description)) > 0) NOT VALID;

ALTER TABLE public.soumission_exercice
    ADD CONSTRAINT soumission_contenu_non_vide
        CHECK (
            NULLIF(BTRIM(url_depot), '') IS NOT NULL
            OR NULLIF(BTRIM(commentaire), '') IS NOT NULL
        ) NOT VALID;

-- Garantir les relations chronologiques certaines, sans imposer qu'une date
-- facultative soit renseignée ni présumer que la limite précède le début.
ALTER TABLE public.opportunite
    ADD CONSTRAINT opportunite_debut_avant_fin
        CHECK (
            date_debut IS NULL
            OR date_fin IS NULL
            OR date_debut <= date_fin
        ) NOT VALID,
    ADD CONSTRAINT opportunite_limite_avant_fin
        CHECK (
            date_limite IS NULL
            OR date_fin IS NULL
            OR date_limite <= date_fin
        ) NOT VALID;
