import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../data/bowling_repository.dart';
import '../models/bowling.dart';

/// Simple Firestore-based sync service for RoundData.
class CloudSyncService {
  CloudSyncService._private();
  static final CloudSyncService instance = CloudSyncService._private();

  Map<String, dynamic> _ensureMap(Object? data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return <String, dynamic>{};
  }

  FirebaseAuth? _auth;
  FirebaseFirestore? _db;

  FirebaseAuth get _firebaseAuth {
    if (!Firebase.apps.isNotEmpty) throw StateError('Firebase not initialized');
    return _auth ??= FirebaseAuth.instance;
  }

  FirebaseFirestore get _firebaseFirestore {
    if (!Firebase.apps.isNotEmpty) throw StateError('Firebase not initialized');
    return _db ??= FirebaseFirestore.instance;
  }

  StreamSubscription<User?>? _authSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _remoteSub;

  void start() {
    // Only start if Firebase is initialized.
    if (!Firebase.apps.isNotEmpty) return;
    // Listen to auth changes and start/stop sync accordingly
    _authSub = _firebaseAuth.authStateChanges().listen((user) async {
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
    final coll = _firebaseFirestore.collection('users').doc(uid).collection('rounds');
    try {
      final snap = await coll.get();
      final repo = BowlingRepository.instance;
      // Merge remote rounds into local repository (add missing)
      final remoteIds = <String>{};
      for (final doc in snap.docs) {
        final data = doc.data();
        try {
          final r = RoundData.fromJson(_ensureMap(data));
          await repo.upsertRound(r);
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
    final coll = _firebaseFirestore.collection('users').doc(uid).collection('rounds');
    _remoteSub = coll.snapshots().listen((snap) async {
      final repo = BowlingRepository.instance;
      for (final change in snap.docChanges) {
        final data = change.doc.data();
        try {
          final r = RoundData.fromJson(_ensureMap(data));
          await repo.upsertRound(r);
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
    if (!Firebase.apps.isNotEmpty) throw StateError('Firebase not initialized');
    final user = _firebaseAuth.currentUser;
    if (user == null) throw StateError('Not signed in');
    final uid = user.uid;
    final coll = _firebaseFirestore.collection('users').doc(uid).collection('rounds');
    final repo = BowlingRepository.instance;
    try {
      final snap = await coll.get();
      final remoteIds = <String>{};
      for (final doc in snap.docs) {
        final data = doc.data();
        try {
          final r = RoundData.fromJson(_ensureMap(data));
          await repo.upsertRound(r);
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
