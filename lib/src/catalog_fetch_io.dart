import 'dart:convert';
import 'dart:io';

/// Downloads the catalog JSON; `null` on any error or after 5 seconds.
Future<String?> fetchCatalog(Uri uri) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
  try {
    final request = await client.getUrl(uri);
    final response = await request.close().timeout(const Duration(seconds: 5));
    if (response.statusCode != 200) return null;
    return await response.transform(utf8.decoder).join();
  } catch (_) {
    return null;
  } finally {
    client.close(force: true);
  }
}
