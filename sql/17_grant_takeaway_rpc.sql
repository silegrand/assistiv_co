-- Expose takeaway() and takeaway_summary() as callable RPCs.
--
-- The Worker calls these with the service key, so we grant to the roles the
-- service key resolves to. We deliberately do NOT grant to anon: the public
-- browser never calls Supabase directly, only via the Worker. This keeps the
-- attack surface to the Worker's own /takeaway endpoint.

grant execute on function takeaway(
  double precision, double precision, text[], int, int, int, boolean
) to service_role;

grant execute on function takeaway_summary(
  double precision, double precision, text[], int
) to service_role;

-- PostgREST needs to see the function in its schema cache. If a call 404s with
-- "function not found", run:  notify pgrst, 'reload schema';
notify pgrst, 'reload schema';
