import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../data/bowling_repository.dart';
import '../models/bowling_meta.dart';
import '../services/location_service.dart';
import '../services/nearby_alleys_service.dart';
import '../utils/google_maps_support.dart';
import '../utils/map_marker_factory.dart';

/// 近くのボウリング場を Google Maps で表示
class AlleysMapScreen extends StatefulWidget {
  const AlleysMapScreen({super.key, required this.onChanged});

  final VoidCallback onChanged;

  @override
  State<AlleysMapScreen> createState() => _AlleysMapScreenState();
}

class _AlleysMapScreenState extends State<AlleysMapScreen> {
  GoogleMapController? _mapController;
  ll.LatLng _center = LocationService.fallbackCenter;
  ll.LatLng? _cameraCenter;

  List<NearbyBowlingPlace> _nearby = [];
  NearbyBowlingPlace? _selectedNearby;
  BowlingAlley? _selectedSaved;

  Set<Marker> _markers = {};
  Set<Circle> _circles = {};

  bool _loading = true;
  String? _error;
  int _radiusKm = 8;
  bool _usedGps = false;
  bool _markersReady = false;

  @override
  void initState() {
    super.initState();
    if (isGoogleMapsSupported) {
      _init();
    } else {
      _loading = false;
    }
  }

  LatLng _toGoogle(ll.LatLng p) => LatLng(p.latitude, p.longitude);

  Future<void> _init() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final loc = await LocationService.instance.getCurrentLatLng();
    if (loc != null) {
      _center = loc;
      _cameraCenter = loc;
      _usedGps = true;
    } else {
      _cameraCenter = _center;
    }

    await _searchNearby();
    await _buildMarkers();

    if (mounted) {
      setState(() => _loading = false);
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _toGoogle(_center), zoom: _usedGps ? 14 : 12),
        ),
      );
    }
  }

  Future<void> _buildMarkers() async {
    if (!isGoogleMapsSupported) return;

    final bowlingIcon = await MapMarkerFactory.bowlingAlley();
    final savedIcon = await MapMarkerFactory.savedAlley();
    final repo = BowlingRepository.instance;
    final markers = <Marker>{};

    for (final p in _nearby) {
      markers.add(
        Marker(
          markerId: MarkerId('nearby_${p.osmId}'),
          position: LatLng(p.latitude, p.longitude),
          icon: bowlingIcon,
          anchor: const Offset(0.5, 1.0),
          infoWindow: InfoWindow(
            title: p.name,
            snippet: [if (p.address != null) p.address, p.distanceLabel].where((s) => s != null && s.isNotEmpty).join(' · '),
            onTap: () => setState(() {
              _selectedNearby = p;
              _selectedSaved = null;
            }),
          ),
          onTap: () => setState(() {
            _selectedNearby = p;
            _selectedSaved = null;
          }),
        ),
      );
    }

    for (final a in repo.alleys.where((a) => a.hasLocation)) {
      markers.add(
        Marker(
          markerId: MarkerId('saved_${a.id}'),
          position: LatLng(a.latitude!, a.longitude!),
          icon: savedIcon,
          anchor: const Offset(0.5, 1.0),
          infoWindow: InfoWindow(
            title: '★ ${a.name}',
            snippet: a.address ?? '登録済み',
            onTap: () => setState(() {
              _selectedSaved = a;
              _selectedNearby = null;
            }),
          ),
          onTap: () => setState(() {
            _selectedSaved = a;
            _selectedNearby = null;
          }),
        ),
      );
    }

    final circles = <Circle>{};
    if (_usedGps) {
      circles.add(
        Circle(
          circleId: const CircleId('search_radius'),
          center: _toGoogle(_center),
          radius: _radiusKm * 1000.0,
          fillColor: const Color(0xFF3949AB).withValues(alpha: 0.08),
          strokeColor: const Color(0xFF3949AB).withValues(alpha: 0.35),
          strokeWidth: 2,
        ),
      );
    }

    if (mounted) {
      setState(() {
        _markers = markers;
        _circles = circles;
        _markersReady = true;
      });
    }
  }

  Future<void> _searchNearby() async {
    final searchCenter = _cameraCenter ?? _center;
    try {
      final list = await NearbyAlleysService.instance.searchNearby(
        center: searchCenter,
        radiusMeters: _radiusKm * 1000,
      );
      if (mounted) {
        setState(() {
          _nearby = list;
          _error = null;
        });
        await _buildMarkers();
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
      _cameraCenter = loc;
      _usedGps = true;
    });
    await _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(CameraPosition(target: _toGoogle(loc), zoom: 15)),
    );
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
    _buildMarkers();
  }

  @override
  Widget build(BuildContext context) {
    if (!isGoogleMapsSupported) {
      return Scaffold(
        appBar: AppBar(title: const Text('近くのボウリング場')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Google Maps は Android / iOS / Web で利用できます。\n'
              'android/local.properties に GOOGLE_MAPS_API_KEY を設定してください。',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('近くのボウリング場'),
        actions: [
          IconButton(icon: const Icon(Icons.my_location), tooltip: '現在地へ', onPressed: _goToMyLocation),
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
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _toGoogle(_center),
              zoom: _usedGps ? 14 : 12,
            ),
            onMapCreated: (c) => _mapController = c,
            markers: _markers,
            circles: _circles,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            compassEnabled: true,
            mapToolbarEnabled: true,
            zoomControlsEnabled: false,
            buildingsEnabled: true,
            mapType: MapType.normal,
            padding: const EdgeInsets.only(top: 72, bottom: 100),
            onCameraMove: (pos) => _cameraCenter = ll.LatLng(pos.target.latitude, pos.target.longitude),
            onTap: (_) => setState(() {
              _selectedNearby = null;
              _selectedSaved = null;
            }),
          ),
          if (_loading || !_markersReady)
            const ColoredBox(
              color: Color(0x99FFFFFF),
              child: Center(child: CircularProgressIndicator()),
            ),
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Material(
              elevation: 3,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Icon(Icons.sports_score, size: 22, color: scheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _usedGps ? '現在地（青点）から半径 $_radiusKm km' : '地図を動かして再検索',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                          Text(
                            '${_nearby.length} 件 · ピン付きマーカーがボウリング場',
                            style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    FilledButton.tonal(onPressed: _searchNearby, child: const Text('再検索')),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 12,
            bottom: 100,
            child: Material(
              elevation: 2,
              borderRadius: BorderRadius.circular(10),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 14, height: 14, decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    const Text('現在地', style: TextStyle(fontSize: 11)),
                    const SizedBox(width: 12),
                    Icon(Icons.sports_score, size: 16, color: scheme.primary),
                    const SizedBox(width: 4),
                    const Text('ボウリング場', style: TextStyle(fontSize: 11)),
                    const SizedBox(width: 12),
                    Icon(Icons.star, size: 16, color: Colors.amber.shade700),
                    const SizedBox(width: 4),
                    const Text('登録済', style: TextStyle(fontSize: 11)),
                  ],
                ),
              ),
            ),
          ),
          if (_error != null)
            Positioned(
              bottom: 200,
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
          if (_selectedNearby != null)
            _PlaceSheet(place: _selectedNearby!, onSave: () => _saveNearbyToBookmarks(_selectedNearby!)),
          if (_selectedSaved != null) _SavedAlleySheet(alley: _selectedSaved!),
          if (!_loading && _nearby.isNotEmpty && _selectedNearby == null && _selectedSaved == null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: _NearbyListPreview(
                places: _nearby.take(4).toList(),
                onTap: (p) {
                  setState(() => _selectedNearby = p);
                  _mapController?.animateCamera(
                    CameraUpdate.newLatLngZoom(LatLng(p.latitude, p.longitude), 16),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
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
      bottom: 88,
      child: Card(
        elevation: 6,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.sports_score, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(child: Text(place.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                ],
              ),
              if (place.address != null) ...[
                const SizedBox(height: 4),
                Text(place.address!, style: Theme.of(context).textTheme.bodySmall),
              ],
              if (place.distanceLabel.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text('約 ${place.distanceLabel}', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600)),
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
      bottom: 88,
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
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: places
              .map(
                (p) => ListTile(
                  dense: true,
                  leading: Icon(Icons.sports_score, color: Theme.of(context).colorScheme.primary, size: 22),
                  title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: Text(p.distanceLabel, style: const TextStyle(fontWeight: FontWeight.w700)),
                  onTap: () => onTap(p),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
