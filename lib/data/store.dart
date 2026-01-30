import '../models/note.dart';
import '../services/ai_service.dart';

class Store {
  Store._private();
  static final Store instance = Store._private();

  final List<Note> _notes = [];

  List<Note> getNotes() => List.unmodifiable(_notes.reversed);

  void addNote(Note note) {
    _notes.add(note);
  }

  /// 非同期でAIベースのタグ抽出を試みる。失敗した場合は簡易フォールバックを使う。
  Future<List<String>> generateTags(String text) async {
    try {
      final tags = await AiService.instance.extractTags(text);
      if (tags.isNotEmpty) return tags;
    } catch (_) {}
    // フォールバック（簡易）
    final fallback = <String>{};
    final t = text.toLowerCase();
    if (t.contains('開発') || t.contains('アプリ') || t.contains('実装')) fallback.add('開発');
    if (t.contains('予算') || t.contains('コスト') || t.contains('費用')) fallback.add('予算');
    if (t.contains('アイデア') || t.contains('発想')) fallback.add('アイデア');
    if (t.contains('会議') || t.contains('ミーティング')) fallback.add('会議');
    if (t.contains('todo') || t.contains('やること') || t.contains('タスク')) fallback.add('タスク');
    if (fallback.isEmpty) fallback.add('メモ');
    return fallback.toList();
  }
}
