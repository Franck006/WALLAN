import type { Metadata } from "next";
import { AuthForm } from "@/modules/auth/components/auth-form";

export const metadata: Metadata = {
  title: "Inscription",
  description: "Créez votre compte WALLAN.",
};

export default function SignupPage() {
  return <AuthForm mode="signup" />;
}
