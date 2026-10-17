-- =====================================================
-- WALLAN : modération communautaire et administration
-- =====================================================

-- Centraliser la vérification administrateur évite toute récursion RLS lors
-- de la modification de user_roles. La fonction ne crée aucun droit métier.
CREATE FUNCTION public.is_active_admin()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
    SELECT EXISTS (
        SELECT 1
        FROM public.user_roles ur
        WHERE ur.user_id = (SELECT auth.uid())
          AND ur.role = 'ADMIN'
          AND ur.statut = 'ACTIF'
    );
$$;

REVOKE ALL ON FUNCTION public.is_active_admin() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.is_active_admin() TO authenticated;

-- Historique append-only des décisions sensibles. Les lignes ne sont jamais
-- modifiées ni supprimées par les clients authentifiés.
CREATE TABLE public.action_moderation (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    acteur_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    communaute_id BIGINT REFERENCES public.communaute(id) ON DELETE SET NULL,
    type_action VARCHAR(40) NOT NULL CHECK (type_action IN (
        'MASQUER_PUBLICATION',
        'MASQUER_COMMENTAIRE',
        'TRAITER_SIGNALEMENT',
        'CHANGER_STATUT_COMPTE',
        'CHANGER_ROLE_COMMUNAUTE'
    )),
    type_cible VARCHAR(30) NOT NULL,
    cible_id TEXT NOT NULL,
    ancienne_valeur TEXT,
    nouvelle_valeur TEXT,
    date_action TIMESTAMPTZ NOT NULL DEFAULT pg_catalog.now()
);

CREATE INDEX idx_action_moderation_communaute_date
ON public.action_moderation(communaute_id, date_action DESC);

ALTER TABLE public.action_moderation ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admin consulter historique moderation"
ON public.action_moderation
FOR SELECT TO authenticated
USING ((SELECT public.is_active_admin()));

CREATE POLICY "Moderateur consulter historique communaute"
ON public.action_moderation
FOR SELECT TO authenticated
USING (
    communaute_id IS NOT NULL
    AND EXISTS (
        SELECT 1
        FROM public.adhesion_communaute ac
        WHERE ac.communaute_id = action_moderation.communaute_id
          AND ac.utilisateur_id = (SELECT auth.uid())
          AND ac.role = 'MODERATEUR'
    )
);

-- Seuls les comptes actifs peuvent lire l'historique qui leur est autorisé.
CREATE POLICY "Compte actif SELECT historique moderation"
ON public.action_moderation AS RESTRICTIVE
FOR SELECT TO authenticated
USING ((SELECT public.is_active_user()));

-- Les auteurs conservent l'édition de leur contenu. Un modérateur ou un
-- administrateur agissant sur le contenu d'autrui ne peut que le masquer.
CREATE OR REPLACE FUNCTION public.protect_publication_fields()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        NEW.date_creation := pg_catalog.now();
        NEW.date_maj := NULL;
        RETURN NEW;
    END IF;

    IF NEW.auteur_id IS DISTINCT FROM OLD.auteur_id
       OR NEW.communaute_id IS DISTINCT FROM OLD.communaute_id
       OR NEW.date_creation IS DISTINCT FROM OLD.date_creation
    THEN
        RAISE EXCEPTION 'Modification non autorisée des champs protégés';
    END IF;

    IF OLD.supprime_le IS NOT NULL THEN
        RAISE EXCEPTION 'Publication déjà supprimée';
    END IF;

    IF OLD.auteur_id IS DISTINCT FROM (SELECT auth.uid())
       AND (
           NEW.contenu IS DISTINCT FROM OLD.contenu
           OR NEW.lien_url IS DISTINCT FROM OLD.lien_url
           OR NEW.image_url IS DISTINCT FROM OLD.image_url
       )
    THEN
        RAISE EXCEPTION 'La modération ne peut pas modifier le contenu original';
    END IF;

    IF NEW.supprime_le IS NOT NULL AND OLD.supprime_le IS NULL THEN
        NEW.supprime_le := pg_catalog.now();

        INSERT INTO public.action_moderation (
            acteur_id, communaute_id, type_action, type_cible, cible_id,
            ancienne_valeur, nouvelle_valeur
        ) VALUES (
            (SELECT auth.uid()), OLD.communaute_id, 'MASQUER_PUBLICATION',
            'PUBLICATION', OLD.id::TEXT, 'VISIBLE', 'MASQUEE'
        );
    END IF;

    NEW.date_maj := pg_catalog.now();
    RETURN NEW;
END;
$$;

DROP TRIGGER trg_protect_publication_fields ON public.publication;

CREATE TRIGGER trg_protect_publication_fields
BEFORE INSERT OR UPDATE ON public.publication
FOR EACH ROW
EXECUTE FUNCTION public.protect_publication_fields();

CREATE OR REPLACE FUNCTION public.protect_commentaire_fields()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    communaute_cible BIGINT;
BEGIN
    IF TG_OP = 'INSERT' THEN
        NEW.date_creation := pg_catalog.now();
        RETURN NEW;
    END IF;

    IF NEW.auteur_id IS DISTINCT FROM OLD.auteur_id
       OR NEW.publication_id IS DISTINCT FROM OLD.publication_id
       OR NEW.date_creation IS DISTINCT FROM OLD.date_creation
    THEN
        RAISE EXCEPTION 'Modification non autorisée des champs protégés';
    END IF;

    IF OLD.supprime_le IS NOT NULL THEN
        RAISE EXCEPTION 'Commentaire déjà supprimé';
    END IF;

    IF OLD.auteur_id IS DISTINCT FROM (SELECT auth.uid())
       AND NEW.contenu IS DISTINCT FROM OLD.contenu
    THEN
        RAISE EXCEPTION 'La modération ne peut pas modifier le contenu original';
    END IF;

    IF NEW.supprime_le IS NOT NULL AND OLD.supprime_le IS NULL THEN
        NEW.supprime_le := pg_catalog.now();

        SELECT p.communaute_id
        INTO communaute_cible
        FROM public.publication p
        WHERE p.id = OLD.publication_id;

        INSERT INTO public.action_moderation (
            acteur_id, communaute_id, type_action, type_cible, cible_id,
            ancienne_valeur, nouvelle_valeur
        ) VALUES (
            (SELECT auth.uid()), communaute_cible, 'MASQUER_COMMENTAIRE',
            'COMMENTAIRE', OLD.id::TEXT, 'VISIBLE', 'MASQUE'
        );
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER trg_protect_commentaire_fields ON public.commentaire;

CREATE TRIGGER trg_protect_commentaire_fields
BEFORE INSERT OR UPDATE ON public.commentaire
FOR EACH ROW
EXECUTE FUNCTION public.protect_commentaire_fields();

-- Résoudre l'appartenance communautaire hors des politiques RLS des contenus
-- évite qu'une cible devienne inaccessible après son masquage. La fonction ne
-- renvoie aucune donnée : uniquement une autorisation booléenne.
CREATE FUNCTION public.can_moderate_community_target(
    target_type TEXT,
    target_id TEXT
)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
    SELECT CASE
        WHEN target_type = 'PUBLICATION' AND target_id ~ '^[0-9]+$' THEN
            EXISTS (
                SELECT 1
                FROM public.publication p
                JOIN public.adhesion_communaute ac
                  ON ac.communaute_id = p.communaute_id
                WHERE p.id = target_id::BIGINT
                  AND ac.utilisateur_id = (SELECT auth.uid())
                  AND ac.role = 'MODERATEUR'
            )
        WHEN target_type = 'COMMENTAIRE' AND target_id ~ '^[0-9]+$' THEN
            EXISTS (
                SELECT 1
                FROM public.commentaire c
                JOIN public.publication p ON p.id = c.publication_id
                JOIN public.adhesion_communaute ac
                  ON ac.communaute_id = p.communaute_id
                WHERE c.id = target_id::BIGINT
                  AND ac.utilisateur_id = (SELECT auth.uid())
                  AND ac.role = 'MODERATEUR'
            )
        ELSE FALSE
    END;
$$;

REVOKE ALL ON FUNCTION public.can_moderate_community_target(TEXT, TEXT)
FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.can_moderate_community_target(TEXT, TEXT)
TO authenticated;

-- Un modérateur peut uniquement masquer les contenus de sa communauté.
CREATE POLICY "Moderateur masquer publication"
ON public.publication
FOR UPDATE TO authenticated
USING (
    supprime_le IS NULL
    AND communaute_id IS NOT NULL
    AND EXISTS (
        SELECT 1
        FROM public.adhesion_communaute ac
        WHERE ac.communaute_id = publication.communaute_id
          AND ac.utilisateur_id = (SELECT auth.uid())
          AND ac.role = 'MODERATEUR'
    )
)
WITH CHECK (
    communaute_id IS NOT NULL
    AND supprime_le IS NOT NULL
    AND EXISTS (
        SELECT 1
        FROM public.adhesion_communaute ac
        WHERE ac.communaute_id = publication.communaute_id
          AND ac.utilisateur_id = (SELECT auth.uid())
          AND ac.role = 'MODERATEUR'
    )
);

CREATE POLICY "Moderateur masquer commentaire"
ON public.commentaire
FOR UPDATE TO authenticated
USING (
    supprime_le IS NULL
    AND (SELECT public.can_moderate_community_target(
        'COMMENTAIRE', commentaire.id::TEXT
    ))
)
WITH CHECK (
    supprime_le IS NOT NULL
    AND (SELECT public.can_moderate_community_target(
        'COMMENTAIRE', commentaire.id::TEXT
    ))
);

CREATE POLICY "Admin moderer publications"
ON public.publication
FOR UPDATE TO authenticated
USING (supprime_le IS NULL AND (SELECT public.is_active_admin()))
WITH CHECK (supprime_le IS NOT NULL AND (SELECT public.is_active_admin()));

CREATE POLICY "Admin moderer commentaires"
ON public.commentaire
FOR UPDATE TO authenticated
USING (supprime_le IS NULL AND (SELECT public.is_active_admin()))
WITH CHECK (supprime_le IS NOT NULL AND (SELECT public.is_active_admin()));

-- Le traitement d'un signalement fixe toujours l'acteur et la date côté base.
ALTER TABLE public.signalement
    ADD COLUMN date_traitement TIMESTAMPTZ;

CREATE FUNCTION public.protect_signalement_fields()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    communaute_cible BIGINT;
BEGIN
    IF TG_OP = 'INSERT' THEN
        NEW.date_creation := pg_catalog.now();
        NEW.traite_par := NULL;
        NEW.date_traitement := NULL;
        RETURN NEW;
    END IF;

    IF NEW.id IS DISTINCT FROM OLD.id
       OR NEW.signaleur_id IS DISTINCT FROM OLD.signaleur_id
       OR NEW.type_cible IS DISTINCT FROM OLD.type_cible
       OR NEW.cible_id IS DISTINCT FROM OLD.cible_id
       OR NEW.motif IS DISTINCT FROM OLD.motif
       OR NEW.date_creation IS DISTINCT FROM OLD.date_creation
    THEN
        RAISE EXCEPTION 'Modification non autorisée du signalement';
    END IF;

    IF NEW.statut IS NOT DISTINCT FROM OLD.statut THEN
        IF NEW.traite_par IS DISTINCT FROM OLD.traite_par
           OR NEW.date_traitement IS DISTINCT FROM OLD.date_traitement
        THEN
            RAISE EXCEPTION 'La réattribution directe d’un signalement est interdite';
        END IF;
        RETURN NEW;
    END IF;

    NEW.traite_par := (SELECT auth.uid());
    NEW.date_traitement := pg_catalog.now();

    IF OLD.type_cible = 'PUBLICATION' THEN
        SELECT p.communaute_id INTO communaute_cible
        FROM public.publication p
        WHERE p.id = CASE WHEN OLD.cible_id ~ '^[0-9]+$'
                          THEN OLD.cible_id::BIGINT END;
    ELSIF OLD.type_cible = 'COMMENTAIRE' THEN
        SELECT p.communaute_id INTO communaute_cible
        FROM public.commentaire c
        JOIN public.publication p ON p.id = c.publication_id
        WHERE c.id = CASE WHEN OLD.cible_id ~ '^[0-9]+$'
                          THEN OLD.cible_id::BIGINT END;
    END IF;

    INSERT INTO public.action_moderation (
        acteur_id, communaute_id, type_action, type_cible, cible_id,
        ancienne_valeur, nouvelle_valeur
    ) VALUES (
        (SELECT auth.uid()), communaute_cible, 'TRAITER_SIGNALEMENT',
        'SIGNALEMENT', OLD.id::TEXT, OLD.statut, NEW.statut
    );

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_protect_signalement_fields
BEFORE INSERT OR UPDATE ON public.signalement
FOR EACH ROW
EXECUTE FUNCTION public.protect_signalement_fields();

-- Les modérateurs voient et traitent uniquement les signalements portant sur
-- une publication ou un commentaire de leur propre communauté.
CREATE POLICY "Moderateur consulter signalements communaute"
ON public.signalement
FOR SELECT TO authenticated
USING ((SELECT public.can_moderate_community_target(type_cible, cible_id)));

CREATE POLICY "Moderateur traiter signalements communaute"
ON public.signalement
FOR UPDATE TO authenticated
USING ((SELECT public.can_moderate_community_target(type_cible, cible_id)))
WITH CHECK ((SELECT public.can_moderate_community_target(type_cible, cible_id)));

CREATE POLICY "Admin consulter signalements"
ON public.signalement
FOR SELECT TO authenticated
USING ((SELECT public.is_active_admin()));

CREATE POLICY "Admin traiter signalements"
ON public.signalement
FOR UPDATE TO authenticated
USING ((SELECT public.is_active_admin()))
WITH CHECK ((SELECT public.is_active_admin()));

-- Les administrateurs peuvent uniquement changer le statut d'un compte.
-- Le rôle global reste hors de portée des clients, y compris administrateurs.
GRANT UPDATE (statut) ON public.user_roles TO authenticated;

CREATE POLICY "Admin changer statut compte"
ON public.user_roles
FOR UPDATE TO authenticated
USING ((SELECT public.is_active_admin()))
WITH CHECK ((SELECT public.is_active_admin()));

CREATE FUNCTION public.audit_user_status_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
    IF NEW.user_id IS DISTINCT FROM OLD.user_id
       OR NEW.role IS DISTINCT FROM OLD.role
       OR NEW.created_at IS DISTINCT FROM OLD.created_at
    THEN
        RAISE EXCEPTION 'Seul le statut du compte peut être modifié';
    END IF;

    IF OLD.statut = 'SUPPRIME' OR NEW.statut = 'SUPPRIME' THEN
        RAISE EXCEPTION 'Le statut SUPPRIME ne peut pas être administré depuis le client';
    END IF;

    IF NEW.statut IS DISTINCT FROM OLD.statut THEN
        INSERT INTO public.action_moderation (
            acteur_id, type_action, type_cible, cible_id,
            ancienne_valeur, nouvelle_valeur
        ) VALUES (
            (SELECT auth.uid()), 'CHANGER_STATUT_COMPTE', 'COMPTE',
            OLD.user_id::TEXT, OLD.statut::TEXT, NEW.statut::TEXT
        );
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_audit_user_status_change
BEFORE UPDATE ON public.user_roles
FOR EACH ROW
EXECUTE FUNCTION public.audit_user_status_change();

-- Une adhésion ne peut être déplacée ou réattribuée ; seul son rôle change.
CREATE FUNCTION public.protect_adhesion_communaute_fields()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        NEW.date_adhesion := pg_catalog.now();
        RETURN NEW;
    END IF;

    IF NEW.utilisateur_id IS DISTINCT FROM OLD.utilisateur_id
       OR NEW.communaute_id IS DISTINCT FROM OLD.communaute_id
       OR NEW.date_adhesion IS DISTINCT FROM OLD.date_adhesion
    THEN
        RAISE EXCEPTION 'Seul le rôle communautaire peut être modifié';
    END IF;

    IF NEW.role IS DISTINCT FROM OLD.role THEN
        INSERT INTO public.action_moderation (
            acteur_id, communaute_id, type_action, type_cible, cible_id,
            ancienne_valeur, nouvelle_valeur
        ) VALUES (
            (SELECT auth.uid()), OLD.communaute_id, 'CHANGER_ROLE_COMMUNAUTE',
            'ADHESION', OLD.utilisateur_id::TEXT, OLD.role, NEW.role
        );
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_protect_adhesion_communaute_fields
BEFORE INSERT OR UPDATE ON public.adhesion_communaute
FOR EACH ROW
EXECUTE FUNCTION public.protect_adhesion_communaute_fields();

-- Protéger l'identité et la date des communautés administrées.
CREATE FUNCTION public.protect_communaute_fields()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        NEW.date_creation := pg_catalog.now();
        RETURN NEW;
    END IF;

    IF NEW.id IS DISTINCT FROM OLD.id
       OR NEW.cree_par IS DISTINCT FROM OLD.cree_par
       OR NEW.date_creation IS DISTINCT FROM OLD.date_creation
    THEN
        RAISE EXCEPTION 'Modification non autorisée des champs protégés de la communauté';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_protect_communaute_fields
BEFORE INSERT OR UPDATE ON public.communaute
FOR EACH ROW
EXECUTE FUNCTION public.protect_communaute_fields();

-- Gestion complète des opportunités, réservée aux administrateurs actifs.
CREATE POLICY "Admin consulter opportunites"
ON public.opportunite
FOR SELECT TO authenticated
USING ((SELECT public.is_active_admin()));

CREATE POLICY "Admin creer opportunite"
ON public.opportunite
FOR INSERT TO authenticated
WITH CHECK (
    publie_par = (SELECT auth.uid())
    AND (SELECT public.is_active_admin())
);

CREATE POLICY "Admin modifier opportunite"
ON public.opportunite
FOR UPDATE TO authenticated
USING ((SELECT public.is_active_admin()))
WITH CHECK ((SELECT public.is_active_admin()));

CREATE FUNCTION public.protect_opportunite_fields()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        NEW.date_creation := pg_catalog.now();
        NEW.date_maj := NULL;
        RETURN NEW;
    END IF;

    IF NEW.id IS DISTINCT FROM OLD.id
       OR NEW.publie_par IS DISTINCT FROM OLD.publie_par
       OR NEW.date_creation IS DISTINCT FROM OLD.date_creation
    THEN
        RAISE EXCEPTION 'Modification non autorisée des champs protégés de l’opportunité';
    END IF;

    NEW.date_maj := pg_catalog.now();
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_protect_opportunite_fields
BEFORE INSERT OR UPDATE ON public.opportunite
FOR EACH ROW
EXECUTE FUNCTION public.protect_opportunite_fields();
