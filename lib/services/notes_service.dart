import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../db/db_helper.dart';
import '../model/note.dart';
import 'alarm_service.dart';

class NotesService {
  NotesService._();
  static final NotesService instance = NotesService._();

  final _db = DbHelper();

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  final StreamController<List<Note>> _localNotesController =
      StreamController<List<Note>>.broadcast();

  /// Watch notes (local or Firebase)
  Stream<List<Note>> watchNotes({String? userId}) {
    final uid = userId ?? _uid;

    if (uid == null) {
      _loadLocalNotes();
      return _localNotesController.stream;
    }

    final col = _notesCollection(uid);
    return col
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  /// Firestore collection reference with converter
  CollectionReference<Note> _notesCollection(String userId) =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notes')
          .withConverter<Note>(
            fromFirestore: (snapshot, _) => Note.fromFirestore(snapshot),
            toFirestore: (note, _) => note.toFirestoreMap(),
          );

  /// Load local notes into stream
  Future<void> _loadLocalNotes() async {
    final notes = await getLocalNotes();
    _localNotesController.add(notes);
  }

  /// Get local notes from SQLite
  Future<List<Note>> getLocalNotes() async {
    final rows = await _db.getNotes();
    return rows
        .map((r) => Note(
              id: r['id'].toString(),
              title: r['title'],
              content: r['content'],
              createdAt:
                  DateTime.tryParse(r['createdAt'] ?? '') ?? DateTime.now(),
              updatedAt:
                  DateTime.tryParse(r['updatedAt'] ?? '') ?? DateTime.now(),
              reminderTime: r['reminderTime'] != null
                  ? DateTime.tryParse(r['reminderTime'])
                  : null,
            ))
        .toList();
  }

  /// Add or update note (local or Firebase)
  Future<void> addOrUpdateNote(Note note, {String? userId, Note? oldNote}) async {
    final uid = userId ?? _uid;

    // Stop previous alarm if reminder changed or removed
    if (oldNote != null) {
      final oldTime = oldNote.reminderTime?.millisecondsSinceEpoch;
      final newTime = note.reminderTime?.millisecondsSinceEpoch;
      if (oldTime != newTime) {
        await AlarmService.stopAlarm(oldNote.id.hashCode);
      }
    }

    // Schedule new alarm if set (auto-stop after 1 minute)
    if (note.reminderTime != null) {
      await AlarmService.scheduleAlarm(
        id: note.id.hashCode,
        dateTime: note.reminderTime!,
        notificationTitle: "Reminder: ${note.title}",
        notificationBody: note.content,
        assetPath: 'assets/alarm.mp3',
        loopAudio: true,
        vibrate: true,
        volume: 1.0,
        autoStopDuration: const Duration(minutes: 1), // <-- auto-stop
      );
    } else {
      await AlarmService.stopAlarm(note.id.hashCode);
    }

    // Local DB
    if (uid == null) {
      final row = {
        'id': note.id.isEmpty ? null : int.tryParse(note.id),
        'title': note.title,
        'content': note.content,
        'createdAt': note.createdAt.toIso8601String(),
        'updatedAt': note.updatedAt.toIso8601String(),
        'reminderTime': note.reminderTime?.toIso8601String(),
      };

      if (note.id.isEmpty) {
        await _db.insertNote(row);
      } else {
        await _db.updateNote(row);
      }

      await _loadLocalNotes();
      return;
    }

    // Firestore
    final col = _notesCollection(uid);
    if (note.id.isEmpty) {
      final doc = await col.add(note);
      note = note.copyWith(id: doc.id);
      await col.doc(doc.id).set(note, SetOptions(merge: true));
    } else {
      await col.doc(note.id).set(note, SetOptions(merge: true));
    }
  }

  /// Delete note (local or Firebase)
  Future<void> deleteNote(String id, {String? userId}) async {
    await AlarmService.stopAlarm(id.hashCode);

    final uid = userId ?? _uid;
    if (uid == null) {
      await _db.deleteNote(int.parse(id));
      await _loadLocalNotes();
      return;
    }

    final col = _notesCollection(uid);
    await col.doc(id).delete();
  }

  void dispose() {
    _localNotesController.close();
  }
}
