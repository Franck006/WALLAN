-- =====================================================
-- WALLAN : bloquer les écritures des comptes non actifs
-- =====================================================

-- Centraliser la vérification évite de dupliquer la lecture de user_roles.
-- SECURITY DEFINER est nécessaire pour que la vérification reste fiable
-- indépendamment des politiques RLS appliquées à user_roles.
CREATE OR REPLACE FUNCTION public.is_active_user()
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
          AND ur.statut = 'ACTIF'
    );
$$;

-- Ne pas exposer cette fonction de sécurité à tous les rôles par défaut.
REVOKE ALL ON FUNCTION public.is_active_user() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.is_active_user() TO authenticated;

-- Chaque politique restrictive est combinée avec les politiques métier
-- existantes. Elle ne crée donc aucun nouveau droit. Trois politiques séparées
-- permettent de bloquer uniquement les écritures, sans modifier les lectures.
DO $$
DECLARE
    table_cible REGCLASS;
BEGIN
    FOREACH table_cible IN ARRAY ARRAY[
        'public.profiles'::REGCLASS,
        'public.profil_technologie'::REGCLASS,
        'public.profil_centre_interet'::REGCLASS,
        'public.lien_profil'::REGCLASS,
        'public.projet'::REGCLASS,
        'public.projet_technologie'::REGCLASS,
        'public.disponibilite'::REGCLASS,
        'public.communaute'::REGCLASS,
        'public.adhesion_communaute'::REGCLASS,
        'public.publication'::REGCLASS,
        'public.commentaire'::REGCLASS,
        'public.reaction'::REGCLASS,
        'public.question'::REGCLASS,
        'public.question_technologie'::REGCLASS,
        'public.question_tag'::REGCLASS,
        'public.reponse'::REGCLASS,
        'public.offre_mentorat'::REGCLASS,
        'public.offre_mentorat_domaine'::REGCLASS,
        'public.espace_mentorat'::REGCLASS,
        'public.membre_espace'::REGCLASS,
        'public.exercice'::REGCLASS,
        'public.soumission_exercice'::REGCLASS,
        'public.message_mentorat'::REGCLASS,
        'public.projet_collaboratif'::REGCLASS,
        'public.membre_projet'::REGCLASS,
        'public.revue_code'::REGCLASS,
        'public.commentaire_revue'::REGCLASS,
        'public.signalement'::REGCLASS,
        'public.notification'::REGCLASS
    ]
    LOOP
        EXECUTE pg_catalog.format(
            'CREATE POLICY "Compte actif INSERT" ON %s AS RESTRICTIVE '
            'FOR INSERT TO authenticated '
            'WITH CHECK ((SELECT public.is_active_user()))',
            table_cible
        );

        EXECUTE pg_catalog.format(
            'CREATE POLICY "Compte actif UPDATE" ON %s AS RESTRICTIVE '
            'FOR UPDATE TO authenticated '
            'USING ((SELECT public.is_active_user())) '
            'WITH CHECK ((SELECT public.is_active_user()))',
            table_cible
        );

        EXECUTE pg_catalog.format(
            'CREATE POLICY "Compte actif DELETE" ON %s AS RESTRICTIVE '
            'FOR DELETE TO authenticated '
            'USING ((SELECT public.is_active_user()))',
            table_cible
        );
    END LOOP;
END;
$$;
