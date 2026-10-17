BEGIN;

CREATE EXTENSION IF NOT EXISTS pgtap WITH SCHEMA extensions;
SELECT extensions.plan(16);

-- Compter les lignes écrites sans imbriquer un CTE DML dans un SELECT.
-- La fonction reste SECURITY INVOKER et respecte le rôle/RLS du test.
CREATE FUNCTION pg_temp.affected_rows(command TEXT)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    affected INTEGER;
BEGIN
    EXECUTE command;
    GET DIAGNOSTICS affected = ROW_COUNT;
    RETURN affected;
END;
$$;

-- Données exclusivement transactionnelles : ROLLBACK les supprime en fin de test.
INSERT INTO auth.users (id, email)
VALUES
    ('20000000-0000-0000-0000-000000000001', 'admin@wallan.test'),
    ('20000000-0000-0000-0000-000000000002', 'moderateur@wallan.test'),
    ('20000000-0000-0000-0000-000000000003', 'membre@wallan.test'),
    ('20000000-0000-0000-0000-000000000004', 'auteur@wallan.test'),
    ('20000000-0000-0000-0000-000000000005', 'suspendu@wallan.test');

UPDATE public.user_roles
SET role = 'ADMIN'
WHERE user_id = '20000000-0000-0000-0000-000000000001';

INSERT INTO public.technologie (nom, slug, categorie)
VALUES ('Test moderation', 'test-moderation', 'AUTRE');

INSERT INTO public.type_opportunite (libelle)
VALUES ('Test administration');

INSERT INTO public.communaute (
    nom, slug, description, categorie, technologie_id, cree_par
)
SELECT 'Communauté A', 'communaute-a-test', 'Première communauté',
       'TECHNOLOGIE', id, '20000000-0000-0000-0000-000000000001'
FROM public.technologie WHERE slug = 'test-moderation';

INSERT INTO public.communaute (
    nom, slug, description, categorie, technologie_id, cree_par
)
SELECT 'Communauté B', 'communaute-b-test', 'Seconde communauté',
       'TECHNOLOGIE', id, '20000000-0000-0000-0000-000000000001'
FROM public.technologie WHERE slug = 'test-moderation';

INSERT INTO public.adhesion_communaute (utilisateur_id, communaute_id, role)
SELECT '20000000-0000-0000-0000-000000000002', id, 'MODERATEUR'
FROM public.communaute WHERE slug = 'communaute-a-test';

INSERT INTO public.adhesion_communaute (utilisateur_id, communaute_id, role)
SELECT '20000000-0000-0000-0000-000000000003', id, 'MEMBRE'
FROM public.communaute WHERE slug = 'communaute-a-test';

INSERT INTO public.publication (auteur_id, communaute_id, contenu)
SELECT '20000000-0000-0000-0000-000000000004', id, 'Publication communauté A'
FROM public.communaute WHERE slug = 'communaute-a-test';

INSERT INTO public.publication (auteur_id, communaute_id, contenu)
SELECT '20000000-0000-0000-0000-000000000004', id, 'Publication communauté B'
FROM public.communaute WHERE slug = 'communaute-b-test';

INSERT INTO public.commentaire (publication_id, auteur_id, contenu)
SELECT id, '20000000-0000-0000-0000-000000000004', 'Commentaire à modérer'
FROM public.publication WHERE contenu = 'Publication communauté A';

INSERT INTO public.signalement (signaleur_id, type_cible, cible_id, motif)
SELECT '20000000-0000-0000-0000-000000000003', 'PUBLICATION', id::TEXT, 'Motif A'
FROM public.publication WHERE contenu = 'Publication communauté A';

INSERT INTO public.signalement (signaleur_id, type_cible, cible_id, motif)
SELECT '20000000-0000-0000-0000-000000000003', 'PUBLICATION', id::TEXT, 'Motif B'
FROM public.publication WHERE contenu = 'Publication communauté B';

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '20000000-0000-0000-0000-000000000002', true);

SELECT extensions.throws_ok(
    $$UPDATE public.commentaire SET contenu = 'Contenu falsifié'
      WHERE contenu = 'Commentaire à modérer'$$,
    'P0001',
    'La modération ne peut pas modifier le contenu original',
    'un modérateur ne peut pas modifier le contenu original'
);

SELECT extensions.is(
    pg_temp.affected_rows(
        $$UPDATE public.publication SET supprime_le = pg_catalog.now()
          WHERE contenu = 'Publication communauté A'$$
    ),
    1,
    'un modérateur peut masquer une publication de sa communauté'
);

SELECT extensions.is(
    pg_temp.affected_rows(
        $$UPDATE public.publication SET supprime_le = pg_catalog.now()
          WHERE contenu = 'Publication communauté B'$$
    ),
    0,
    'un modérateur ne peut pas masquer une publication d une autre communauté'
);

SELECT extensions.is(
    (SELECT count(*)::INTEGER FROM public.signalement WHERE motif = 'Motif A'),
    1,
    'un modérateur consulte les signalements de sa communauté même après masquage'
);

SELECT extensions.is(
    (SELECT count(*)::INTEGER FROM public.signalement WHERE motif = 'Motif B'),
    0,
    'un modérateur ne consulte pas les signalements d une autre communauté'
);

SELECT set_config('request.jwt.claim.sub', '20000000-0000-0000-0000-000000000003', true);

SELECT extensions.is(
    pg_temp.affected_rows(
        $$UPDATE public.signalement SET statut = 'TRAITE' WHERE motif = 'Motif A'$$
    ),
    0,
    'un membre ne peut pas traiter un signalement'
);

SELECT set_config('request.jwt.claim.sub', '20000000-0000-0000-0000-000000000001', true);

SELECT extensions.is(
    pg_temp.affected_rows(
        $$UPDATE public.signalement SET statut = 'TRAITE' WHERE motif = 'Motif B'$$
    ),
    1,
    'un administrateur peut traiter tous les signalements'
);

SELECT extensions.is(
    pg_temp.affected_rows(
        $$UPDATE public.user_roles SET statut = 'SUSPENDU'
          WHERE user_id = '20000000-0000-0000-0000-000000000005'$$
    ),
    1,
    'un administrateur peut suspendre un compte'
);

SELECT set_config('request.jwt.claim.sub', '20000000-0000-0000-0000-000000000005', true);

SELECT extensions.throws_ok(
    $$INSERT INTO public.publication (auteur_id, contenu)
      VALUES ('20000000-0000-0000-0000-000000000005', 'Publication interdite')$$,
    '42501',
    NULL,
    'un utilisateur suspendu ne peut pas publier'
);

SELECT set_config('request.jwt.claim.sub', '20000000-0000-0000-0000-000000000003', true);

SELECT extensions.throws_ok(
    $$UPDATE public.user_roles SET role = 'ADMIN'
      WHERE user_id = '20000000-0000-0000-0000-000000000003'$$,
    '42501',
    NULL,
    'un membre ne peut pas s attribuer le rôle ADMIN'
);

SELECT extensions.throws_ok(
    $$INSERT INTO public.opportunite (
          titre, type_id, description, lien_officiel, source,
          date_derniere_verification, statut_publication, publie_par
      )
      SELECT 'Opportunité membre', id, 'Interdite', 'https://example.test',
             'Test', CURRENT_DATE, 'PUBLIE',
             '20000000-0000-0000-0000-000000000003'
      FROM public.type_opportunite WHERE libelle = 'Test administration'$$,
    '42501',
    NULL,
    'un membre ne peut pas publier une opportunité'
);

SELECT set_config('request.jwt.claim.sub', '20000000-0000-0000-0000-000000000001', true);

SELECT extensions.lives_ok(
    $$INSERT INTO public.opportunite (
          titre, type_id, description, lien_officiel, source,
          date_derniere_verification, statut_publication, publie_par
      )
      SELECT 'Opportunité admin', id, 'Autorisée', 'https://example.test',
             'Test', CURRENT_DATE, 'PUBLIE',
             '20000000-0000-0000-0000-000000000001'
      FROM public.type_opportunite WHERE libelle = 'Test administration'$$,
    'un administrateur peut publier une opportunité'
);

SELECT extensions.is(
    pg_temp.affected_rows(
        $$UPDATE public.adhesion_communaute SET role = 'MODERATEUR'
          WHERE utilisateur_id = '20000000-0000-0000-0000-000000000003'$$
    ),
    1,
    'un administrateur peut désigner un modérateur'
);

SELECT extensions.is(
    (SELECT count(*)::INTEGER FROM public.action_moderation
     WHERE type_action = 'MASQUER_PUBLICATION'),
    1,
    'le masquage est historisé'
);

SELECT extensions.is(
    (SELECT count(*)::INTEGER FROM public.action_moderation
     WHERE type_action = 'CHANGER_STATUT_COMPTE'),
    1,
    'le changement de statut du compte est historisé'
);

SELECT extensions.is(
    (SELECT count(*)::INTEGER FROM public.action_moderation
     WHERE type_action = 'TRAITER_SIGNALEMENT'),
    1,
    'le traitement du signalement est historisé'
);

SELECT * FROM extensions.finish();
ROLLBACK;
