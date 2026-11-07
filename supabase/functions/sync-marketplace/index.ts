// Supabase Edge Function starter. Deploy only after you implement an approved provider adapter.
// Store marketplace credentials as Supabase Function secrets; never in the browser.
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

serve(async (_req) => {
  return new Response(JSON.stringify({
    ok: false,
    status: "not_configured",
    message: "Belum ada adapter/API marketplace yang diaktifkan. Hubungkan API/feed resmi dan kredensial yang disetujui terlebih dahulu."
  }), {
    status: 501,
    headers: { "content-type": "application/json", "access-control-allow-origin": "*" }
  });
});
