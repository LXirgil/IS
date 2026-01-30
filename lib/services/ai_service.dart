// デモ用の簡易AIサービス
// 将来的に外部API(OpenAIなど)を呼ぶ箇所をここに実装する
class AiService {
  AiService._();
  static final instance = AiService._();

  /// 簡易要約: 長文なら先頭の文を抜き、必要に応じて末尾に…を付ける
  Future<String> summarize(String text, {int maxLength = 200}) async {
    final t = text.trim();
    if (t.isEmpty) return '';
    // 単純：句点で区切って最初の文を返す（日本語の句点対応）
    final endIdx = t.indexOf(RegExp(r'[。．.!?]'));
    String firstSentence;
    if (endIdx != -1 && endIdx < t.length - 1) {
      firstSentence = t.substring(0, endIdx + 1);
    } else {
      firstSentence = t;
    }
    if (firstSentence.length > maxLength) {
      return '${firstSentence.substring(0, maxLength)}…';
    }
    return firstSentence;
  }

  /// 簡易タグ抽出: キーワードマッチベースでタグ候補を返す
  Future<List<String>> extractTags(String text) async {
    final lower = text.toLowerCase();
    final Set<String> tags = {};
    if (lower.contains('開発') || lower.contains('アプリ') || lower.contains('実装')) tags.add('開発');
    if (lower.contains('予算') || lower.contains('コスト') || lower.contains('費用')) tags.add('予算');
    if (lower.contains('会議') || lower.contains('ミーティング')) tags.add('会議');
    if (lower.contains('買い物') || lower.contains('ランチ') || lower.contains('レシピ')) tags.add('生活');
    if (lower.contains('todo') || lower.contains('やること') || lower.contains('タスク')) tags.add('タスク');
    if (tags.isEmpty) tags.add('メモ');
    return tags.toList();
  }
}
