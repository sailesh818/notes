import 'package:flutter/material.dart';
import 'package:notes_todo/pages/note_list.dart';
import '../model/note.dart';
import '../services/notes_service.dart';
import '../services/alarm_service.dart';

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

  DateTime? _selectedReminderTime;

  @override
  void initState() {
    super.initState();
    if (widget.note != null) {
      _titleController.text = widget.note!.title;
      _contentController.text = widget.note!.content;
      _selectedReminderTime = widget.note!.reminderTime;
    }
  }

  Future<void> _pickReminder() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      initialDate: _selectedReminderTime ?? DateTime.now(),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: _selectedReminderTime != null
          ? TimeOfDay.fromDateTime(_selectedReminderTime!)
          : TimeOfDay.now(),
    );
    if (time == null) return;

    setState(() {
      _selectedReminderTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  /// Cancel reminder and stop any playing alarm
  Future<void> _cancelReminder() async {
    if (widget.note != null) {
      await AlarmService.stopAlarm(widget.note!.id.hashCode);
    }
    setState(() => _selectedReminderTime = null);
  }

  /// Save or update note with proper alarm handling
  Future<void> _saveNote() async {
    if (!_formKey.currentState!.validate()) return;

    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    final now = DateTime.now();

    Note note;

    if (widget.note == null) {
      note = Note(
        id: '',
        title: title,
        content: content,
        createdAt: now,
        updatedAt: now,
        reminderTime: _selectedReminderTime,
      );
    } else {
      note = widget.note!.copyWith(
        title: title,
        content: content,
        updatedAt: now,
        reminderTime: _selectedReminderTime,
      );
    }

    // Handle oldNote for cancelling previous alarm if removed
    Note? oldNote = widget.note;
    if (_selectedReminderTime == null && widget.note?.reminderTime != null) {
      oldNote = widget.note!.copyWith(reminderTime: null);
    }

    // Add or update note with alarm handling
    await _notesService.addOrUpdateNote(note, oldNote: oldNote);

    // Stop currently playing alarm if reminder removed
    if (_selectedReminderTime == null && widget.note != null) {
      await AlarmService.stopAlarm(widget.note!.id.hashCode);
    }

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_)=> NoteListPage()), 
        (route)=> false,
      );
    }
  }

  /// Delete note and cancel any alarm
  Future<void> _deleteNote() async {
    if (widget.note != null) {
      await _notesService.deleteNote(widget.note!.id);
      await AlarmService.stopAlarm(widget.note!.id.hashCode);
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
          ),
          if (isEdit)
            IconButton(
              onPressed: _deleteNote,
              icon: const Icon(Icons.delete),
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
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _pickReminder,
                        icon: const Icon(Icons.alarm),
                        label: Text(_selectedReminderTime == null
                            ? "Add Reminder"
                            : "Reminder: ${_selectedReminderTime.toString().substring(0, 16)}"),
                      ),
                    ),
                    if (_selectedReminderTime != null)
                      IconButton(
                        onPressed: _cancelReminder,
                        icon: const Icon(Icons.cancel),
                        tooltip: 'Cancel Reminder',
                      ),
                  ],
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
