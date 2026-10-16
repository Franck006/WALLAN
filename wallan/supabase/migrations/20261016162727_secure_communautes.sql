-- Autoriser uniquement les administrateurs à créer des communautés
CREATE POLICY "Admin creer communaute"
ON public.communaute
FOR INSERT TO authenticated
WITH CHECK (
    cree_par = (SELECT auth.uid())
    AND EXISTS (
        SELECT 1
        FROM public.user_roles ur
        WHERE ur.user_id = (SELECT auth.uid())
          AND ur.role = 'ADMIN'
          AND ur.statut = 'ACTIF'
    )
);

-- Autoriser les administrateurs à modifier les communautés
CREATE POLICY "Admin modifier communaute"
ON public.communaute
FOR UPDATE TO authenticated
USING (
    EXISTS (
        SELECT 1
        FROM public.user_roles ur
        WHERE ur.user_id = (SELECT auth.uid())
          AND ur.role = 'ADMIN'
          AND ur.statut = 'ACTIF'
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1
        FROM public.user_roles ur
        WHERE ur.user_id = (SELECT auth.uid())
          AND ur.role = 'ADMIN'
          AND ur.statut = 'ACTIF'
    )
);

-- Autoriser les administrateurs à consulter les adhésions
-- La lecture publique existe déjà dans create_communautes.sql.

-- Autoriser les administrateurs à modifier les rôles communautaires
CREATE POLICY "Admin gerer roles communautaires"
ON public.adhesion_communaute
FOR UPDATE TO authenticated
USING (
    EXISTS (
        SELECT 1
        FROM public.user_roles ur
        WHERE ur.user_id = (SELECT auth.uid())
          AND ur.role = 'ADMIN'
          AND ur.statut = 'ACTIF'
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1
        FROM public.user_roles ur
        WHERE ur.user_id = (SELECT auth.uid())
          AND ur.role = 'ADMIN'
          AND ur.statut = 'ACTIF'
    )
);