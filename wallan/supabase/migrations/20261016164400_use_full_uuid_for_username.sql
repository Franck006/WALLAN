-- =====================================================
-- WALLAN : garantir l'unicité des noms générés à l'inscription
-- =====================================================

-- Le préfixe "dev_" suivi des 32 caractères de l'UUID sans tirets nécessite
-- 36 caractères. Ce changement de type ne modifie aucune valeur existante.
ALTER TABLE public.profiles
ALTER COLUMN username TYPE VARCHAR(36);

-- Utiliser l'UUID complet évite les collisions possibles lorsque deux UUID
-- partagent les 20 premiers caractères précédemment conservés.
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    new_username TEXT;
BEGIN
    new_username := 'dev_' || REPLACE(NEW.id::TEXT, '-', '');

    INSERT INTO public.profiles (id, username, nom_affiche)
    VALUES (NEW.id, new_username, new_username);

    -- Chaque nouvel utilisateur conserve le rôle initial MEMBRE/ACTIF.
    INSERT INTO public.user_roles (user_id, role, statut)
    VALUES (NEW.id, 'MEMBRE', 'ACTIF');

    RETURN NEW;
END;
$$;
