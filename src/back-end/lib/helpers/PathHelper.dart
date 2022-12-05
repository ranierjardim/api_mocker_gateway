import 'package:dcli/dcli.dart';
import 'package:path/path.dart' as path;


class PathHelper {

  static String resolvePath(String pathToResolve, {bool absolute = true}) {
    return path.joinAll([path.dirname(DartScript.self.pathToScript), '..', pathToResolve]);
  }
}