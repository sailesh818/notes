import 'package:flutter/material.dart';
import 'package:notes_todo/db/db_helper.dart';
import 'package:notes_todo/model/note.dart';

class NoteEditPage extends StatefulWidget {
  final Note? note;
  NoteEditPage({this.note});

  @override
  _NoteEditPageState createState() => _NoteEditPageState();
}

class _NoteEditPageState extends State<NoteEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  late DbHelper dbHelper;

  @override
  void initState() {
    super.initState();
    dbHelper = DbHelper();
    if (widget.note != null) {
      _titleController.text = widget.note!.title;
      _contentController.text = widget.note!.content;
    }
  }

  void _saveNote() async {
    if (_formKey.currentState!.validate()) {
      String title = _titleController.text.trim();
      String content = _contentController.text.trim();
      if (widget.note == null) {
        await dbHelper.insertNote(Note(title: title, content: content).toMap());
      } else {
        await dbHelper.updateNote(
          Note(id: widget.note!.id, title: title, content: content).toMap(),
        );
      }
      Navigator.pop(context);
    }
  }

  void _deleteNote() async {
    if (widget.note?.id != null) {
      await dbHelper.deleteNote(widget.note!.id!);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.note == null ? 'Add Note' : 'Edit Note'),
        actions: [
          IconButton(onPressed: _saveNote, icon: Icon(Icons.save)),
          if (widget.note != null)
            IconButton(onPressed: _deleteNote, icon: Icon(Icons.delete)),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(labelText: 'Title'),
                  validator: (val) => val == null || val.isEmpty ? 'Enter title' : null,
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _contentController,
                  decoration: InputDecoration(labelText: 'Content'),
                  maxLines: 8,
                  validator: (val) => val == null || val.isEmpty ? 'Enter content' : null,
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _saveNote,
                  child: Text('Save'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
