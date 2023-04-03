import 'dart:convert';
import 'dart:io';

import 'package:alfred/alfred.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart' as dio;
import 'package:path_to_regexp/path_to_regexp.dart';
import 'package:yaml/yaml.dart';

String? currentFile;
int currentAppPort = 3000;

Future<void> main() async {
  final app = Alfred();
  app.all('*', requestHandler);
  await app.listen(currentAppPort);
  runApp(const MyApp());
}

Future<dynamic> requestHandler(HttpRequest req, HttpResponse res) async {
  try {
    if (currentFile == null) {
      print('Arquivo de configuração não selecionado');
      res.statusCode = 503;
      return 'Arquivo de configuração não selecionado';
    } else {
      final filePath = currentFile!;
      print('filePath: $filePath');
      final yaml = File(filePath).readAsStringSync();
      //print('yaml: $yaml');
      final document = loadYaml(yaml);
      //print('document: $document');
      final requestPath = req.requestedUri.path;
      print('requestPath: $requestPath');
      for (final endpoint in document['endpoints']) {
        final regExp = pathToRegExp(endpoint['endpoint']);
        if (regExp.hasMatch(requestPath) &&
            endpoint['method'].toLowerCase() == req.method.toLowerCase() &&
            endpoint['enabled'] as bool) {
          res.statusCode = endpoint['code'] as int;
          if (endpoint["body"]["type"].toLowerCase() == "json") {
            res.setContentTypeFromExtension('json');
          } else {
            res.setContentTypeFromExtension('text');
          }
          return endpoint['body']['content'];
        }
      }
      final serverUrl = document['url'];
      print('serverUrl: $serverUrl');
      final Map<String, dynamic> reqHeaders = {};
      req.headers.forEach((name, values) {
        if(name != 'host') {
          reqHeaders.addAll({name: values.join(",")});
        }
      });
      print('reqHeaders: $reqHeaders');
      final requestUrl = '$serverUrl${requestPath ?? ''}';
      print('url: $requestUrl');
      dynamic body;
      if (req.contentLength > 0) {
        body = await req.body;
      }
      print('body: $body');
      print('Query: ${req.requestedUri.queryParameters}');

      try {
        final dioResponse = await dio.Dio().request(
          requestUrl,
          data: body,
          queryParameters: req.requestedUri.queryParameters,
          options: dio.Options(
            method: req.method,
            headers: reqHeaders,
          ),
        );

        print('no response');
        final Map<String, dynamic> responseHeaders = {};
        dioResponse.headers.map.forEach((name, values) {
          responseHeaders.addAll({name: values.join(",")});
        });
        res.statusCode = dioResponse.statusCode!;
        print(
            'dioResponse.data.runtimeType: ${dioResponse.data.runtimeType}');
        if(requestPath == '/controle-acesso-360-api/v1/usuarios/info/') {
          print('ContentType.text: ${ContentType.text.subType}');
          res.setContentTypeFromExtension(ContentType.text.subType);
          return jsonEncode(dioResponse.data);
        }
        final contentType = ContentType.parse(dioResponse.headers.value('content-type') ?? 'application/json');

        print('contentType: ${contentType.subType}');
        res.setContentTypeFromExtension(contentType.subType);
        print('Response headers: ${dioResponse.headers.map}');
        print('resposta enviada: ${jsonEncode(dioResponse.data)}');
        return dioResponse.data;


      } catch (e, stack) {
        print('type: ${e.runtimeType}');
        print('stack: ${stack}');
        if (e is dio.DioError) {
          print('e.message: ${e.message}');
          print('e.error: ${e.error}');
          print('e.error.runtimeType: ${e.error.runtimeType}');
          print('e.response: ${e.response}');
          print('e.response.runtimeType: ${e.response.runtimeType}');

//final response = Response.ok(e.response?.data, headers: e.response?.headers.map);
          res.statusCode = e.response?.statusCode ?? 500;
          res.setContentTypeFromExtension(ContentType.json.subType);
          res.headers.clear();
          e.response?.headers.map.forEach((key, value) {
            res.headers.add(key, value);
          });
          return e.response?.data;
        }
      }
    }
  } catch (e) {
    rethrow;
    res.statusCode = 500;
    return 'Erro ao processar solicitação';
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'API Mocker Gateway',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Future<void> _pickTheFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: ['yaml', 'yml'],
      lockParentWindow: true,
    );
    if (result != null) {
      setState(() {
        currentFile = result!.files.single.path!;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      body: Center(
        child: Builder(builder: (context) {
          if (currentFile != null) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Modificação de API ativada, direcione as requisições para este computador na porta $currentAppPort.\n\nCaso necessário alterar alguma resposta, altere no arquivo de configuração que foi selecionado.\n\nArquivo selecionado: $currentFile',
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            );
          } else {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Nenhum arquivo selecionado, por favor, selecione um arquivo de configuração',
                  ),
                ),
                MaterialButton(
                  color: Colors.blue,
                  child: const Text(
                    'Selecionar arquivo',
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: _pickTheFile,
                ),
              ],
            );
          }
        }),
      ),
      floatingActionButton: currentFile == null
          ? null
          : FloatingActionButton(
              onPressed: _pickTheFile,
              tooltip: 'Trocar de arquivo',
              child: const Icon(Icons.insert_drive_file_sharp),
            ),
    );
  }
}
