import type { Metadata } from "next";
import { AuthForm } from "@/modules/auth/components/auth-form";

export const metadata: Metadata = {
  title: "Connexion",
  description: "Connectez-vous à votre compte WALLAN.",
};

type LoginPageProps = {
  searchParams: Promise<{ confirmation?: string }>;
};

export default async function LoginPage({ searchParams }: LoginPageProps) {
  const { confirmation } = await searchParams;

  return (
    <AuthForm
      mode="login"
      notice={
        confirmation === "succes"
          ? {
              type: "success",
              message: "Votre adresse email est confirmée. Vous pouvez maintenant vous connecter.",
            }
          : confirmation === "erreur"
            ? {
                type: "error",
                message: "Ce lien de confirmation est invalide ou a expiré. Recommencez l’inscription pour recevoir un nouveau lien.",
              }
          : undefined
      }
    />
  );
}
