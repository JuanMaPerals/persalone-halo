/// Evidence status for a capability or runtime event.
///
/// A transport acknowledgement, test fixture, or vendor claim must not be
/// represented as [measured] without reproducible physical evidence.
enum TruthLabel {
  simulated,
  prepared,
  measured,
  blocked,
  failed,
}
