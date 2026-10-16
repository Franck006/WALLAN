import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";

export async function GET() {
  try {
    const supabase = await createClient();

    const { data, error } = await supabase
      .from("wallan_health_check")
      .select("id, message")
      .limit(1)
      .single();

    if (error) {
      return NextResponse.json(
        { status: "error", message: error.message },
        { status: 503 }
      );
    }

    return NextResponse.json({
      status: "success",
      database: "PostgreSQL",
      data,
    });
  } catch {
    return NextResponse.json(
      { status: "error", message: "Connexion impossible" },
      { status: 503 }
    );
  }
}