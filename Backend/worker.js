// Deployed as the Cloudflare Worker "llr-exercises-api", bound to the D1 database
// "llr-exercises" (binding name DB). Deploy by hand via the Cloudflare API/dashboard
// or `wrangler deploy` once a wrangler.toml is added — see Backend/README.md.

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const cors = {
      "Access-Control-Allow-Origin": "*",
      "Content-Type": "application/json",
    };
    if (url.pathname === "/exercises" && request.method === "GET") {
      const muscle = url.searchParams.get("muscle");
      const stmt = muscle
        ? env.DB.prepare("SELECT id, name, muscle_group FROM exercises WHERE muscle_group = ? ORDER BY name").bind(muscle)
        : env.DB.prepare("SELECT id, name, muscle_group FROM exercises ORDER BY name");
      const { results } = await stmt.all();
      return new Response(JSON.stringify(results), { headers: cors });
    }
    return new Response(JSON.stringify({ error: "not found", routes: ["/exercises", "/exercises?muscle=Chest"] }), {
      status: 404,
      headers: cors,
    });
  },
};
