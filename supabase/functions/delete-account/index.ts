const jsonHeaders = {
  "Content-Type": "application/json",
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "DELETE, OPTIONS",
};

function jsonResponse(body: Record<string, unknown>, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: jsonHeaders,
  });
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: jsonHeaders });
  }

  if (req.method !== "DELETE") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return jsonResponse({ error: "Unauthorized" }, 401);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

  if (!supabaseUrl || !anonKey || !serviceRoleKey) {
    console.error("[delete-account] Missing required server configuration");
    return jsonResponse({ error: "Failed to delete account" }, 500);
  }

  try {
    const userRes = await fetch(`${supabaseUrl}/auth/v1/user`, {
      headers: { Authorization: authHeader, apikey: anonKey },
    });

    if (!userRes.ok) {
      return jsonResponse({ error: "Unauthorized" }, 401);
    }

    const user = await userRes.json();
    const userId = typeof user?.id === "string" ? user.id : "";
    if (!userId) {
      return jsonResponse({ error: "Unauthorized" }, 401);
    }

    const deleteRes = await fetch(
      `${supabaseUrl}/auth/v1/admin/users/${encodeURIComponent(userId)}`,
      {
        method: "DELETE",
        headers: {
          Authorization: `Bearer ${serviceRoleKey}`,
          apikey: serviceRoleKey,
        },
      },
    );

    if (!deleteRes.ok) {
      console.error("[delete-account] Admin delete failed with status", deleteRes.status);
      return jsonResponse({ error: "Failed to delete account" }, 500);
    }

    return jsonResponse({ success: true }, 200);
  } catch {
    console.error("[delete-account] Request failed unexpectedly");
    return jsonResponse({ error: "Failed to delete account" }, 500);
  }
});
