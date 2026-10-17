"use server";

import { redirect } from "next/navigation";
import { validateLoginCredentials, validateSignupCredentials } from "@/modules/auth/schemas/auth-credentials";
import { authenticateUser } from "@/modules/auth/services/authenticate-user";
import { registerUser } from "@/modules/auth/services/register-user";
import type { AuthActionState } from "@/modules/auth/types/auth-action-state";

export async function loginAction(
  _previousState: AuthActionState,
  formData: FormData,
): Promise<AuthActionState> {
  const validation = validateLoginCredentials(formData);
  const email = String(formData.get("email") ?? "").trim();

  if (!validation.success) {
    return { status: "error", errors: validation.errors, values: { email } };
  }

  const result = await authenticateUser(validation.data);

  if (!result.success) {
    return { status: "error", message: result.message, values: { email } };
  }

  redirect("/");
}

export async function signupAction(
  _previousState: AuthActionState,
  formData: FormData,
): Promise<AuthActionState> {
  const validation = validateSignupCredentials(formData);
  const email = String(formData.get("email") ?? "").trim();

  if (!validation.success) {
    return { status: "error", errors: validation.errors, values: { email } };
  }

  const result = await registerUser(validation.data);

  if (!result.success) {
    return { status: "error", message: result.message, values: { email } };
  }

  if (result.confirmationRequired) {
    return {
      status: "confirmation-required",
      message: "Compte créé. Consultez votre boîte email pour confirmer votre inscription.",
      values: { email },
    };
  }

  redirect("/");
}
