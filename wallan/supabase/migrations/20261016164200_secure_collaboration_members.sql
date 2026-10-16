-- =====================================================
-- WALLAN : sécuriser les demandes de collaboration
-- =====================================================

-- Une demande ne peut viser qu'un projet encore ouvert. Le champ role reste
-- libre car il décrit le rôle recherché dans le projet et non un privilège SQL.
DROP POLICY IF EXISTS "Rejoindre projet"
ON public.membre_projet;

CREATE POLICY "Rejoindre projet"
ON public.membre_projet
FOR INSERT TO authenticated
WITH CHECK (
    utilisateur_id = (SELECT auth.uid())
    AND statut = 'EN_ATTENTE'
    AND EXISTS (
        SELECT 1
        FROM public.projet_collaboratif p
        WHERE p.id = membre_projet.projet_id
          AND p.statut = 'OUVERT'
          AND p.createur_id <> (SELECT auth.uid())
    )
);

-- Le créateur doit voir les demandes en attente de son propre projet.
CREATE POLICY "Createur consulter demandes projet"
ON public.membre_projet
FOR SELECT TO authenticated
USING (
    EXISTS (
        SELECT 1
        FROM public.projet_collaboratif p
        WHERE p.id = membre_projet.projet_id
          AND p.createur_id = (SELECT auth.uid())
    )
);

-- Le créateur peut accepter ou refuser les demandes de son projet.
CREATE POLICY "Createur gerer demandes projet"
ON public.membre_projet
FOR UPDATE TO authenticated
USING (
    EXISTS (
        SELECT 1
        FROM public.projet_collaboratif p
        WHERE p.id = membre_projet.projet_id
          AND p.createur_id = (SELECT auth.uid())
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1
        FROM public.projet_collaboratif p
        WHERE p.id = membre_projet.projet_id
          AND p.createur_id = (SELECT auth.uid())
    )
);

-- Empêcher qu'une mise à jour transforme une demande en adhésion d'un autre
-- utilisateur ou la déplace vers un autre projet.
CREATE OR REPLACE FUNCTION public.protect_membre_projet_fields()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
    IF NEW.projet_id IS DISTINCT FROM OLD.projet_id
       OR NEW.utilisateur_id IS DISTINCT FROM OLD.utilisateur_id
       OR NEW.date_demande IS DISTINCT FROM OLD.date_demande
    THEN
        RAISE EXCEPTION 'Modification non autorisée de l’identité de la demande de collaboration';
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_protect_membre_projet_fields
BEFORE UPDATE ON public.membre_projet
FOR EACH ROW
EXECUTE FUNCTION public.protect_membre_projet_fields();
