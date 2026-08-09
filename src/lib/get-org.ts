import { cache } from "react";
import { createServiceClient } from "@/lib/supabase/server";

/**
 * Gets the org ID for a given user.
 * Wrapped in React cache() so multiple calls with the same userId
 * within a single server render share the same DB query result.
 */
export const getOrgId = cache(async (userId: string): Promise<string | null> => {
  const supabase = createServiceClient();

  // Parallel: ownership + membership at the same time
  const [ownedResult, memberResult] = await Promise.all([
    supabase
      .from("organizations")
      .select("id")
      .eq("owner_id", userId)
      .order("created_at", { ascending: true })
      .limit(1)
      .maybeSingle(),
    supabase
      .from("team_members")
      .select("org_id")
      .eq("user_id", userId)
      .not("accepted_at", "is", null)
      .maybeSingle(),
  ]);

  if (ownedResult.data?.id) return ownedResult.data.id;
  return memberResult.data?.org_id ?? null;
});
