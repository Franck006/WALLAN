-- Créer automatiquement le profil et le rôle d'un nouvel utilisateur
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    new_username TEXT;
BEGIN
    -- Générer un identifiant unique à partir de l'UUID
    new_username := 'dev_' || LEFT(REPLACE(NEW.id::TEXT, '-', ''), 20);

    INSERT INTO public.profiles (id, username, nom_affiche)
    VALUES (NEW.id, new_username, new_username);

    -- Chaque nouvel utilisateur possède le rôle MEMBRE
    INSERT INTO public.user_roles (user_id, role, statut)
    VALUES (NEW.id, 'MEMBRE', 'ACTIF');

    RETURN NEW;
END;
$$;

-- Déclencher la création après chaque inscription
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW
EXECUTE FUNCTION public.handle_new_user();