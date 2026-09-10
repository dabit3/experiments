/// Launch overrides from the process environment (desktop) or the page URL
/// (web), keyed without the `BRICKFOLK_` prefix in lower case.
library;

export 'launch_env_stub.dart' if (dart.library.io) 'launch_env_io.dart';
