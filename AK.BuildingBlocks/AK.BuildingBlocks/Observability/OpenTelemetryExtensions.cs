using System.Reflection;
using Azure.Monitor.OpenTelemetry.Exporter;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using OpenTelemetry;
using OpenTelemetry.Resources;
using OpenTelemetry.Trace;

namespace AK.BuildingBlocks.Observability;

// OpenTelemetry wiring shared by every .NET service. Distributed traces are exported to
// Application Insights (Azure Monitor). OTel propagates the W3C traceparent header automatically
// on outbound HttpClient calls, so a request is correlated end-to-end without hand-plumbing.
//
// THE PYTHON HOP: a request crosses runtimes twice — .NET gateway -> Python orchestrator, and
// Python agent -> .NET MCP server. Both hops are plain HTTP, so traceparent survives them ONLY if
// the Python side reads the incoming header and sets it on its own outbound calls. That is the
// Python orchestrator's OTel setup, not this file's; this file guarantees the .NET half. Without
// it the trace breaks into three disconnected pieces instead of one.
//
// Metrics are NOT collected here, and logs are NOT exported here — Serilog owns logging. The two
// meet in Log Analytics, where a log line's TraceId equals a span's OperationId.
public static class OpenTelemetryExtensions
{
    // Vaulted secret ApplicationInsights--ConnectionString maps to this config key.
    private const string ConnectionStringKey = "ApplicationInsights:ConnectionString";

    public static IHostApplicationBuilder AddOpenTelemetryObservability(
        this IHostApplicationBuilder builder, string serviceName)
    {
        var serviceVersion = (Assembly.GetEntryAssembly() ?? Assembly.GetExecutingAssembly())
            .GetName().Version?.ToString() ?? "unknown";
        var environmentName = builder.Environment.EnvironmentName;
        var connectionString = builder.Configuration[ConnectionStringKey];
        var hasAzureMonitor = !string.IsNullOrWhiteSpace(connectionString);

        builder.Services.AddOpenTelemetry()
            .ConfigureResource(resource => resource
                .AddService(serviceName: serviceName, serviceVersion: serviceVersion)
                .AddAttributes(new[]
                {
                    new KeyValuePair<string, object>("deployment.environment", environmentName)
                }))
            .WithTracing(tracing =>
            {
                tracing
                    // Health probes must not become traces — every probe would bill App Insights for no value.
                    .AddAspNetCoreInstrumentation(options =>
                        options.Filter = context => !IsHealthEndpoint(context.Request.Path))
                    // Outbound calls carry traceparent: gateway -> orchestrator, agent -> MCP
                    // server, MCP server -> Catalogue/Cart/Orders/Users. This is the single
                    // mechanism that stitches the agent loop to the services it acts on.
                    .AddHttpClientInstrumentation()
                    // Data-store spans via each driver's own ActivitySource:
                    .AddSource("Npgsql")              // PostgreSQL command spans (Orders, Users, Catalogue)
                    // Redis command spans (Cart). The DI overload resolves IConnectionMultiplexer from
                    // the service provider when present; this extension is shared by every service, and
                    // services without Redis registered are unaffected (no multiplexer, nothing
                    // instrumented). NOTE: only `Configure Topology` spans were ever confirmed in the
                    // earlier platform — treat Redis command spans as unverified until seen in a query.
                    .AddRedisInstrumentation();

                if (hasAzureMonitor)
                    tracing.AddAzureMonitorTraceExporter(options => options.ConnectionString = connectionString);
            });

        if (!hasAzureMonitor)
            // Local development has no Key Vault; the service must still start. Traces are
            // collected in-process but not exported until the connection string is present.
            Serilog.Log.Warning(
                "OpenTelemetry: no {Key} configured for {ServiceName} — traces are collected but NOT exported to Application Insights (expected in local development).",
                ConnectionStringKey, serviceName);

        return builder;
    }

    // Matches /health, /health/live, /health/ready, /health/deps (segment-boundary aware,
    // so it does not match e.g. /healthz).
    private static bool IsHealthEndpoint(PathString path) => path.StartsWithSegments("/health");
}
