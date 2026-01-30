import 'package:flutter/material.dart';
import '../data/store.dart';
import '../models/note.dart';
import 'compose_page.dart';
import 'detail_page.dart';

class ListPage extends StatefulWidget {
  const ListPage({Key? key}) : super(key: key);

  @override
  State<ListPage> createState() => _ListPageState();
}

class _ListPageState extends State<ListPage> {
  List<Note> notes = [];

  @override
  void initState() {
    super.initState();
    notes = Store.instance.getNotes();
  }

  Future<void> _openCompose() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const ComposePage()),
    );
    if (result == true) {
      setState(() {
        notes = Store.instance.getNotes();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('アイデアメモ（デモ）')),
      body: notes.isEmpty
          ? const Center(child: Text('まだメモがありません。右下の＋で追加してください。'))
          : ListView.builder(
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final n = notes[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    title: Text(n.title.isEmpty ? '(無題)' : n.title),
                    subtitle: Text(n.body, maxLines: 2, overflow: TextOverflow.ellipsis),
                    trailing: Wrap(
                      spacing: 6,
                      children: [
                        if (n.hasImage) const Icon(Icons.image, size: 18),
                        if (n.hasAudio) const Icon(Icons.mic, size: 18),
                      ],
                    ),
                    onTap: () async {
                      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => DetailPage(note: n)));
                      setState(() {
                        notes = Store.instance.getNotes();
                      });
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCompose,
        child: const Icon(Icons.add),
      ),
    );
  }
}
