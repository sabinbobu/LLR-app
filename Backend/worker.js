// Deployed as the Cloudflare Worker "llr-exercises-api", bound to the D1 database
// "llr-exercises" (binding name DB). Deploy by hand via the Cloudflare API/dashboard
// or `wrangler deploy` once a wrangler.toml is added — see Backend/README.md.

const ROUTES = ["/exercises", "/exercises?muscle=Chest"];
// Longest library value is "Lower Back"; anything far past it is junk, not a muscle group.
const MAX_MUSCLE_LENGTH = 64;

const baseHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Content-Type": "application/json; charset=utf-8",
  "X-Content-Type-Options": "nosniff",
};

function json(body, status = 200, extra = {}) {
  return new Response(JSON.stringify(body), { status, headers: { ...baseHeaders, ...extra } });
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    if (url.pathname !== "/exercises") {
      return json({ error: "not found", routes: ROUTES }, 404);
    }
    if (request.method === "OPTIONS") {
      return new Response(null, {
        status: 204,
        headers: { ...baseHeaders, "Access-Control-Allow-Methods": "GET, OPTIONS", "Access-Control-Max-Age": "86400" },
      });
    }
    // Read-only API: say so instead of answering a POST or DELETE with the list.
    if (request.method !== "GET") {
      return json({ error: "method not allowed" }, 405, { Allow: "GET, OPTIONS" });
    }
    const muscle = url.searchParams.get("muscle");
    if (muscle !== null && (muscle.length === 0 || muscle.length > MAX_MUSCLE_LENGTH)) {
      return json({ error: "invalid muscle" }, 400);
    }
    try {
      const stmt = muscle
        ? env.DB.prepare("SELECT id, name, muscle_group FROM exercises WHERE muscle_group = ? ORDER BY name").bind(muscle)
        : env.DB.prepare("SELECT id, name, muscle_group FROM exercises ORDER BY name");
      const { results } = await stmt.all();
      // The library changes rarely; a short edge cache spares D1 a read per request.
      return json(results, 200, { "Cache-Control": "public, max-age=300" });
    } catch (error) {
      // Logged for `wrangler tail`; the caller gets no internals.
      console.error("exercises query failed", error);
      return json({ error: "internal error" }, 500);
    }
  },
};
