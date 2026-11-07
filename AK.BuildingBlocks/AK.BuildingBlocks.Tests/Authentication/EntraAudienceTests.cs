using System.Security.Cryptography;
using AK.BuildingBlocks.Authentication;
using FluentAssertions;
using Microsoft.IdentityModel.JsonWebTokens;
using Microsoft.IdentityModel.Tokens;

namespace AK.BuildingBlocks.Tests.Authentication;

public sealed class EntraAudienceTests
{
    // Fixtures, not configuration. The GUID is deliberately a non-existent one:
    // a test has no business carrying a real directory's identifiers, and these
    // assertions are about the SHAPE of the audience check — that both the App ID
    // URI and the client-id form are accepted — which holds for any values.
    private const string AppIdUri = "api://antkart-api-test";
    private const string ClientId = "00000000-0000-0000-0000-00000000beef";

    private static EntraSettings Settings() => new() { Audience = AppIdUri, ClientId = ClientId };

    // ── ResolveValidAudiences ───────────────────────────────────────────────────────────────

    [Fact]
    public void ResolveValidAudiences_IncludesBoth_AppIdUri_And_ClientId()
    {
        Settings().ResolveValidAudiences().Should().BeEquivalentTo(new[] { AppIdUri, ClientId });
    }

    [Fact]
    public void ResolveValidAudiences_WithOnlyAudience_ReturnsThatOne()
    {
        new EntraSettings { Audience = AppIdUri }.ResolveValidAudiences()
            .Should().ContainSingle().Which.Should().Be(AppIdUri);
    }

    [Fact]
    public void ResolveValidAudiences_WithOnlyClientId_ReturnsThatOne()
    {
        new EntraSettings { ClientId = ClientId }.ResolveValidAudiences()
            .Should().ContainSingle().Which.Should().Be(ClientId);
    }

    // ── Token audience acceptance (real JWT stack, focused on the audience check) ────────────

    private static readonly SymmetricSecurityKey TestKey =
        new(RandomNumberGenerator.GetBytes(32));

    private static string CreateToken(string audience)
    {
        return new JsonWebTokenHandler().CreateToken(new SecurityTokenDescriptor
        {
            Audience = audience,
            Issuer = "https://test-issuer",
            Expires = DateTime.UtcNow.AddMinutes(5),
            SigningCredentials = new SigningCredentials(TestKey, SecurityAlgorithms.HmacSha256)
        });
    }

    private static TokenValidationParameters AudienceValidationParameters() => new()
    {
        ValidateAudience = true,
        ValidAudiences = Settings().ResolveValidAudiences(),
        ValidateIssuer = false,
        ValidateLifetime = false,
        ValidateIssuerSigningKey = true,
        IssuerSigningKey = TestKey
    };

    [Fact]
    public async Task Token_WithAudience_ClientIdGuid_IsAccepted()
    {
        var result = await new JsonWebTokenHandler()
            .ValidateTokenAsync(CreateToken(ClientId), AudienceValidationParameters());

        result.IsValid.Should().BeTrue();
    }

    [Fact]
    public async Task Token_WithAudience_AppIdUri_IsAccepted()
    {
        var result = await new JsonWebTokenHandler()
            .ValidateTokenAsync(CreateToken(AppIdUri), AudienceValidationParameters());

        result.IsValid.Should().BeTrue();
    }

    [Fact]
    public async Task Token_WithAudience_ForAnotherApi_IsRejected()
    {
        var result = await new JsonWebTokenHandler()
            .ValidateTokenAsync(CreateToken("api://some-other-api"), AudienceValidationParameters());

        result.IsValid.Should().BeFalse();
    }
}
