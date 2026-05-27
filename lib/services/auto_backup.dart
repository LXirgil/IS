import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../data/bowling_repository.dart';

class AutoBackupService {
  AutoBackupService._();
  static final instance = AutoBackupService._();

  Timer? _timer;

  Future<void> start({Duration interval = const Duration(hours: 24)}) async {
    // immediate backup
    await performBackup();
    // periodic
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) async {
      await performBackup();
    });
  }

  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> performBackup() async {
    try {
      final json = BowlingRepository.instance.exportJson();
      final now = DateTime.now();
      final ts = '${now.year}${now.month.toString().padLeft(2,'0')}${now.day.toString().padLeft(2,'0')}_${now.hour.toString().padLeft(2,'0')}${now.minute.toString().padLeft(2,'0')}';
      final doc = await getApplicationDocumentsDirectory();
      final file = File('${doc.path}/ai_bowling_autobackup_$ts.json');
      await file.writeAsString(json);

      // try to copy to Downloads on Windows
      if (Platform.isWindows) {
        final env = Platform.environment['USERPROFILE'];
        if (env != null) {
          final downloads = Directory('$env\\Downloads');
          if (downloads.existsSync()) {
            final dest = File('${downloads.path}\\AI_Bowling_autobackup_$ts.json');
            await file.copy(dest.path);
          }
        }
      }
    } catch (_) {
      // ignore backup failures silently
    }
  }
}
