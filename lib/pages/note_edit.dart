import 'package:flutter/material.dart';
import '../model/note.dart';
import '../services/notes_service.dart';

class NoteEditPage extends StatefulWidget {
  final Note? note;
  const NoteEditPage({super.key, this.note});

  @override
  State<NoteEditPage> createState() => _NoteEditPageState();
}

class _NoteEditPageState extends State<NoteEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _notesService = NotesService.instance;

  @override
  void initState() {
    super.initState();
    if (widget.note != null) {
      _titleController.text = widget.note!.title;
      _contentController.text = widget.note!.content;
    }
  }

  /// Save note: Firebase if logged in, local DB if not
  Future<void> _saveNote() async {
    if (!_formKey.currentState!.validate()) return;

    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    final now = DateTime.now();

    if (widget.note == null) {
      // New note
      final newNote = Note(
        id: '',
        title: title,
        content: content,
        createdAt: now,
        updatedAt: now,
      );
      await _notesService.addOrUpdateNote(newNote);
    } else {
      // Update existing note
      final updatedNote = widget.note!.copyWith(
        title: title,
        content: content,
        updatedAt: now,
      );
      await _notesService.addOrUpdateNote(updatedNote);
    }

    if (mounted) Navigator.pop(context);
  }

  /// Delete note
  Future<void> _deleteNote() async {
    if (widget.note != null) {
      await _notesService.deleteNote(widget.note!.id);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.note != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Note' : 'Add Note'),
        actions: [
          IconButton(
            onPressed: _saveNote,
            icon: const Icon(Icons.save),
            tooltip: 'Save Note',
          ),
          if (isEdit)
            IconButton(
              onPressed: _deleteNote,
              icon: const Icon(Icons.delete),
              tooltip: 'Delete Note',
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) =>
                      val == null || val.trim().isEmpty ? 'Enter title' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _contentController,
                  decoration: const InputDecoration(
                    labelText: 'Content',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 8,
                  validator: (val) =>
                      val == null || val.trim().isEmpty ? 'Enter content' : null,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveNote,
                    child: Text(isEdit ? 'Update Note' : 'Save Note'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
