BEGIN;

CREATE EXTENSION IF NOT EXISTS pgtap WITH SCHEMA extensions;
SELECT extensions.plan(13);

-- Compter les lignes écrites sous le rôle courant sans CTE DML imbriqué.
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

-- Les données de test restent transactionnelles et sont annulées à la fin.
INSERT INTO auth.users (id, email)
VALUES
    ('30000000-0000-0000-0000-000000000001', 'admin-fix@wallan.test'),
    ('30000000-0000-0000-0000-000000000002', 'membre-fix@wallan.test'),
    ('30000000-0000-0000-0000-000000000003', 'auteur-fix@wallan.test'),
    ('30000000-0000-0000-0000-000000000004', 'suspendu-fix@wallan.test');

UPDATE public.user_roles
SET role = 'ADMIN'
WHERE user_id = '30000000-0000-0000-0000-000000000001';

INSERT INTO public.type_opportunite (libelle)
VALUES ('Type correctifs prioritaires');

INSERT INTO public.publication (auteur_id, contenu)
VALUES ('30000000-0000-0000-0000-000000000003', 'Publication test correctifs');

INSERT INTO public.commentaire (publication_id, auteur_id, contenu)
SELECT id, '30000000-0000-0000-0000-000000000002', 'Commentaire enfant'
FROM public.publication WHERE contenu = 'Publication test correctifs';

INSERT INTO public.reaction (publication_id, utilisateur_id, type)
SELECT id, '30000000-0000-0000-0000-000000000002', 'UTILE'
FROM public.publication WHERE contenu = 'Publication test correctifs';

INSERT INTO public.signalement (signaleur_id, type_cible, cible_id, motif)
SELECT '30000000-0000-0000-0000-000000000002', 'PUBLICATION', id::TEXT, 'Premier signalement'
FROM public.publication WHERE contenu = 'Publication test correctifs';

INSERT INTO public.offre_mentorat (utilisateur_id, description, disponibilites)
VALUES ('30000000-0000-0000-0000-000000000001', 'Mentor test', 'soir');

INSERT INTO public.espace_mentorat (mentor_id, nom, description)
VALUES (
    '30000000-0000-0000-0000-000000000001',
    'Espace contraintes', 'Espace de test'
);

INSERT INTO public.membre_espace (espace_id, utilisateur_id, statut)
SELECT id, '30000000-0000-0000-0000-000000000002', 'ACCEPTE'
FROM public.espace_mentorat WHERE nom = 'Espace contraintes';

INSERT INTO public.exercice (espace_id, titre, description)
SELECT id, 'Exercice valide', 'Description valide'
FROM public.espace_mentorat WHERE nom = 'Espace contraintes';

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '30000000-0000-0000-0000-000000000001', true);

SELECT extensions.is(
    (SELECT count(*)::INTEGER FROM public.user_roles),
    4,
    'un administrateur actif peut consulter les comptes'
);

SELECT extensions.is(
    pg_temp.affected_rows(
        $$UPDATE public.user_roles SET statut = 'SUSPENDU'
          WHERE user_id = '30000000-0000-0000-0000-000000000004'$$
    ),
    1,
    'un administrateur peut suspendre un autre compte'
);

SELECT extensions.is(
    pg_temp.affected_rows(
        $$UPDATE public.user_roles SET statut = 'ACTIF'
          WHERE user_id = '30000000-0000-0000-0000-000000000004'$$
    ),
    1,
    'un administrateur peut réactiver un compte suspendu'
);

SELECT set_config('request.jwt.claim.sub', '30000000-0000-0000-0000-000000000002', true);

SELECT extensions.throws_ok(
    $$UPDATE public.user_roles SET role = 'ADMIN'
      WHERE user_id = '30000000-0000-0000-0000-000000000002'$$,
    '42501', NULL,
    'un membre ne peut toujours pas modifier son rôle global'
);

SELECT extensions.throws_ok(
    $$INSERT INTO public.signalement (signaleur_id, type_cible, cible_id, motif)
      VALUES (
        '30000000-0000-0000-0000-000000000002',
        'PUBLICATION', '999999999999', 'Cible inexistante'
      )$$,
    'P0001', 'La cible du signalement n’existe pas',
    'un signalement ne peut pas viser une publication inexistante'
);

SELECT extensions.throws_ok(
    $$INSERT INTO public.signalement (signaleur_id, type_cible, cible_id, motif)
      SELECT '30000000-0000-0000-0000-000000000002',
             'PUBLICATION', id::TEXT, 'Doublon'
      FROM public.publication WHERE contenu = 'Publication test correctifs'$$,
    '23505', NULL,
    'un signalement ouvert identique ne peut pas être créé deux fois'
);

SELECT set_config('request.jwt.claim.sub', '30000000-0000-0000-0000-000000000003', true);

SELECT extensions.lives_ok(
    $$UPDATE public.publication SET supprime_le = pg_catalog.now()
      WHERE contenu = 'Publication test correctifs'$$,
    'l auteur peut masquer sa publication'
);

SELECT set_config('request.jwt.claim.sub', '30000000-0000-0000-0000-000000000002', true);

SELECT extensions.is(
    (SELECT count(*)::INTEGER FROM public.commentaire WHERE contenu = 'Commentaire enfant'),
    0,
    'les commentaires d une publication masquée ne sont plus lisibles'
);

SELECT extensions.is(
    (SELECT count(*)::INTEGER FROM public.reaction WHERE type = 'UTILE'),
    0,
    'les réactions d une publication masquée ne sont plus lisibles'
);

SELECT set_config('request.jwt.claim.sub', '30000000-0000-0000-0000-000000000001', true);

SELECT extensions.throws_ok(
    $$INSERT INTO public.exercice (espace_id, titre, description)
      SELECT id, '   ', 'Description'
      FROM public.espace_mentorat WHERE nom = 'Espace contraintes'$$,
    '23514', NULL,
    'un exercice ne peut pas avoir un titre vide'
);

SELECT set_config('request.jwt.claim.sub', '30000000-0000-0000-0000-000000000002', true);

SELECT extensions.throws_ok(
    $$INSERT INTO public.soumission_exercice (
          exercice_id, utilisateur_id, url_depot, commentaire
      )
      SELECT id, '30000000-0000-0000-0000-000000000002', '  ', ' '
      FROM public.exercice WHERE titre = 'Exercice valide'$$,
    '23514', NULL,
    'une soumission ne peut pas contenir uniquement des espaces'
);

SELECT set_config('request.jwt.claim.sub', '30000000-0000-0000-0000-000000000001', true);

SELECT extensions.throws_ok(
    $$INSERT INTO public.opportunite (
          titre, type_id, description, lien_officiel, source,
          date_derniere_verification, date_debut, date_fin,
          statut_publication, publie_par
      )
      SELECT 'Dates invalides', id, 'Test', 'https://example.test',
             'Test', CURRENT_DATE, DATE '2027-02-01', DATE '2027-01-01',
             'BROUILLON', '30000000-0000-0000-0000-000000000001'
      FROM public.type_opportunite
      WHERE libelle = 'Type correctifs prioritaires'$$,
    '23514', NULL,
    'la date de début d une opportunité ne peut pas dépasser sa date de fin'
);

SELECT set_config('request.jwt.claim.sub', '30000000-0000-0000-0000-000000000004', true);

-- Le compte a été réactivé plus haut : on le suspend hors rôle client pour
-- vérifier que la politique restrictive existante continue de s'appliquer.
RESET ROLE;
UPDATE public.user_roles
SET statut = 'SUSPENDU'
WHERE user_id = '30000000-0000-0000-0000-000000000004';
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '30000000-0000-0000-0000-000000000004', true);

SELECT extensions.throws_ok(
    $$INSERT INTO public.publication (auteur_id, contenu)
      VALUES ('30000000-0000-0000-0000-000000000004', 'Interdite')$$,
    '42501', NULL,
    'un compte suspendu reste incapable de publier'
);

SELECT * FROM extensions.finish();
ROLLBACK;
