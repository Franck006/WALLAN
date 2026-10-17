-- =====================================================
-- WALLAN : rendre les suppressions logiques compatibles avec la RLS
-- =====================================================

-- PostgreSQL exige une politique SELECT compatible pour mettre à jour une
-- ligne. Après passage de supprime_le à une date, la politique publique ne
-- voit plus la publication ; cette lecture ciblée permet donc au propriétaire,
-- au modérateur concerné ou à l'administrateur de terminer l'UPDATE.
CREATE POLICY "Gestionnaires consulter publications masquees"
ON public.publication
FOR SELECT TO authenticated
USING (
    supprime_le IS NOT NULL
    AND (SELECT public.is_active_user())
    AND (
        auteur_id = (SELECT auth.uid())
        OR (SELECT public.is_active_admin())
        OR (
            communaute_id IS NOT NULL
            AND EXISTS (
                SELECT 1
                FROM public.adhesion_communaute ac
                WHERE ac.communaute_id = publication.communaute_id
                  AND ac.utilisateur_id = (SELECT auth.uid())
                  AND ac.role = 'MODERATEUR'
            )
        )
    )
);

-- Même principe pour les commentaires masqués. La fonction existante résout
-- l'appartenance communautaire sans exposer le contenu aux autres membres.
CREATE POLICY "Gestionnaires consulter commentaires masques"
ON public.commentaire
FOR SELECT TO authenticated
USING (
    supprime_le IS NOT NULL
    AND (SELECT public.is_active_user())
    AND (
        auteur_id = (SELECT auth.uid())
        OR (SELECT public.is_active_admin())
        OR (SELECT public.can_moderate_community_target(
            'COMMENTAIRE', commentaire.id::TEXT
        ))
    )
);
