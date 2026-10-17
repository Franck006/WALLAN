import { createClient } from "@/lib/supabase/server";

type Credentials = {
  email: string;
  password: string;
};

export async function signInWithPassword(credentials: Credentials) {
  const supabase = await createClient();
  return supabase.auth.signInWithPassword(credentials);
}

export async function signUpWithPassword(credentials: Credentials) {
  const supabase = await createClient();
  return supabase.auth.signUp(credentials);
}
