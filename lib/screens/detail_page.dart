import 'package:flutter/material.dart';
import '../models/note.dart';

class DetailPage extends StatelessWidget {
  final Note note;
  const DetailPage({super.key, required this.note});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('メモ詳細')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(note.title.isEmpty ? '(無題)' : note.title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: note.tags.map((t) => Chip(label: Text('#$t'))).toList(),
              ),
              const SizedBox(height: 12),
              Text(note.body),
              const SizedBox(height: 12),
              if (note.hasImage) Card(child: Padding(padding: const EdgeInsets.all(16), child: Row(children: const [Icon(Icons.image), SizedBox(width: 8), Text('写真が添付されています（デモ表示）')]))),
              if (note.hasAudio) Card(child: Padding(padding: const EdgeInsets.all(16), child: Row(children: const [Icon(Icons.mic), SizedBox(width: 8), Text('音声メモが添付されています（デモ表示）')]))),
              const SizedBox(height: 24),
              Text('作成: ${note.createdAt}'),
            ],
          ),
        ),
      ),
    );
  }
}
