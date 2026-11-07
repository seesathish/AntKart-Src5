namespace AK.BuildingBlocks.DDD;

// Shared base class for domain entities that use a string primary key.
// For entities whose id is a string rather than a Guid — e.g. a catalogue item keyed by a
// deterministic SKU-derived id, or a document id that has to match a retrieval index.
//
// ID default: Guid.NewGuid().ToString("N") produces a compact 32-char hex string.
// A 32-character hex string rather than a Guid, for an entity whose id has to survive as text.
public abstract class StringEntity
{
    public string Id { get; protected set; } = Guid.NewGuid().ToString("N");
    public DateTimeOffset CreatedAt { get; protected set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset? UpdatedAt { get; protected set; }

    private readonly List<IDomainEvent> _domainEvents = [];
    public IReadOnlyCollection<IDomainEvent> DomainEvents => _domainEvents.AsReadOnly();

    protected void AddDomainEvent(IDomainEvent domainEvent) => _domainEvents.Add(domainEvent);
    public void ClearDomainEvents() => _domainEvents.Clear();
    protected void SetUpdatedAt() => UpdatedAt = DateTimeOffset.UtcNow;
}
