import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/bowling_repository.dart';
import '../models/bowling.dart';

/// Simple Firestore-based sync service for RoundData.
class CloudSyncService {
  CloudSyncService._private();
  static final CloudSyncService instance = CloudSyncService._private();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  StreamSubscription<User?>? _authSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _remoteSub;

  void start() {
    // Listen to auth changes and start/stop sync accordingly
    _authSub = _auth.authStateChanges().listen((user) async {
      await _stopRemoteListener();
      if (user != null) {
        await _initialSyncForUser(user.uid);
        _startRemoteListener(user.uid);
      }
    });
  }

  Future<void> dispose() async {
    await _authSub?.cancel();
    await _stopRemoteListener();
  }

  Future<void> _initialSyncForUser(String uid) async {
    final coll = _db.collection('users').doc(uid).collection('rounds');
    try {
      final snap = await coll.get();
      final repo = BowlingRepository.instance;
      // Merge remote rounds into local repository (add missing)
      final remoteIds = <String>{};
      for (final doc in snap.docs) {
        final data = doc.data();
        try {
          final r = RoundData.fromJson(Map<String, dynamic>.from(data as Map<String, dynamic>));
          repo.upsertRound(r);
          remoteIds.add(r.id);
        } catch (_) {
          // ignore individual parse errors
        }
      }

      // Upload local rounds that do not exist remotely
      for (final local in repo.rounds) {
        if (!remoteIds.contains(local.id)) {
          await coll.doc(local.id).set(local.toJson());
        }
      }
    } catch (e) {
      // ignore for now; could log
    }
  }

  void _startRemoteListener(String uid) {
    final coll = _db.collection('users').doc(uid).collection('rounds');
    _remoteSub = coll.snapshots().listen((snap) {
      final repo = BowlingRepository.instance;
      for (final change in snap.docChanges) {
        final data = change.doc.data();
        try {
          final r = RoundData.fromJson(Map<String, dynamic>.from(data as Map<String, dynamic>));
          repo.upsertRound(r);
        } catch (_) {
          // ignore
        }
      }
    });
  }

  Future<void> _stopRemoteListener() async {
    await _remoteSub?.cancel();
    _remoteSub = null;
  }

  /// Manual sync: push local rounds and pull remote rounds once.
  Future<void> manualSync() async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Not signed in');
    final uid = user.uid;
    final coll = _db.collection('users').doc(uid).collection('rounds');
    final repo = BowlingRepository.instance;
    try {
      final snap = await coll.get();
      final remoteIds = <String>{};
      for (final doc in snap.docs) {
        final data = doc.data();
        try {
          final r = RoundData.fromJson(Map<String, dynamic>.from(data as Map<String, dynamic>));
          repo.upsertRound(r);
          remoteIds.add(r.id);
        } catch (_) {}
      }
      for (final local in repo.rounds) {
        if (!remoteIds.contains(local.id)) {
          await coll.doc(local.id).set(local.toJson());
        }
      }
    } catch (e) {
      rethrow;
    }
  }
}
