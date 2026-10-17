"use client";

import Link from "next/link";
import { useActionState } from "react";
import { useFormStatus } from "react-dom";
import { Button } from "@/components/ui/button";
import { TextField } from "@/components/ui/text-field";
import { loginAction, signupAction } from "@/modules/auth/actions";
import { INITIAL_AUTH_STATE } from "@/modules/auth/types/auth-action-state";

type AuthFormProps = {
  mode: "login" | "signup";
  notice?: {
    message: string;
    type: "success" | "error";
  };
};

export function AuthForm({ mode, notice }: AuthFormProps) {
  const isLogin = mode === "login";
  const action = isLogin ? loginAction : signupAction;
  const [state, formAction] = useActionState(action, INITIAL_AUTH_STATE);

  return (
    <div className="w-full max-w-md">
      <Link
        href="/"
        className="mb-8 inline-flex min-h-11 items-center rounded-lg font-heading text-2xl font-extrabold tracking-tight text-forest-500 focus-visible:outline-none focus-visible:ring-3 focus-visible:ring-forest-400 focus-visible:ring-offset-2 lg:hidden"
      >
        WALLAN<span className="text-solar-500">.</span>
      </Link>

      <h1 className="font-heading text-3xl font-bold leading-tight text-anthracite-700 md:text-4xl">
        {isLogin ? "Connexion" : "Créer votre compte"}
      </h1>
      <p className="mt-2 text-base leading-relaxed text-anthracite-700/60">
        {isLogin ? "Retrouvez votre communauté WALLAN." : "Rejoignez WALLAN en quelques secondes."}
      </p>

      {notice ? (
        <div
          className={`mt-6 rounded-xl border p-4 text-sm leading-relaxed ${
            notice.type === "success"
              ? "border-green-700/20 bg-green-50 text-green-800"
              : "border-red-700/20 bg-red-50 text-red-800"
          }`}
          role={notice.type === "error" ? "alert" : "status"}
        >
          {notice.message}
        </div>
      ) : null}

      {state.message ? (
        <div
          className={`mt-6 rounded-xl border p-4 text-sm leading-relaxed ${
            state.status === "confirmation-required"
              ? "border-green-700/20 bg-green-50 text-green-800"
              : "border-red-700/20 bg-red-50 text-red-800"
          }`}
          role={state.status === "error" ? "alert" : "status"}
        >
          {state.message}
        </div>
      ) : null}

      <form action={formAction} className="mt-8 space-y-5" noValidate>
        <TextField
          id={`${mode}-email`}
          name="email"
          type="email"
          label="Adresse email"
          placeholder="vous@exemple.com"
          autoComplete="email"
          inputMode="email"
          required
          defaultValue={state.values?.email}
          error={state.errors?.email}
        />
        <TextField
          id={`${mode}-password`}
          name="password"
          type="password"
          label="Mot de passe"
          placeholder="8 caractères minimum"
          autoComplete={isLogin ? "current-password" : "new-password"}
          required
          minLength={8}
          error={state.errors?.password}
          hint={isLogin ? undefined : "Utilisez au moins 8 caractères."}
        />
        {!isLogin ? (
          <TextField
            id="signup-password-confirmation"
            name="passwordConfirmation"
            type="password"
            label="Confirmer le mot de passe"
            placeholder="Saisissez à nouveau votre mot de passe"
            autoComplete="new-password"
            required
            minLength={8}
            error={state.errors?.passwordConfirmation}
          />
        ) : null}

        <SubmitButton mode={mode} />
      </form>

      <p className="mt-6 text-center text-sm text-anthracite-700/60">
        {isLogin ? "Pas encore de compte ? " : "Déjà inscrit ? "}
        <Link
          href={isLogin ? "/inscription" : "/connexion"}
          className="inline-flex min-h-11 items-center font-semibold text-forest-500 underline-offset-4 hover:underline focus-visible:rounded focus-visible:outline-none focus-visible:ring-3 focus-visible:ring-forest-400 focus-visible:ring-offset-2"
        >
          {isLogin ? "Inscrivez-vous" : "Connectez-vous"}
        </Link>
      </p>
    </div>
  );
}

function SubmitButton({ mode }: { mode: "login" | "signup" }) {
  const { pending } = useFormStatus();
  const isLogin = mode === "login";

  return (
    <Button
      type="submit"
      className="w-full"
      loading={pending}
      loadingLabel={isLogin ? "Connexion…" : "Création du compte…"}
    >
      {isLogin ? "Se connecter" : "Créer mon compte"}
      <span aria-hidden="true">→</span>
    </Button>
  );
}
