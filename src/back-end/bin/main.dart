import 'package:api_mocker_gateway/api_mocker_gateway.dart';

Future main() async {
  final amgChannelApp = Application<AMGChannel>()
    ..options.port = 8888;


  await amgChannelApp.start();

  print("Application started.");
}
