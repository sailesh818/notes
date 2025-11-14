import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:notes_todo/db/db_helper.dart';
import '../model/note.dart';

class NotesService {
  NotesService._();
  static final NotesService instance = NotesService._();

  final _db = DbHelper();

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // StreamController for local notes
  final StreamController<List<Note>> _localNotesController =
      StreamController<List<Note>>.broadcast();

  /// Watch notes: Firebase if logged in, local if logged out
  Stream<List<Note>> watchNotes({String? userId}) {
    final uid = userId ?? _uid;
    if (uid == null) {
      // Local notes stream
      _loadLocalNotes();
      return _localNotesController.stream;
    }

    // Firebase notes stream
    final col = _notesCollection(uid);
    return col
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((q) => q.docs.map((d) => d.data()).toList());
  }

  CollectionReference<Note> _notesCollection(String userId) =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notes')
          .withConverter<Note>(
            fromFirestore: (snapshot, _) => Note.fromFirestore(snapshot),
            toFirestore: (note, _) => note.toMap(),
          );

  /// Load local notes and push to stream
  Future<void> _loadLocalNotes() async {
    final notes = await getLocalNotes();
    _localNotesController.add(notes);
  }

  /// Get local notes
  Future<List<Note>> getLocalNotes() async {
    final rows = await _db.getNotes();
    return rows
        .map((r) => Note(
              id: r['id'].toString(),
              title: r['title'],
              content: r['content'],
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ))
        .toList();
  }

  /// Add or update note
  Future<void> addOrUpdateNote(Note note, {String? userId}) async {
    final uid = userId ?? _uid;

    if (uid == null) {
      // Save locally
      final row = {
        'id': note.id.isEmpty ? null : int.tryParse(note.id),
        'title': note.title,
        'content': note.content
      };

      if (note.id.isEmpty) {
        await _db.insertNote(row);
      } else {
        await _db.updateNote(row);
      }

      // Update local stream
      await _loadLocalNotes();
      return;
    }

    // Save to Firebase
    final col = _notesCollection(uid);
    if (note.id.isEmpty) {
      await col.add(note);
    } else {
      await col.doc(note.id).set(note, SetOptions(merge: true));
    }
  }

  /// Delete note
  Future<void> deleteNote(String id, {String? userId}) async {
    final uid = userId ?? _uid;

    if (uid == null) {
      // Delete local
      await _db.deleteNote(int.parse(id));
      await _loadLocalNotes(); // update stream
      return;
    }

    final col = _notesCollection(uid);
    await col.doc(id).delete();
  }

  /// Migrate local notes to Firebase after login
  Future<void> migrateLocalToFirebase(String emailUID) async {
    final localNotes = await getLocalNotes();
    for (var note in localNotes) {
      await addOrUpdateNote(note, userId: emailUID);
    }
    // Clear local DB
    for (var note in localNotes) {
      await _db.deleteNote(int.parse(note.id));
    }
    // Update local stream
    await _loadLocalNotes();
  }

  /// Dispose the local stream controller
  void dispose() {
    _localNotesController.close();
  }
}
