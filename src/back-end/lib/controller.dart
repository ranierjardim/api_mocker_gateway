import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:api_mocker_gateway/helpers/PathHelper.dart';
import 'package:conduit/conduit.dart';
import 'package:dio/dio.dart' as dio;
import 'package:yaml/yaml.dart';

class AMGController extends Controller {
  @override
  Future<RequestOrResponse> handle(Request request) async {
    final relativePath = request.path.remainingPath;
    print('relativePath: ${relativePath}');
    print('request.method: ${request.method}');
    final yamlFilePath = PathHelper.resolvePath('responses.yaml');
    print('file: ${yamlFilePath}');
    final yaml = File(yamlFilePath).readAsStringSync();
    print('yaml: ${yaml}');
    final document = loadYaml(yaml);
    print('document: ${document}');
    for (final endpoint in document['endpoints']) {
      if (endpoint['endpoint'] == request.path.remainingPath &&
          endpoint['method'].toLowerCase() == request.method.toLowerCase() &&
          endpoint['enabled'] as bool) {
        final response = Response.ok(endpoint['body']['content']);
        response.statusCode = endpoint['code'] as int;
        if (endpoint["body"]["content"].toLowerCase() == "json") {
          response.contentType = ContentType.json;
        } else {
          response.contentType = ContentType.text;
        }
        return response;
      }
    }
    final Map<String, dynamic> reqHeaders = {};
    request.raw.headers.forEach((name, values) {
      reqHeaders.addAll({name: values.join(",")});
    });
    print('url: ${'https://testeapi.inspectos.com/${request.path.remainingPath ?? ''}'}');
    print('headers: ${reqHeaders}');
    final bytes = await request.body.bytes.toList();
    final List<int> bodyRequestBytes = bytes.isEmpty ? [] : bytes[0];
    final bodyRequest = utf8.decode(bodyRequestBytes);
    print('bytes: ${bytes}');
    print('bodyRequest: ${bodyRequest}');
    print('Query: ${request.raw.requestedUri.queryParameters}');
    try {
      final dioResponse = await dio.Dio().request(
        'https://testeapi.inspectos.com/${request.path.remainingPath ?? ''}',
        data: bodyRequest,
        queryParameters: request.raw.requestedUri.queryParameters,
        options: dio.Options(
          method: request.method,
          headers: reqHeaders,
        ),
      );
      print('no response');
      final Map<String, dynamic> responseHeaders = {};
      dioResponse.headers.map.forEach((name, values) {
        responseHeaders.addAll({name: values.join(",")});
      });
      final response = Response.ok(dioResponse.data, headers: responseHeaders);
      response.statusCode = dioResponse.statusCode;
      print('dioResponse.data.runtimeType: ${dioResponse.data.runtimeType}');
      response.contentType = ContentType.json;
      print('resposta enviada: ${jsonEncode(dioResponse.data)}');
      return response;
    } catch (e, stack) {
      print('type: ${e.runtimeType}');
      print('stack: ${stack}');
      if(e is dio.DioError) {
        print('e.message: ${e.message}');
        print('e.error: ${e.error}');
        print('e.error.runtimeType: ${e.error.runtimeType}');
        print('e.response: ${e.response}');
        print('e.response.runtimeType: ${e.response.runtimeType}');

        final response = Response.ok(e.response?.data, headers: e.response?.headers.map);
        response.statusCode = e.response?.statusCode;
        response.contentType = ContentType.json;
        return response;
      }
    }
    return Response.serverError();
  }
}
