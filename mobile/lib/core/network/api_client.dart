import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ApiClient {
  ApiClient() {
    final fromEnv = dotenv.env['RESQNET_API_BASE_URL'];
    _baseUrl = (fromEnv != null && fromEnv.isNotEmpty)
        ? fromEnv
        : 'https://8301-182-71-109-122.ngrok-free.app';
  }

  late final String _baseUrl;

  String get baseUrl => _baseUrl;

  /// Free ngrok often returns an HTML interstitial unless this header is set.
  Map<String, String> get _tunnelHeaders {
    final u = _baseUrl.toLowerCase();
    if (u.contains('ngrok-free.app') || u.contains('ngrok.io') || u.contains('ngrok.app')) {
      return {'ngrok-skip-browser-warning': 'true'};
    }
    return const {};
  }

  Map<String, String> _jsonHeaders() => {
        ..._tunnelHeaders,
        'Content-Type': 'application/json',
      };

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    return Uri.parse(_baseUrl).replace(
      path: path.startsWith('/') ? path : '/$path',
      queryParameters: query?.map((k, v) => MapEntry(k, '$v')),
    );
  }

  Future<List<dynamic>> getList(String path,
      {Map<String, dynamic>? query}) async {
    final res = await http.get(_uri(path, query), headers: _tunnelHeaders);
    if (res.statusCode >= 400) {
      throw Exception(
        'API GET $path failed (${res.statusCode}): ${res.body}',
      );
    }
    final body = jsonDecode(res.body);
    if (body is List) return body;
    throw Exception('Expected list response for $path');
  }

  Future<Map<String, dynamic>> getJson(String path,
      {Map<String, dynamic>? query}) async {
    final res = await http.get(_uri(path, query), headers: _tunnelHeaders);
    if (res.statusCode >= 400) {
      throw Exception(
        'API GET $path failed (${res.statusCode}): ${res.body}',
      );
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return body;
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? query,
  }) async {
    final res = await http.post(
      _uri(path, query),
      headers: _jsonHeaders(),
      body: jsonEncode(body ?? const <String, dynamic>{}),
    );
    if (res.statusCode >= 400) {
      throw Exception(
        'API POST $path failed (${res.statusCode}): ${res.body}',
      );
    }
    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    return decoded;
  }

  Future<dynamic> postJsonDynamic(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
  }) async {
    final res = await http.post(
      _uri(path, query),
      headers: _jsonHeaders(),
      body: jsonEncode(body ?? const <String, dynamic>{}),
    );
    if (res.statusCode >= 400) {
      throw Exception(
        'API POST $path failed (${res.statusCode}): ${res.body}',
      );
    }
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> patchJson(
    String path, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? query,
  }) async {
    final res = await http.patch(
      _uri(path, query),
      headers: _jsonHeaders(),
      body: jsonEncode(body ?? const <String, dynamic>{}),
    );
    if (res.statusCode >= 400) {
      throw Exception(
        'API PATCH $path failed (${res.statusCode}): ${res.body}',
      );
    }
    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    return decoded;
  }

  Future<dynamic> getDynamic(String path, {Map<String, dynamic>? query}) async {
    final res = await http.get(_uri(path, query), headers: _tunnelHeaders);
    if (res.statusCode >= 400) {
      throw Exception(
        'API GET $path failed (${res.statusCode}): ${res.body}',
      );
    }
    return jsonDecode(res.body);
  }

  Future<String> postFormRaw(
    String path, {
    required Map<String, String> body,
    Map<String, dynamic>? query,
  }) async {
    final res = await http.post(
      _uri(path, query),
      headers: {
        ..._tunnelHeaders,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: body,
    );
    if (res.statusCode >= 400) {
      throw Exception(
        'API POST(form) $path failed (${res.statusCode}): ${res.body}',
      );
    }
    return res.body;
  }

  Future<Map<String, dynamic>> postMultipart(
    String path, {
    required String fileField,
    required Uint8List fileBytes,
    required String filename,
    MediaType? fileContentType,
    required Map<String, String> fields,
    Map<String, dynamic>? query,
  }) async {
    final req = http.MultipartRequest('POST', _uri(path, query));
    req.headers.addAll(_tunnelHeaders);
    req.fields.addAll(fields);
    req.files.add(
      http.MultipartFile.fromBytes(
        fileField,
        fileBytes,
        filename: filename,
        contentType: fileContentType,
      ),
    );

    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode >= 400) {
      throw Exception(
        'API POST $path failed (${res.statusCode}): ${res.body}',
      );
    }
    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    return decoded;
  }
}

