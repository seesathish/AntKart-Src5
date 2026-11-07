namespace AK.BuildingBlocks.HealthChecks;

// Tags partition health checks across the THREE probe surfaces (liveness / readiness / deep
// diagnostics). The "ak:" prefix is deliberate: third-party libraries register their OWN checks
// with plain tags — many libraries tag their own check "ready". If our readiness probe selected
// the bare "ready" tag it would silently inherit that library's state and couple readiness to a
// shared dependency (one blip would then pull every pod out of rotation). Selecting by an
// ak:-prefixed tag keeps each surface under our explicit control.
public static class HealthCheckTags
{
    public const string Live = "ak:live";   // shallow — process is up; performs NO external calls
    public const string Ready = "ak:ready"; // ready to serve traffic; tolerant of dependency blips
    public const string Deep = "ak:deep";   // deep dependency diagnostics; NEVER a probe target
}
