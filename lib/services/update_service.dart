import 'dart:io';
import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

const _githubOwner = 'devMatrix0815';
const _githubRepo = 'orbit';

class UpdateInfo {
  final String version;
  final String releaseNotes;
  final String downloadUrl;

  const UpdateInfo({
    required this.version,
    required this.releaseNotes,
    required this.downloadUrl,
  });
}

class UpdateService {
  static final _dio = Dio();

  static Future<String> currentVersion() async {
    final info = await PackageInfo.fromPlatform();
    return info.version;
  }

  // Returns null if already up to date, UpdateInfo if a newer release exists.
  static Future<UpdateInfo?> checkForUpdate() async {
    final current = await currentVersion();

    final resp = await _dio.get(
      'https://api.github.com/repos/$_githubOwner/$_githubRepo/releases/latest',
      options: Options(headers: {'Accept': 'application/vnd.github+json'}),
    );

    final data = resp.data as Map<String, dynamic>;
    final tag = data['tag_name'] as String;
    final latest = tag.startsWith('v') ? tag.substring(1) : tag;

    if (!_isNewer(latest, current)) return null;

    final notes = data['body'] as String? ?? '';
    final assets = data['assets'] as List<dynamic>;
    final apkUrl = assets
        .where((a) => (a['name'] as String).endsWith('.apk'))
        .map((a) => a['browser_download_url'] as String)
        .firstOrNull;

    if (apkUrl == null) return null;

    return UpdateInfo(version: latest, releaseNotes: notes, downloadUrl: apkUrl);
  }

  static Future<void> downloadAndInstall(
    String url, {
    required void Function(double progress) onProgress,
  }) async {
    final dir = Platform.isAndroid
        ? await getExternalStorageDirectory() ?? await getTemporaryDirectory()
        : await getTemporaryDirectory();

    final filePath = '${dir.path}/orbit_update.apk';

    await _dio.download(
      url,
      filePath,
      onReceiveProgress: (received, total) {
        if (total > 0) onProgress(received / total);
      },
    );

    await OpenFilex.open(filePath);
  }

  // Compares semantic versions: returns true if [latest] > [current].
  static bool _isNewer(String latest, String current) {
    List<int> parse(String v) =>
        v.split('-').first.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    final l = parse(latest);
    final c = parse(current);
    final len = l.length > c.length ? l.length : c.length;

    for (var i = 0; i < len; i++) {
      final lv = i < l.length ? l[i] : 0;
      final cv = i < c.length ? c[i] : 0;
      if (lv > cv) return true;
      if (lv < cv) return false;
    }
    return false;
  }
}
