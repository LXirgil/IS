import 'package:flutter/material.dart';
import 'screens/compose_idea_page.dart';

class FirstPage extends StatelessWidget {
  FirstPage({Key? key}) : super(key: key);

  final List<Map<String, String>> templates = [
    {'title': 'UXアイデア', 'body': '誰のためのUXか？\n課題は？\n提案内容：\n期待される効果：'},
    {'title': '改善提案', 'body': '現状：\n問題点：\n改善案：\nリスク：'},
    {'title': 'ミーティングメモ', 'body': '参加者：\n議題：\n決定事項：\nアクション：'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('テンプレートギャラリー (FirstPage)')),
      body: ListView.builder(
        padding: const EdgeInsets.all(12.0),
        itemCount: templates.length,
        itemBuilder: (context, index) {
          final t = templates[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: ListTile(
              title: Text(t['title'] ?? ''),
              subtitle: Text((t['body'] ?? '').split('\n').first),
              trailing: ElevatedButton(
                child: const Text('使う'),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (c) => ComposeIdeaPage(initialTitle: t['title'], initialBody: t['body'])));
                },
              ),
            ),
          );
        },
      ),
    );
  }
}