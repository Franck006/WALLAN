-- Empêcher les utilisateurs de modifier directement leurs rôles
REVOKE INSERT, UPDATE, DELETE
ON public.user_roles
FROM anon, authenticated;

-- Autoriser uniquement la lecture de son propre rôle
DROP POLICY IF EXISTS "Consulter son rôle"
ON public.user_roles;

CREATE POLICY "Consulter son rôle"
ON public.user_roles
FOR SELECT
TO authenticated
USING ((SELECT auth.uid()) = user_id);