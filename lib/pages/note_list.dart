import 'package:flutter/material.dart';
import 'package:notes_todo/db/db_helper.dart';
import 'package:notes_todo/model/note.dart';
import 'note_edit.dart';

class NoteListPage extends StatefulWidget {
  @override
  _NoteListPageState createState() => _NoteListPageState();
}

class _NoteListPageState extends State<NoteListPage> {
  late DbHelper dbHelper;
  List<Note> notes = [];

  @override
  void initState() {
    super.initState();
    dbHelper = DbHelper();
    _refreshNotes();
  }

  void _refreshNotes() async {
    List<Map<String, dynamic>> noteMaps = await dbHelper.getNotes();
    notes = noteMaps.map((noteMap) => Note.fromMap(noteMap)).toList();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Notes'),
      ),
      body: notes.isEmpty
          ? Center(child: Text('No notes yet!'))
          : ListView.builder(
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final note = notes[index];
                return Card(
                  child: ListTile(
                    title: Text(
                      note.title, 
                      maxLines: 1, 
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(note.content, maxLines: 1, overflow: TextOverflow.ellipsis,),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => NoteEditPage(note: note),
                        ),
                      );
                      _refreshNotes();
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => NoteEditPage()),
          );
          _refreshNotes();
        },
      ),
    );
  }
}
