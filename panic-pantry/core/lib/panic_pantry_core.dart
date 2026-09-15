/// Shared, deterministic game logic for Panic Pantry.
///
/// The server runs [Simulation] authoritatively; clients use the same model to
/// decode snapshots, predict local movement and render the kitchen.
library;

export 'src/bot.dart';
export 'src/items.dart';
export 'src/levels.dart';
export 'src/protocol.dart';
export 'src/rng.dart';
export 'src/scoring.dart';
export 'src/simulation.dart';
export 'src/state.dart';
export 'src/tiles.dart';
