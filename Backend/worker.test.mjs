// Run with: node --test Backend/worker.test.mjs
import assert from "node:assert/strict";
import { test } from "node:test";
import worker from "./worker.js";

const rows = [
  { id: 1, name: "Bench Press (Barbell)", muscle_group: "Chest" },
  { id: 2, name: "Squat (Barbell)", muscle_group: "Quadriceps" },
];

/** A D1 stand-in that records each statement and its bound values. */
function fakeDB({ fail = false } = {}) {
  const calls = [];
  return {
    calls,
    prepare(sql) {
      const call = { sql, params: [] };
      calls.push(call);
      const statement = {
        bind(...params) {
          call.params = params;
          return statement;
        },
        async all() {
          if (fail) throw new Error("D1 unavailable");
          const filtered = call.params.length ? rows.filter((row) => row.muscle_group === call.params[0]) : rows;
          return { results: filtered };
        },
      };
      return statement;
    },
  };
}

const request = (path, method = "GET") => new Request(`https://api.example${path}`, { method });

test("lists every exercise", async () => {
  const response = await worker.fetch(request("/exercises"), { DB: fakeDB() });
  assert.equal(response.status, 200);
  assert.equal(response.headers.get("Content-Type"), "application/json; charset=utf-8");
  assert.equal(response.headers.get("X-Content-Type-Options"), "nosniff");
  assert.deepEqual(await response.json(), rows);
});

test("filters by muscle through a bound parameter, never string-built SQL", async () => {
  const db = fakeDB();
  const injection = "Chest' OR '1'='1";
  const response = await worker.fetch(request(`/exercises?muscle=${encodeURIComponent(injection)}`), { DB: db });
  assert.equal(response.status, 200);
  assert.deepEqual(await response.json(), []);
  assert.ok(!db.calls[0].sql.includes(injection));
  assert.deepEqual(db.calls[0].params, [injection]);
});

test("rejects an empty or oversized muscle filter", async () => {
  for (const muscle of ["", "x".repeat(65)]) {
    const response = await worker.fetch(request(`/exercises?muscle=${muscle}`), { DB: fakeDB() });
    assert.equal(response.status, 400);
  }
});

test("refuses writes and answers CORS preflight", async () => {
  const post = await worker.fetch(request("/exercises", "POST"), { DB: fakeDB() });
  assert.equal(post.status, 405);
  assert.equal(post.headers.get("Allow"), "GET, OPTIONS");
  const preflight = await worker.fetch(request("/exercises", "OPTIONS"), { DB: fakeDB() });
  assert.equal(preflight.status, 204);
  assert.equal(preflight.headers.get("Access-Control-Allow-Origin"), "*");
});

test("unknown paths are 404 with the route list", async () => {
  const response = await worker.fetch(request("/admin"), { DB: fakeDB() });
  assert.equal(response.status, 404);
  assert.deepEqual((await response.json()).routes, ["/exercises", "/exercises?muscle=Chest"]);
});

test("a database failure returns JSON 500 without internals", async (t) => {
  t.mock.method(console, "error", () => {});
  const response = await worker.fetch(request("/exercises"), { DB: fakeDB({ fail: true }) });
  assert.equal(response.status, 500);
  const body = await response.json();
  assert.deepEqual(body, { error: "internal error" });
  assert.ok(!JSON.stringify(body).includes("D1 unavailable"));
});
