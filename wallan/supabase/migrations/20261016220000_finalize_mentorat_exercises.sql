-- =====================================================
-- WALLAN : gestion et correction des exercices de mentorat
-- =====================================================

-- L'appréciation reste volontairement qualitative : aucune note chiffrée
-- ni donnée assimilable à un bulletin n'est introduite.
CREATE TYPE public.appreciation_exercice AS ENUM (
    'A_AMELIORER',
    'BON_TRAVAIL',
    'EXCELLENT'
);

ALTER TABLE public.soumission_exercice
    ADD COLUMN appreciation public.appreciation_exercice;

-- Les identifiants, relations et dates d'origine d'un exercice sont
-- immuables. La date fournie par un client est toujours remplacée côté base.
CREATE FUNCTION public.protect_exercice_fields()
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
       OR NEW.espace_id IS DISTINCT FROM OLD.espace_id
       OR NEW.date_creation IS DISTINCT FROM OLD.date_creation
    THEN
        RAISE EXCEPTION 'Modification non autorisée des champs protégés de l’exercice';
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_protect_exercice_fields
BEFORE INSERT OR UPDATE ON public.exercice
FOR EACH ROW
EXECUTE FUNCTION public.protect_exercice_fields();

-- Une correction ne doit jamais pouvoir déplacer ou réattribuer une
-- soumission, ni réécrire le travail remis par le mentoré.
CREATE FUNCTION public.protect_soumission_exercice_fields()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        NEW.date_soumission := pg_catalog.now();
        RETURN NEW;
    END IF;

    IF NEW.id IS DISTINCT FROM OLD.id
       OR NEW.exercice_id IS DISTINCT FROM OLD.exercice_id
       OR NEW.utilisateur_id IS DISTINCT FROM OLD.utilisateur_id
       OR NEW.url_depot IS DISTINCT FROM OLD.url_depot
       OR NEW.commentaire IS DISTINCT FROM OLD.commentaire
       OR NEW.date_soumission IS DISTINCT FROM OLD.date_soumission
    THEN
        RAISE EXCEPTION 'Seuls le retour et l’appréciation du mentor peuvent être modifiés';
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_protect_soumission_exercice_fields
BEFORE INSERT OR UPDATE ON public.soumission_exercice
FOR EACH ROW
EXECUTE FUNCTION public.protect_soumission_exercice_fields();

-- Le propriétaire de l'espace peut modifier uniquement ses exercices.
CREATE POLICY "Modifier exercice"
ON public.exercice
FOR UPDATE TO authenticated
USING (
    EXISTS (
        SELECT 1
        FROM public.espace_mentorat e
        WHERE e.id = exercice.espace_id
          AND e.mentor_id = (SELECT auth.uid())
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1
        FROM public.espace_mentorat e
        WHERE e.id = exercice.espace_id
          AND e.mentor_id = (SELECT auth.uid())
    )
);

-- Un mentoré ne peut pas préremplir sa propre correction au moment du dépôt.
DROP POLICY "Soumettre exercice"
ON public.soumission_exercice;

CREATE POLICY "Soumettre exercice"
ON public.soumission_exercice
FOR INSERT TO authenticated
WITH CHECK (
    utilisateur_id = (SELECT auth.uid())
    AND retour_mentor IS NULL
    AND appreciation IS NULL
    AND EXISTS (
        SELECT 1
        FROM public.exercice ex
        JOIN public.membre_espace m
          ON m.espace_id = ex.espace_id
        WHERE ex.id = soumission_exercice.exercice_id
          AND m.utilisateur_id = (SELECT auth.uid())
          AND m.statut = 'ACCEPTE'
    )
);

-- Seul le mentor propriétaire de l'espace relié à l'exercice peut corriger
-- la soumission. La politique restrictive « Compte actif UPDATE » existante
-- continue en parallèle à bloquer les comptes SUSPENDU et SUPPRIME.
CREATE POLICY "Corriger soumission exercice"
ON public.soumission_exercice
FOR UPDATE TO authenticated
USING (
    EXISTS (
        SELECT 1
        FROM public.exercice ex
        JOIN public.espace_mentorat e
          ON e.id = ex.espace_id
        WHERE ex.id = soumission_exercice.exercice_id
          AND e.mentor_id = (SELECT auth.uid())
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1
        FROM public.exercice ex
        JOIN public.espace_mentorat e
          ON e.id = ex.espace_id
        WHERE ex.id = soumission_exercice.exercice_id
          AND e.mentor_id = (SELECT auth.uid())
    )
);
