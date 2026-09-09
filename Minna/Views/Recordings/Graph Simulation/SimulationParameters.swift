
/// Tunable constants for the note graph force simulation. Every value can be adjusted live from `SimulationControlsView`; the simulation reads them each frame.
/// - Authored by: Claude Fable 5 (Anthropic)
@Observable
final class SimulationParameters {
    /// How strongly connected notes pull toward their rest distance, in 1/s². Springs are the only attractive force between notes.
    var springStiffness: Double = 4
    /// The desired edge-to-edge gap between two connected cards, in points. The spring rest length is this gap plus both cards' effective radii.
    var springRestGap: Double = 50
    /// Inverse-square repulsion applied between every pair of notes, connected or not. Springs dominate for connected notes, so this mostly spaces out unrelated clusters.
    var repulsionStrength: Double = 400_000
    /// Distance (between card edges) beyond which repulsion is skipped, in points.
    var repulsionRadius: Double = 800
    /// Spring-like pull toward the canvas center, in 1/s². This is what keeps disconnected clusters from drifting off the edge of the canvas forever.
    var centerStrength: Double = 0.6
    /// Exponential velocity damping rate, per second. Higher values bleed off energy faster and settle the layout sooner.
    var damping: Double = 6
    /// Hard cap on node speed in points per second. Prevents any force spike from launching a note across the canvas.
    var maxSpeed: Double = 1_000
    /// Cosine distance between sentence embeddings below which two notes are considered related and get a spring.
    var connectionThreshold: Double = 0.85
    /// Exponent on a note's area-derived mass. At 0 every note weighs the same; at 1 a card's mass scales with its area, so large notes pull small notes strongly while barely moving themselves; above 1 the effect is exaggerated.
    var massInfluence: Double = 1
    /// Speed below which a node counts as at rest. When every node is below this for half a second the simulation sleeps.
    var sleepSpeed: Double = 30
    /// When enabled, overlapping cards are pushed apart so notes pack instead of stacking.
    var collisionsEnabled: Bool = true
    /// Draws the springs between connected notes, Obsidian style.
    var showsConnections: Bool = true

    /// Restores every parameter to its default value.
    /// - Authored by: Claude Fable 5 (Anthropic)
    func reset() {
        springStiffness = 4
        springRestGap = 50
        repulsionStrength = 400_000
        repulsionRadius = 800
        centerStrength = 0.6
        damping = 6
        maxSpeed = 1_000
        connectionThreshold = 0.85
        massInfluence = 1
        sleepSpeed = 4
        collisionsEnabled = true
        showsConnections = true
    }
}