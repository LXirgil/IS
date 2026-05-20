import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../data/bowling_repository.dart';
import '../models/bowling_meta.dart';
import '../services/location_service.dart';
import '../services/nearby_alleys_service.dart';

/// 近くのボウリング場を地図で表示（OpenStreetMap）
class AlleysMapScreen extends StatefulWidget {
  const AlleysMapScreen({super.key, required this.onChanged});

  final VoidCallback onChanged;

  @override
  State<AlleysMapScreen> createState() => _AlleysMapScreenState();
}

class _AlleysMapScreenState extends State<AlleysMapScreen> {
  final _mapController = MapController();
  LatLng _center = LocationService.fallbackCenter;
  List<NearbyBowlingPlace> _nearby = [];
  NearbyBowlingPlace? _selectedNearby;
  BowlingAlley? _selectedSaved;
  bool _loading = true;
  String? _error;
  int _radiusKm = 8;
  bool _usedGps = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final loc = await LocationService.instance.getCurrentLatLng();
    if (loc != null) {
      _center = loc;
      _usedGps = true;
    }

    await _searchNearby();
    if (mounted) {
      setState(() => _loading = false);
      _mapController.move(_center, 13);
    }
  }

  Future<void> _searchNearby() async {
    try {
      final list = await NearbyAlleysService.instance.searchNearby(
        center: _center,
        radiusMeters: _radiusKm * 1000,
      );
      if (mounted) {
        setState(() {
          _nearby = list;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _nearby = [];
          _error = '$e';
        });
      }
    }
  }

  Future<void> _goToMyLocation() async {
    final loc = await LocationService.instance.getCurrentLatLng();
    if (loc == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('位置情報を取得できません。設定で許可してください。')),
        );
      }
      return;
    }
    setState(() {
      _center = loc;
      _usedGps = true;
    });
    _mapController.move(loc, 14);
    await _searchNearby();
  }

  void _saveNearbyToBookmarks(NearbyBowlingPlace place) {
    final repo = BowlingRepository.instance;
    final existing = repo.alleys.where(
      (a) => a.latitude == place.latitude && a.longitude == place.longitude,
    );
    if (existing.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('すでに登録済みです')));
      return;
    }
    repo.upsertAlley(
      BowlingAlley(
        id: 'alley-${DateTime.now().millisecondsSinceEpoch}',
        name: place.name,
        address: place.address,
        latitude: place.latitude,
        longitude: place.longitude,
        isFavorite: true,
      ),
    );
    widget.onChanged();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('「${place.name}」を登録しました')));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final repo = BowlingRepository.instance;
    final scheme = Theme.of(context).colorScheme;
    final savedWithLoc = repo.alleys.where((a) => a.hasLocation).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('近くのボウリング場'),
        actions: [
          IconButton(icon: const Icon(Icons.my_location), tooltip: '現在地', onPressed: _goToMyLocation),
          PopupMenuButton<int>(
            initialValue: _radiusKm,
            onSelected: (v) async {
              setState(() => _radiusKm = v);
              await _searchNearby();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 3, child: Text('半径 3km')),
              PopupMenuItem(value: 5, child: Text('半径 5km')),
              PopupMenuItem(value: 8, child: Text('半径 8km')),
              PopupMenuItem(value: 15, child: Text('半径 15km')),
            ],
            icon: const Icon(Icons.tune),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 13,
              onTap: (_, __) => setState(() {
                _selectedNearby = null;
                _selectedSaved = null;
              }),
              onPositionChanged: (camera, hasGesture) {
                if (hasGesture) {
                  _center = camera.center;
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.ai_bowling_master',
              ),
              if (_usedGps)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: _center,
                      radius: _radiusKm * 1000,
                      useRadiusInMeter: true,
                      color: scheme.primary.withValues(alpha: 0.08),
                      borderColor: scheme.primary.withValues(alpha: 0.35),
                      borderStrokeWidth: 1.5,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  if (_usedGps)
                    Marker(
                      point: _center,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.my_location, color: Colors.blue, size: 32),
                    ),
                  for (final a in savedWithLoc)
                    Marker(
                      point: LatLng(a.latitude!, a.longitude!),
                      width: 44,
                      height: 44,
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _selectedSaved = a;
                          _selectedNearby = null;
                        }),
                        child: Icon(
                          a.isFavorite ? Icons.star : Icons.sports,
                          color: Colors.amber.shade700,
                          size: 36,
                        ),
                      ),
                    ),
                  for (final p in _nearby)
                    Marker(
                      point: LatLng(p.latitude, p.longitude),
                      width: 40,
                      height: 40,
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _selectedNearby = p;
                          _selectedSaved = null;
                        }),
                        child: Icon(Icons.location_on, color: scheme.primary, size: 38),
                      ),
                    ),
                ],
              ),
            ],
          ),
          if (_loading)
            const ColoredBox(
              color: Color(0x88FFFFFF),
              child: Center(child: CircularProgressIndicator()),
            ),
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Material(
              elevation: 2,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Icon(Icons.map_outlined, size: 20, color: scheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _usedGps ? '現在地から半径 $_radiusKm km · ${_nearby.length} 件' : '地図を移動して「再検索」',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                    TextButton(onPressed: _searchNearby, child: const Text('再検索')),
                  ],
                ),
              ),
            ),
          ),
          if (_error != null)
            Positioned(
              bottom: 120,
              left: 16,
              right: 16,
              child: Material(
                color: scheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(_error!, style: TextStyle(color: scheme.onErrorContainer, fontSize: 12)),
                ),
              ),
            ),
          if (_selectedNearby != null) _PlaceSheet(place: _selectedNearby!, onSave: () => _saveNearbyToBookmarks(_selectedNearby!)),
          if (_selectedSaved != null) _SavedAlleySheet(alley: _selectedSaved!),
          if (!_loading && _nearby.isNotEmpty && _selectedNearby == null && _selectedSaved == null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: _NearbyListPreview(places: _nearby.take(5).toList(), onTap: (p) {
                setState(() => _selectedNearby = p);
                _mapController.move(LatLng(p.latitude, p.longitude), 15);
              }),
            ),
        ],
      ),
    );
  }
}

class _PlaceSheet extends StatelessWidget {
  const _PlaceSheet({required this.place, required this.onSave});

  final NearbyBowlingPlace place;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 16,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(place.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              if (place.address != null) ...[
                const SizedBox(height: 4),
                Text(place.address!, style: Theme.of(context).textTheme.bodySmall),
              ],
              if (place.distanceLabel.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text('約 ${place.distanceLabel}', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
              ],
              const SizedBox(height: 12),
              FilledButton.icon(onPressed: onSave, icon: const Icon(Icons.bookmark_add_outlined), label: const Text('お気に入りに登録')),
            ],
          ),
        ),
      ),
    );
  }
}

class _SavedAlleySheet extends StatelessWidget {
  const _SavedAlleySheet({required this.alley});

  final BowlingAlley alley;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 16,
      child: Card(
        color: Colors.amber.shade50,
        child: ListTile(
          leading: const Icon(Icons.star, color: Colors.amber),
          title: Text(alley.name),
          subtitle: Text(alley.address ?? '登録済みのボウリング場'),
        ),
      ),
    );
  }
}

class _NearbyListPreview extends StatelessWidget {
  const _NearbyListPreview({required this.places, required this.onTap});

  final List<NearbyBowlingPlace> places;
  final ValueChanged<NearbyBowlingPlace> onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('近くのボウリング場', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 4),
            ...places.map(
              (p) => ListTile(
                dense: true,
                title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: Text(p.distanceLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
                onTap: () => onTap(p),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
