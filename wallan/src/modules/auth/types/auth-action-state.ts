export type AuthField = "email" | "password" | "passwordConfirmation";

export type AuthActionState = {
  status: "idle" | "error" | "confirmation-required";
  message?: string;
  errors?: Partial<Record<AuthField, string>>;
  values?: {
    email?: string;
  };
};

export const INITIAL_AUTH_STATE: AuthActionState = {
  status: "idle",
};
