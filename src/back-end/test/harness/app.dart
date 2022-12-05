import 'package:api_mocker_gateway/api_mocker_gateway.dart';
import 'package:conduit_test/conduit_test.dart';

export 'package:conduit/conduit.dart';
export 'package:conduit_test/conduit_test.dart';
export 'package:test/test.dart';

/// A harness for testing an conduit application. Example test file:
///
///         void main() {
///           Harness harness = Harness()..install();
///
///           test("GET /path returns 200", () async {
///             final response = await harness.agent.get("/path");
///             expectResponse(response, 200);
///           });
///         }
///
class Harness extends TestHarness<AMGChannel> {
  @override
  Future onSetUp() async {}

  @override
  Future onTearDown() async {}
}
