import { signUpWithPassword } from "@/modules/auth/repositories/auth-repository";

type Credentials = {
  email: string;
  password: string;
};

export async function registerUser(credentials: Credentials) {
  try {
    const { data, error } = await signUpWithPassword(credentials);

    if (error) {
      return {
        success: false as const,
        message: "Impossible de créer le compte. Vérifiez vos informations puis réessayez.",
      };
    }

    return {
      success: true as const,
      confirmationRequired: !data.session,
    };
  } catch {
    return {
      success: false as const,
      message: "Inscription momentanément indisponible. Réessayez dans quelques instants.",
    };
  }
}
