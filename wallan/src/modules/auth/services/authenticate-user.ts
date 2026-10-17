import { signInWithPassword } from "@/modules/auth/repositories/auth-repository";

type Credentials = {
  email: string;
  password: string;
};

export async function authenticateUser(credentials: Credentials) {
  try {
    const { error } = await signInWithPassword(credentials);

    if (error) {
      return {
        success: false as const,
        message: "Email ou mot de passe incorrect.",
      };
    }

    return { success: true as const };
  } catch {
    return {
      success: false as const,
      message: "Connexion momentanément indisponible. Réessayez dans quelques instants.",
    };
  }
}
