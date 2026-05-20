import 'package:flutter/material.dart';

import '../data/bowling_repository.dart';
import '../models/bowling_meta.dart';
import '../services/geocoding_service.dart';
import 'alleys_map_screen.dart';

/// ボウリング場ブックマーク（地図の代わりにリスト管理 — オリジナルUI）
class AlleysScreen extends StatefulWidget {
  const AlleysScreen({super.key, required this.onChanged});

  final VoidCallback onChanged;

  @override
  State<AlleysScreen> createState() => _AlleysScreenState();
}

class _AlleysScreenState extends State<AlleysScreen> {
  Future<void> _add() async {
    final name = TextEditingController();
    final address = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('ボウリング場を追加'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: '名前 *')),
            TextField(controller: address, decoration: const InputDecoration(labelText: '住所・メモ')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('キャンセル')),
          FilledButton(onPressed: () => Navigator.pop(c, name.text.trim().isNotEmpty), child: const Text('保存')),
        ],
      ),
    );
    if (ok != true) return;

    var latLng = await GeocodingService.instance.geocode(address.text.trim());
    if (latLng == null && address.text.trim().isNotEmpty) {
      latLng = await GeocodingService.instance.geocode('${name.text.trim()} ${address.text.trim()}');
    }

    BowlingRepository.instance.upsertAlley(
      BowlingAlley(
        id: 'alley-${DateTime.now().millisecondsSinceEpoch}',
        name: name.text.trim(),
        address: address.text.trim().isEmpty ? null : address.text.trim(),
        latitude: latLng?.latitude,
        longitude: latLng?.longitude,
      ),
    );
    widget.onChanged();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final repo = BowlingRepository.instance;
    final sorted = [...repo.alleys]..sort((a, b) {
        if (a.isFavorite != b.isFavorite) return a.isFavorite ? -1 : 1;
        return a.name.compareTo(b.name);
      });

    return Scaffold(
      appBar: AppBar(
        title: const Text('ボウリング場'),
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined),
            tooltip: '地図で探す',
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => AlleysMapScreen(onChanged: widget.onChanged)),
              );
              setState(() {});
            },
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'map',
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => AlleysMapScreen(onChanged: widget.onChanged)),
              );
              setState(() {});
            },
            child: const Icon(Icons.map),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(onPressed: _add, child: const Icon(Icons.add)),
        ],
      ),
      body: sorted.isEmpty
          ? const Center(child: Text('お気に入りのボウリング場を登録しましょう'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: sorted.length,
              itemBuilder: (context, i) {
                final a = sorted[i];
                final games = repo.rounds.where((r) => r.alleyId == a.id && r.hasScoreData).length;
                return Card(
                  child: ListTile(
                    leading: Icon(a.isFavorite ? Icons.star : Icons.place_outlined, color: a.isFavorite ? Colors.amber : null),
                    title: Text(a.name),
                    subtitle: Text([if (a.address != null) a.address, '$games ゲーム'].join(' · ')),
                    trailing: IconButton(
                      icon: Icon(a.isFavorite ? Icons.star : Icons.star_border),
                      onPressed: () {
                        a.isFavorite = !a.isFavorite;
                        repo.upsertAlley(a);
                        widget.onChanged();
                        setState(() {});
                      },
                    ),
                    onLongPress: () async {
                      final del = await showDialog<bool>(
                        context: context,
                        builder: (c) => AlertDialog(
                          title: Text('${a.name} を削除？'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('キャンセル')),
                            FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('削除')),
                          ],
                        ),
                      );
                      if (del == true) {
                        repo.deleteAlley(a.id);
                        widget.onChanged();
                        setState(() {});
                      }
                    },
                  ),
                );
              },
            ),
    );
  }
}
