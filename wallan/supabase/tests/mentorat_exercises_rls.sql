BEGIN;

CREATE EXTENSION IF NOT EXISTS pgtap WITH SCHEMA extensions;

SELECT extensions.plan(12);

-- Exécuter les écritures sous le rôle courant et exposer uniquement ROW_COUNT.
-- SECURITY INVOKER (valeur par défaut) conserve intégralement les contrôles RLS.
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

-- Identités locales isolées, créées dans une transaction annulée en fin de test.
INSERT INTO auth.users (id, email)
VALUES
    ('10000000-0000-0000-0000-000000000001', 'mentor1@wallan.test'),
    ('10000000-0000-0000-0000-000000000002', 'mentor2@wallan.test'),
    ('10000000-0000-0000-0000-000000000003', 'membre@wallan.test'),
    ('10000000-0000-0000-0000-000000000004', 'suspendu@wallan.test');

UPDATE public.user_roles
SET statut = 'SUSPENDU'
WHERE user_id = '10000000-0000-0000-0000-000000000004';

INSERT INTO public.offre_mentorat (utilisateur_id, description, disponibilites)
VALUES
    ('10000000-0000-0000-0000-000000000001', 'Mentor 1', 'soir'),
    ('10000000-0000-0000-0000-000000000002', 'Mentor 2', 'soir'),
    ('10000000-0000-0000-0000-000000000004', 'Mentor suspendu', 'soir');

INSERT INTO public.espace_mentorat (mentor_id, nom, description)
VALUES
    ('10000000-0000-0000-0000-000000000001', 'Espace 1', 'Premier espace'),
    ('10000000-0000-0000-0000-000000000002', 'Espace 2', 'Second espace'),
    ('10000000-0000-0000-0000-000000000004', 'Espace suspendu', 'Espace bloqué');

INSERT INTO public.membre_espace (espace_id, utilisateur_id, statut)
SELECT id, '10000000-0000-0000-0000-000000000003', 'ACCEPTE'
FROM public.espace_mentorat
WHERE nom = 'Espace 1';

INSERT INTO public.exercice (espace_id, titre, description)
SELECT id, 'Exercice initial', 'Description initiale'
FROM public.espace_mentorat
WHERE nom = 'Espace 1';

INSERT INTO public.exercice (espace_id, titre, description)
SELECT id, 'Exercice suspendu', 'Description initiale'
FROM public.espace_mentorat
WHERE nom = 'Espace suspendu';

INSERT INTO public.soumission_exercice (exercice_id, utilisateur_id, commentaire)
SELECT id, '10000000-0000-0000-0000-000000000003', 'Mon travail'
FROM public.exercice
WHERE titre = 'Exercice initial';

SET LOCAL ROLE authenticated;

SELECT set_config('request.jwt.claim.sub', '10000000-0000-0000-0000-000000000001', true);

SELECT extensions.lives_ok(
    $$UPDATE public.exercice SET titre = 'Exercice modifié' WHERE titre = 'Exercice initial'$$,
    'le mentor peut modifier son exercice'
);

SELECT extensions.is(
    (SELECT titre::text FROM public.exercice WHERE titre = 'Exercice modifié'),
    'Exercice modifié',
    'la modification de l exercice est persistée'
);

SELECT extensions.lives_ok(
    $$UPDATE public.soumission_exercice
      SET retour_mentor = 'Bonne solution', appreciation = 'BON_TRAVAIL'
      WHERE commentaire = 'Mon travail'$$,
    'le mentor peut corriger une soumission de son espace'
);

SELECT extensions.is(
    (SELECT appreciation::text FROM public.soumission_exercice WHERE commentaire = 'Mon travail'),
    'BON_TRAVAIL',
    'l appréciation qualitative est enregistrée'
);

SELECT set_config('request.jwt.claim.sub', '10000000-0000-0000-0000-000000000002', true);

SELECT extensions.is(
    pg_temp.affected_rows(
        $$UPDATE public.exercice SET titre = 'Intrusion' WHERE titre = 'Exercice modifié'$$
    ),
    0,
    'un autre mentor ne peut pas modifier l exercice'
);

SELECT extensions.is(
    pg_temp.affected_rows(
        $$UPDATE public.soumission_exercice SET retour_mentor = 'Intrusion' WHERE commentaire = 'Mon travail'$$
    ),
    0,
    'un mentor ne peut pas corriger une soumission d un autre espace'
);

SELECT set_config('request.jwt.claim.sub', '10000000-0000-0000-0000-000000000003', true);

SELECT extensions.is(
    (SELECT retour_mentor FROM public.soumission_exercice WHERE commentaire = 'Mon travail'),
    'Bonne solution',
    'le mentoré peut consulter le retour'
);

SELECT extensions.is(
    pg_temp.affected_rows(
        $$UPDATE public.soumission_exercice SET appreciation = 'EXCELLENT' WHERE commentaire = 'Mon travail'$$
    ),
    0,
    'le mentoré ne peut pas falsifier son appréciation'
);

SELECT extensions.throws_ok(
    $$INSERT INTO public.soumission_exercice (exercice_id, utilisateur_id, commentaire, appreciation)
      SELECT id, '10000000-0000-0000-0000-000000000003', 'Fausse correction', 'EXCELLENT'
      FROM public.exercice WHERE titre = 'Exercice modifié'$$,
    '42501',
    NULL,
    'le mentoré ne peut pas fournir une appréciation à la création'
);

SELECT set_config('request.jwt.claim.sub', '10000000-0000-0000-0000-000000000004', true);

SELECT extensions.is(
    pg_temp.affected_rows(
        $$UPDATE public.exercice SET titre = 'Modification suspendue' WHERE titre = 'Exercice suspendu'$$
    ),
    0,
    'un utilisateur suspendu ne peut pas modifier un exercice'
);

SELECT set_config('request.jwt.claim.sub', '10000000-0000-0000-0000-000000000001', true);

SELECT extensions.throws_ok(
    $$UPDATE public.exercice SET espace_id = espace_id + 1 WHERE titre = 'Exercice modifié'$$,
    'P0001',
    'Modification non autorisée des champs protégés de l’exercice',
    'la relation de l exercice est immuable'
);

SELECT extensions.throws_ok(
    $$UPDATE public.soumission_exercice SET commentaire = 'Réécrit' WHERE commentaire = 'Mon travail'$$,
    'P0001',
    'Seuls le retour et l’appréciation du mentor peuvent être modifiés',
    'le mentor ne peut pas réécrire le travail soumis'
);

SELECT * FROM extensions.finish();

ROLLBACK;
