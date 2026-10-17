import type { AuthActionState } from "@/modules/auth/types/auth-action-state";

const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const MINIMUM_PASSWORD_LENGTH = 8;

type ValidationResult =
  | { success: true; data: { email: string; password: string } }
  | { success: false; errors: NonNullable<AuthActionState["errors"]> };

export function validateLoginCredentials(formData: FormData): ValidationResult {
  return validateCredentials(formData, false);
}

export function validateSignupCredentials(formData: FormData): ValidationResult {
  return validateCredentials(formData, true);
}

function validateCredentials(formData: FormData, confirmsPassword: boolean): ValidationResult {
  const email = String(formData.get("email") ?? "").trim().toLowerCase();
  const password = String(formData.get("password") ?? "");
  const passwordConfirmation = String(formData.get("passwordConfirmation") ?? "");
  const errors: NonNullable<AuthActionState["errors"]> = {};

  if (!email) {
    errors.email = "L’adresse email est requise.";
  } else if (!EMAIL_PATTERN.test(email)) {
    errors.email = "Saisissez une adresse email valide.";
  }

  if (!password) {
    errors.password = "Le mot de passe est requis.";
  } else if (password.length < MINIMUM_PASSWORD_LENGTH) {
    errors.password = `Utilisez au moins ${MINIMUM_PASSWORD_LENGTH} caractères.`;
  }

  if (confirmsPassword && password !== passwordConfirmation) {
    errors.passwordConfirmation = "Les mots de passe ne correspondent pas.";
  }

  if (Object.keys(errors).length > 0) {
    return { success: false, errors };
  }

  return { success: true, data: { email, password } };
}
