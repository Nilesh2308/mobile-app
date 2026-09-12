import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/document_item.dart';
import '../models/system_health.dart';

class ApiResponse<T> {
  const ApiResponse({
    this.data,
    this.error,
    required this.isSuccess,
  });

  final T? data;
  final String? error;
  final bool isSuccess;

  factory ApiResponse.success(T data) => ApiResponse(data: data, isSuccess: true);
  factory ApiResponse.failure(String error) => ApiResponse(error: error, isSuccess: false);
}

/// Standardized API client for Voice AI backend services.
class ApiClient {
  const ApiClient();

  String get _baseUrl => AppConfig.baseUrl;

  Duration get _defaultTimeout => const Duration(seconds: 15);

  /// Check health status of backend models
  Future<ApiResponse<SystemHealth>> checkHealth() async {
    try {
      final uri = Uri.parse('$_baseUrl/api/health');
      final response = await http.get(uri).timeout(_defaultTimeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return ApiResponse.success(SystemHealth.fromJson(json));
      } else {
        return ApiResponse.failure('Backend returned HTTP ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse.failure('Cannot connect to $_baseUrl ($e)');
    }
  }

  /// Get analytics stats
  Future<ApiResponse<Map<String, dynamic>>> getStats() async {
    try {
      final uri = Uri.parse('$_baseUrl/api/stats');
      final response = await http.get(uri).timeout(_defaultTimeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return ApiResponse.success(json);
      } else {
        return ApiResponse.failure('Failed to fetch stats: HTTP ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse.failure(e.toString());
    }
  }

  /// Send text query to RAG pipeline
  Future<ApiResponse<Map<String, dynamic>>> sendChatQuery({
    required String query,
    required String sessionId,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/chat/');
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'query': query,
              'session_id': sessionId,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        return ApiResponse.success(json);
      } else {
        return ApiResponse.failure('Chat request failed: ${response.body}');
      }
    } catch (e) {
      return ApiResponse.failure('Connection error: $e');
    }
  }

  /// Send voice recording + session_id to POST /api/voice/chat
  Future<ApiResponse<Map<String, dynamic>>> sendVoiceChat({
    String? filePath,
    List<int>? fileBytes,
    required String sessionId,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/voice/chat');
      final request = http.MultipartRequest('POST', uri);
      request.fields['session_id'] = sessionId;

      if (fileBytes != null && fileBytes.isNotEmpty) {
        final multipartFile = http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: 'query.m4a',
        );
        request.files.add(multipartFile);
      } else if (filePath != null && filePath.isNotEmpty) {
        final multipartFile = await http.MultipartFile.fromPath('file', filePath);
        request.files.add(multipartFile);
      } else {
        return ApiResponse.failure('No audio file provided to sendVoiceChat');
      }

      final streamedResponse = await request.send().timeout(const Duration(seconds: 90));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        return ApiResponse.success(json);
      } else {
        return ApiResponse.failure('Voice chat failed (HTTP ${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      return ApiResponse.failure('Voice chat error: $e');
    }
  }

  /// List indexed knowledge base documents
  Future<ApiResponse<List<DocumentItem>>> listDocuments() async {
    try {
      final uri = Uri.parse('$_baseUrl/api/kb/documents');
      final response = await http.get(uri).timeout(_defaultTimeout);

      if (response.statusCode == 200) {
        final list = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
        final docs = list.map((item) => DocumentItem.fromJson(item as Map<String, dynamic>)).toList();
        return ApiResponse.success(docs);
      } else {
        return ApiResponse.failure('Failed to list documents: HTTP ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse.failure('Connection error: $e');
    }
  }

  /// Delete indexed document by ID
  Future<ApiResponse<bool>> deleteDocument(String docId) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/kb/documents/$docId');
      final response = await http.delete(uri).timeout(_defaultTimeout);

      if (response.statusCode == 200) {
        return ApiResponse.success(true);
      } else {
        return ApiResponse.failure('Delete failed: ${response.body}');
      }
    } catch (e) {
      return ApiResponse.failure(e.toString());
    }
  }

  /// Upload documents (multipart/form-data)
  Future<ApiResponse<Map<String, dynamic>>> uploadDocuments({
    required List<String> filePaths,
    List<Map<String, dynamic>>? inMemoryFiles,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/kb/upload');
      final request = http.MultipartRequest('POST', uri);

      // Add files by path
      for (final path in filePaths) {
        final multipartFile = await http.MultipartFile.fromPath('files', path);
        request.files.add(multipartFile);
      }

      // Add files by bytes if available
      if (inMemoryFiles != null) {
        for (final item in inMemoryFiles) {
          final name = item['name'] as String;
          final bytes = item['bytes'] as List<int>;
          final multipartFile = http.MultipartFile.fromBytes('files', bytes, filename: name);
          request.files.add(multipartFile);
        }
      }

      final streamedResponse = await request.send().timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        return ApiResponse.success(json);
      } else {
        return ApiResponse.failure('Upload failed (HTTP ${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      return ApiResponse.failure('Connection error during upload: $e');
    }
  }

  /// Get domain summary
  Future<ApiResponse<String>> getDomainSummary() async {
    try {
      final uri = Uri.parse('$_baseUrl/api/kb/summary');
      final response = await http.get(uri).timeout(_defaultTimeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final summary = json['summary'] as String? ?? '';
        return ApiResponse.success(summary);
      } else {
        return ApiResponse.failure('Failed to fetch summary: HTTP ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse.failure(e.toString());
    }
  }

  /// Reset session on backend
  Future<void> resetSession(String sessionId) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/chat/session/$sessionId');
      await http.delete(uri).timeout(_defaultTimeout);
    } catch (_) {}
  }

  /// Hard-delete all chat history on backend database
  Future<void> clearAllChats() async {
    try {
      final uri = Uri.parse('$_baseUrl/api/chat/clear');
      await http.delete(uri).timeout(_defaultTimeout);
    } catch (_) {}
  }
}
