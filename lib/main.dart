import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';

import 'services/ai_service.dart';
import 'screens/compose_idea_page.dart';
import 'screens/settings_page.dart';
import 'HomePage.dart';
import 'FirstPage.dart';
import 'SecondPage.dart';

void main() {
  runApp(const IdeaStreamApp());
}

/// アプリ全体の基本設定
class IdeaStreamApp extends StatelessWidget {
  const IdeaStreamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IdeaStream', // 
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
        // cardTheme removed to avoid SDK type mismatch between CardTheme and CardThemeData
        chipTheme: ChipThemeData.fromDefaults(labelStyle: const TextStyle(color: Colors.white), primaryColor: Colors.indigo, secondaryColor: Colors.indigoAccent),
        appBarTheme: const AppBarTheme(centerTitle: true),
      ),
      home: const ListPage(), // S-01 アイデア一覧画面を表示 
    );
  }
}

/// アイデアのデータ構造 (F-03 メタデータ記録に対応) [cite: 13]
class Idea {
  final String title;
  final String date;
  final String type;
  final List<String> tags;
  final String body; // 詳細メモ
  final String? imagePath;
  final String? audioPath;

  Idea({required this.title, required this.date, required this.type, required this.tags, this.body = '', this.imagePath, this.audioPath});

  Map<String, dynamic> toJson() => {
        'title': title,
        'date': date,
        'type': type,
        'tags': tags,
        'body': body,
        'imagePath': imagePath,
        'audioPath': audioPath,
      };

  static Idea fromJson(Map<String, dynamic> m) => Idea(
        title: m['title'] ?? '',
        date: m['date'] ?? '',
        type: m['type'] ?? 'テキスト',
        tags: List<String>.from(m['tags'] ?? []),
        body: m['body'] ?? '',
        imagePath: m['imagePath'],
        audioPath: m['audioPath'],
      );
}

/// S-01 アイデア一覧 (Home) 
class ListPage extends StatefulWidget {
  const ListPage({super.key});

  @override
  State<ListPage> createState() => _ListPageState();
}

class _ListPageState extends State<ListPage> {
  // ダミーのデータリスト (F-04 アイデアカードのUI設計) 
  final List<Idea> _ideas = [
    Idea(title: '新しいアプリのUI案', date: '2026/01/14', type: 'テキスト', tags: ['開発', 'UI'], body: 'モバイル向けの簡単なUI案。カード一覧、FABで入力。'),
    Idea(title: 'ランチのアイデア', date: '2026/01/14', type: '音声', tags: ['生活'], body: '近所のカフェで新しいサンドイッチを試す。'),
  ];
  
  @override
  void initState() {
    super.initState();
    _loadIdeas();
  }
  
  Future<File> _ideasFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/ideas.json');
  }
  
  Future<void> _loadIdeas() async {
    try {
      final f = await _ideasFile();
      if (await f.exists()) {
        final s = await f.readAsString();
        final List<dynamic> arr = json.decode(s);
        setState(() {
          _ideas.clear();
          _ideas.addAll(arr.map((e) => Idea.fromJson(Map<String, dynamic>.from(e))));
        });
      } else {
        await _saveIdeas(); // save initial seeds
      }
    } catch (_) {}
  }
  
  Future<void> _saveIdeas() async {
    try {
      final f = await _ideasFile();
      final arr = _ideas.map((e) => e.toJson()).toList();
      await f.writeAsString(json.encode(arr));
    } catch (_) {}
  }

  String _ext(String p) {
    final i = p.lastIndexOf('.');
    return i != -1 ? p.substring(i) : '';
  }

  // S-02 入力ソース選択 (FABタップ時に表示されるモーダル) 
  void _showSourceSelection() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.text_fields),
              title: const Text('テキスト入力'),
              onTap: () {
                Navigator.pop(context);
                _openTextInput();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('画像入力'),
              onTap: () {
                Navigator.pop(context);
                _openImageInput();
              },
            ),
            ListTile(
              leading: const Icon(Icons.mic),
              title: const Text('音声録音'),
              onTap: () {
                Navigator.pop(context);
                _openAudioInput();
              },
            ),
          ],
        ),
      ),
    );
  }

  // テキスト入力用ダイアログを開く
  Future<void> _openTextInput() async {
    // フルスクリーンの作成ページへ遷移して結果のMapを受け取る
    final res = await Navigator.of(context).push(MaterialPageRoute(builder: (c) => const ComposeIdeaPage()));
    if (res is Map<String, dynamic>) {
      final title = res['title'] ?? '';
      final body = res['body'] ?? '';
      final type = res['type'] ?? 'テキスト';
      final tags = List<String>.from(res['tags'] ?? []);
      final imagePath = res['imagePath'];
      final audioPath = res['audioPath'];
      if (!mounted) return;
      setState(() {
        _ideas.insert(0, Idea(title: title, date: _formatNow(), type: type, tags: tags, body: body, imagePath: imagePath, audioPath: audioPath));
      });
      await _saveIdeas();
    }
  }

  // 画像入力（プレースホルダ）：今はタイトルだけ受け取るダイアログ
  void _openImageInput() {
    // まず画像ファイルを選択
    () async {
      final result = await FilePicker.platform.pickFiles(type: FileType.image);
      if (result == null || result.files.isEmpty) return;
      final path = result.files.first.path;
      if (path == null) return;
      if (!mounted) return;

      final TextEditingController titleController = TextEditingController();
      final TextEditingController bodyController = TextEditingController();
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('画像入力'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 120, child: Image.file(File(path), fit: BoxFit.contain)),
              const SizedBox(height: 8),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(hintText: 'タイトル（省略可）'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: bodyController,
                maxLines: 4,
                decoration: const InputDecoration(hintText: '画像の説明やメモ（省略可）'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('キャンセル')),
            ElevatedButton(
              onPressed: () async {
                final nav = Navigator.of(context);
                final titleText = titleController.text.trim();
                final bodyText = bodyController.text.trim();
                final tags = await AiService.instance.extractTags('$titleText\n$bodyText');
                // copy image into app documents to persist
                final dir = await getApplicationDocumentsDirectory();
                final target = '${dir.path}/img_${DateTime.now().millisecondsSinceEpoch}${_ext(path)}';
                String savedPath = path;
                try {
                  await File(path).copy(target);
                  savedPath = target;
                } catch (_) {}
                setState(() {
                  _ideas.insert(0, Idea(title: titleText.isEmpty ? '画像アイデア' : titleText, date: _formatNow(), type: '画像', tags: tags, body: bodyText, imagePath: savedPath));
                });
                await _saveIdeas();
                nav.pop();
              },
              child: const Text('保存'),
            ),
          ],
        ),
      );
    }();
  }

  // 音声入力（プレースホルダ）：今はタイトルだけ受け取るダイアログ
  void _openAudioInput() {
    // 音声録音用UIをモーダルで表示（簡易実装: 一時ファイルを作成して保存）
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        bool isRecording = false;
        String? recordedPath;
        final TextEditingController titleController = TextEditingController();
        final TextEditingController bodyController = TextEditingController();

        return StatefulBuilder(builder: (context, setModalState) {
          Future<void> startRecording() async {
            final tmp = await getTemporaryDirectory();
            final p = '${tmp.path}/rec_${DateTime.now().millisecondsSinceEpoch}.m4a';
            try {
              await File(p).writeAsBytes([]);
            } catch (_) {}
            setModalState(() {
              isRecording = true;
              recordedPath = p;
            });
          }

          Future<void> stopRecording() async {
            if (!isRecording) return;
            setModalState(() {
              isRecording = false;
            });
          }

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Wrap(
              children: [
                ListTile(title: const Text('音声入力')),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            iconSize: 48,
                            icon: Icon(isRecording ? Icons.mic : Icons.mic_none, color: isRecording ? Colors.red : null),
                            onPressed: () async {
                              if (isRecording) {
                                await stopRecording();
                              } else {
                                await startRecording();
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(isRecording ? '録音中... タップで停止' : (recordedPath == null ? '未録音' : '録音完了')),
                      const SizedBox(height: 12),
                      TextField(controller: titleController, decoration: const InputDecoration(hintText: 'タイトル（省略可）')),
                      const SizedBox(height: 8),
                      TextField(controller: bodyController, maxLines: 3, decoration: const InputDecoration(hintText: 'メモ（省略可）')),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(onPressed: () async {
                            final nav = Navigator.of(context);
                            // キャンセル: 録音停止 + 一時ファイル削除
                            if (isRecording) await stopRecording();
                            if (recordedPath != null) {
                              try { await File(recordedPath!).delete(); } catch (_) {}
                            }
                            nav.pop();
                          }, child: const Text('キャンセル')),
                          const SizedBox(width: 8),
                          ElevatedButton(onPressed: () async {
                            final nav = Navigator.of(context);
                            if (isRecording) await stopRecording();
                            if (recordedPath == null) return; // 録音がない場合保存しない
                            final titleText = titleController.text.trim();
                            final bodyText = bodyController.text.trim();
                            final tags = await AiService.instance.extractTags('$titleText\n$bodyText');
                            // move audio to documents for persistence
                            String? finalPath;
                            try {
                              final dir = await getApplicationDocumentsDirectory();
                              final dest = '${dir.path}/rec_${DateTime.now().millisecondsSinceEpoch}.m4a';
                              if (recordedPath != null) await File(recordedPath!).copy(dest);
                              finalPath = dest;
                            } catch (_) {
                              finalPath = recordedPath;
                            }
                            setState(() {
                              _ideas.insert(0, Idea(title: titleText.isEmpty ? '音声アイデア' : titleText, date: _formatNow(), type: '音声', tags: tags, body: bodyText, audioPath: finalPath));
                            });
                            await _saveIdeas();
                            nav.pop();
                          }, child: const Text('保存')),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  String _formatNow() {
    final now = DateTime.now();
    return '${now.year}/${now.month.toString().padLeft(2,'0')}/${now.day.toString().padLeft(2,'0')} ${now.hour.toString().padLeft(2,'0')}:${now.minute.toString().padLeft(2,'0')}' ;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(child: Text('IdeaStream', style: TextStyle(fontSize: 20))),
            ListTile(
              leading: const Icon(Icons.note_add),
              title: const Text('アイデア作成'),
              onTap: () {
                Navigator.of(context).pop();
                _openTextInput();
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('設定'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute(builder: (c) => const SettingsPage()));
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: const Text('IdeaStream'), // 
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () async {
              final nav = Navigator.of(context);
              final Idea? selected = await showSearch<Idea?>(
                context: context,
                delegate: IdeaSearchDelegate(_ideas),
              );
              if (!mounted) return;
              if (selected != null) {
                nav.push(MaterialPageRoute(builder: (c) => DetailPage(idea: selected)));
              }
            },
          ), // F-05 検索バーのUI [cite: 17]
        ],
      ),
      // F-04 カード形式の一覧表示。上部に画面遷移ボタンを追加（ハンバーガーメニューを使わない）
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (c) => HomePage())), icon: const Icon(Icons.home), label: const Text('Home')),
                const SizedBox(width: 8),
                ElevatedButton.icon(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (c) => FirstPage())), icon: const Icon(Icons.filter_1), label: const Text('First')),
                const SizedBox(width: 8),
                ElevatedButton.icon(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (c) => SecondPage())), icon: const Icon(Icons.filter_2), label: const Text('Second')),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _ideas.length,
              itemBuilder: (context, index) {
                final item = _ideas[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(item.title),
                    subtitle: Text('${item.date} (${item.type})'),
                    trailing: Wrap(
                      spacing: 6,
                      children: item.tags.map((t) => Chip(
                        label: Text(t, style: const TextStyle(fontSize: 12, color: Colors.white)),
                        backgroundColor: _tagColor(t),
                        visualDensity: VisualDensity.compact,
                      )).toList(),
                    ),
                    onTap: () {
                      // S-03 アイデア詳細への遷移 
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => DetailPage(
                          idea: item,
                          onDelete: () {
                            setState(() {
                              _ideas.removeAt(index);
                            });
                            _saveIdeas();
                          },
                        )),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      // S-01 FAB (+ボタン) 
      floatingActionButton: FloatingActionButton(
        onPressed: _showSourceSelection,
        child: const Icon(Icons.add),
      ),
    );
  }

  Color _tagColor(String tag) {
    final lower = tag.toLowerCase();
    if (lower.contains('開発')) return Colors.indigo;
    if (lower.contains('生活')) return Colors.green;
    if (lower.contains('予算')) return Colors.orange;
    if (lower.contains('会議')) return Colors.deepPurple;
    if (lower.contains('タスク')) return Colors.teal;
    return Colors.grey.shade600;
  }

}

class IdeaSearchDelegate extends SearchDelegate<Idea?> {
  final List<Idea> ideas;
  IdeaSearchDelegate(this.ideas) : super(searchFieldLabel: 'タイトル・本文・タグを検索');

  List<Idea> _filter(String q) {
    final ql = q.toLowerCase();
    return ideas.where((i) => i.title.toLowerCase().contains(ql) || i.body.toLowerCase().contains(ql) || i.tags.join(' ').toLowerCase().contains(ql)).toList();
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = _filter(query);
    if (results.isEmpty) return Center(child: Text('一致するアイデアがありません。'));
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final it = results[index];
        return ListTile(
          title: Text(it.title),
          subtitle: Text(it.date),
          onTap: () => close(context, it),
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) return Center(child: Text('検索ワードを入力してください'));
    final results = _filter(query);
    return ListView(
      children: results.map((it) => ListTile(
        title: Text(it.title),
        subtitle: Text(it.type),
        onTap: () => close(context, it),
      )).toList(),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) => [IconButton(icon: const Icon(Icons.clear), onPressed: () => query = '')];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, null));

}
/// S-03 アイデア詳細 
class DetailPage extends StatelessWidget {
  final Idea idea;
  final VoidCallback? onDelete;
  const DetailPage({super.key, required this.idea, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('アイデア詳細'), actions: [
        IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () async {
            final nav = Navigator.of(context);
            final ok = await showDialog<bool>(
              context: context,
              builder: (c) => AlertDialog(
                title: const Text('削除の確認'),
                content: const Text('このアイデアを削除しますか？'),
                actions: [
                  TextButton(onPressed: () => Navigator.of(c).pop(false), child: const Text('キャンセル')),
                  ElevatedButton(onPressed: () => Navigator.of(c).pop(true), child: const Text('削除')),
                ],
              ),
            );
            if (ok == true) {
              try { if (idea.imagePath != null) await File(idea.imagePath!).delete(); } catch (_) {}
              try { if (idea.audioPath != null) await File(idea.audioPath!).delete(); } catch (_) {}
              if (onDelete != null) onDelete!();
              nav.pop();
            }
          },
        ),
      ]), // [cite: 18]
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(idea.title, style: Theme.of(context).textTheme.headlineSmall), // [cite: 18]
            const SizedBox(height: 10),
            Text('作成日: ${idea.date}'),
            Text('形式: ${idea.type}'),
            const Divider(height: 40),
            Text('【本文/内容】\n${idea.body}'),
            const SizedBox(height: 12),
            if (idea.imagePath != null) ...[
              const SizedBox(height: 8),
              SizedBox(height: 160, child: Image.file(File(idea.imagePath!), fit: BoxFit.contain)),
            ],
            if (idea.audioPath != null) ...[
              const SizedBox(height: 8),
              Row(children: [Icon(Icons.audiotrack), const SizedBox(width: 8), Expanded(child: Text('録音ファイル: ${idea.audioPath}'))]),
            ],
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              children: idea.tags.map((t) => Chip(label: Text(t, style: const TextStyle(color: Colors.white)), backgroundColor: tagColorGlobal(t))).toList(), // [cite: 18]
            ),
          ],
        ),
      ),
    );
  }
}

Color tagColorGlobal(String tag) {
  final lower = tag.toLowerCase();
  if (lower.contains('開発')) return Colors.indigo;
  if (lower.contains('生活')) return Colors.green;
  if (lower.contains('予算')) return Colors.orange;
  if (lower.contains('会議')) return Colors.deepPurple;
  if (lower.contains('タスク')) return Colors.teal;
  return Colors.grey.shade600;
}