-- =====================================================
-- WALLAN : permettre le provisionnement serveur des rôles globaux
-- =====================================================

-- Les rôles globaux restent immuables depuis toute session utilisateur
-- authentifiée. Une session PostgreSQL de confiance, sans identité JWT, doit
-- toutefois pouvoir promouvoir un premier administrateur ou gérer les rôles
-- lors d'une opération serveur contrôlée.
CREATE OR REPLACE FUNCTION public.audit_user_status_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
    IF NEW.user_id IS DISTINCT FROM OLD.user_id
       OR NEW.created_at IS DISTINCT FROM OLD.created_at
    THEN
        RAISE EXCEPTION 'Modification non autorisée des champs protégés du compte';
    END IF;

    IF NEW.role IS DISTINCT FROM OLD.role
       AND (SELECT auth.uid()) IS NOT NULL
    THEN
        RAISE EXCEPTION 'Le rôle global ne peut pas être modifié depuis le client';
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
