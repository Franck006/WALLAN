-- =====================================================
-- WALLAN : Sécurisation des publications
-- =====================================================

-- Supprimer les anciennes politiques à renforcer
DROP POLICY IF EXISTS "Creer publication"
ON public.publication;

DROP POLICY IF EXISTS "Modifier publication"
ON public.publication;

DROP POLICY IF EXISTS "Ajouter commentaire"
ON public.commentaire;

DROP POLICY IF EXISTS "Modifier commentaire"
ON public.commentaire;

DROP POLICY IF EXISTS "Ajouter reaction"
ON public.reaction;

DROP POLICY IF EXISTS "Modifier reaction"
ON public.reaction;

-- Un utilisateur peut publier dans le fil général
-- ou dans une communauté active dont il est membre.
CREATE POLICY "Creer publication"
ON public.publication
FOR INSERT TO authenticated
WITH CHECK (
    auteur_id = (SELECT auth.uid())
    AND supprime_le IS NULL
    AND (
        communaute_id IS NULL
        OR EXISTS (
            SELECT 1
            FROM public.communaute c
            JOIN public.adhesion_communaute ac
                ON ac.communaute_id = c.id
            WHERE c.id = publication.communaute_id
              AND c.active = TRUE
              AND ac.utilisateur_id = (SELECT auth.uid())
        )
    )
);

-- Seul l'auteur peut modifier une publication existante.
CREATE POLICY "Modifier publication"
ON public.publication
FOR UPDATE TO authenticated
USING (
    auteur_id = (SELECT auth.uid())
    AND supprime_le IS NULL
)
WITH CHECK (
    auteur_id = (SELECT auth.uid())
);

-- Commenter uniquement une publication visible
-- et appartenir à sa communauté si nécessaire.
CREATE POLICY "Ajouter commentaire"
ON public.commentaire
FOR INSERT TO authenticated
WITH CHECK (
    auteur_id = (SELECT auth.uid())
    AND supprime_le IS NULL
    AND EXISTS (
        SELECT 1
        FROM public.publication p
        WHERE p.id = publication_id
          AND p.supprime_le IS NULL
          AND (
              p.communaute_id IS NULL
              OR EXISTS (
                  SELECT 1
                  FROM public.communaute c
                  JOIN public.adhesion_communaute ac
                      ON ac.communaute_id = c.id
                  WHERE c.id = p.communaute_id
                    AND c.active = TRUE
                    AND ac.utilisateur_id = (SELECT auth.uid())
              )
          )
    )
);

-- L'auteur peut modifier son commentaire non supprimé.
CREATE POLICY "Modifier commentaire"
ON public.commentaire
FOR UPDATE TO authenticated
USING (
    auteur_id = (SELECT auth.uid())
    AND supprime_le IS NULL
)
WITH CHECK (
    auteur_id = (SELECT auth.uid())
);

-- Réagir uniquement aux publications visibles.
CREATE POLICY "Ajouter reaction"
ON public.reaction
FOR INSERT TO authenticated
WITH CHECK (
    utilisateur_id = (SELECT auth.uid())
    AND EXISTS (
        SELECT 1
        FROM public.publication p
        WHERE p.id = publication_id
          AND p.supprime_le IS NULL
          AND (
              p.communaute_id IS NULL
              OR EXISTS (
                  SELECT 1
                  FROM public.communaute c
                  JOIN public.adhesion_communaute ac
                      ON ac.communaute_id = c.id
                  WHERE c.id = p.communaute_id
                    AND c.active = TRUE
                    AND ac.utilisateur_id = (SELECT auth.uid())
              )
          )
    )
);

-- Modifier uniquement sa propre réaction.
CREATE POLICY "Modifier reaction"
ON public.reaction
FOR UPDATE TO authenticated
USING (
    utilisateur_id = (SELECT auth.uid())
    AND EXISTS (
        SELECT 1
        FROM public.publication p
        WHERE p.id = publication_id
          AND p.supprime_le IS NULL
    )
)
WITH CHECK (
    utilisateur_id = (SELECT auth.uid())
    AND EXISTS (
        SELECT 1
        FROM public.publication p
        WHERE p.id = publication_id
          AND p.supprime_le IS NULL
          AND (
              p.communaute_id IS NULL
              OR EXISTS (
                  SELECT 1
                  FROM public.communaute c
                  JOIN public.adhesion_communaute ac
                      ON ac.communaute_id = c.id
                  WHERE c.id = p.communaute_id
                    AND c.active = TRUE
                    AND ac.utilisateur_id = (SELECT auth.uid())
              )
          )
    )
);

-- =====================================================
-- Protection des champs sensibles
-- =====================================================

-- Protection des publications
CREATE OR REPLACE FUNCTION public.protect_publication_fields()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
    -- Interdire le changement d'auteur, de communauté
    -- et de date de création.
    IF NEW.auteur_id IS DISTINCT FROM OLD.auteur_id
       OR NEW.communaute_id IS DISTINCT FROM OLD.communaute_id
       OR NEW.date_creation IS DISTINCT FROM OLD.date_creation
    THEN
        RAISE EXCEPTION 'Modification non autorisée des champs protégés';
    END IF;

    -- Empêcher la restauration d'une publication supprimée.
    IF OLD.supprime_le IS NOT NULL THEN
        RAISE EXCEPTION 'Publication déjà supprimée';
    END IF;

    -- Définir la date réelle de suppression.
    IF NEW.supprime_le IS NOT NULL THEN
        NEW.supprime_le := NOW();
    END IF;

    NEW.date_maj := NOW();

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_protect_publication_fields
BEFORE UPDATE ON public.publication
FOR EACH ROW
EXECUTE FUNCTION public.protect_publication_fields();


-- Protection des commentaires
CREATE OR REPLACE FUNCTION public.protect_commentaire_fields()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
    IF NEW.auteur_id IS DISTINCT FROM OLD.auteur_id
       OR NEW.publication_id IS DISTINCT FROM OLD.publication_id
       OR NEW.date_creation IS DISTINCT FROM OLD.date_creation
    THEN
        RAISE EXCEPTION 'Modification non autorisée des champs protégés';
    END IF;

    IF OLD.supprime_le IS NOT NULL THEN
        RAISE EXCEPTION 'Commentaire déjà supprimé';
    END IF;

    IF NEW.supprime_le IS NOT NULL THEN
        NEW.supprime_le := NOW();
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_protect_commentaire_fields
BEFORE UPDATE ON public.commentaire
FOR EACH ROW
EXECUTE FUNCTION public.protect_commentaire_fields();


-- Protection des réactions
CREATE OR REPLACE FUNCTION public.protect_reaction_fields()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
    IF NEW.utilisateur_id IS DISTINCT FROM OLD.utilisateur_id
       OR NEW.publication_id IS DISTINCT FROM OLD.publication_id
       OR NEW.date_creation IS DISTINCT FROM OLD.date_creation
    THEN
        RAISE EXCEPTION 'Modification non autorisée des champs protégés';
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_protect_reaction_fields
BEFORE UPDATE ON public.reaction
FOR EACH ROW
EXECUTE FUNCTION public.protect_reaction_fields();