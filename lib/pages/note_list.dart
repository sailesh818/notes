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
  Set<int> selectedNotes = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    dbHelper = DbHelper();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    setState(() => _isLoading = true);
    final noteMaps = await dbHelper.getNotes();
    final loadedNotes = noteMaps.map((e) => Note.fromMap(e)).toList();
    setState(() {
      notes = loadedNotes;
      _isLoading = false;
    });
  }

  void _toggleNoteSelection(int? id) {
    if (id == null) return;
    setState(() {
      if (selectedNotes.contains(id)) {
        selectedNotes.remove(id);
      } else {
        selectedNotes.add(id);
      }
    });
  }

  Future<void> _deleteSelectedNotes() async {
    for (var id in selectedNotes) {
      await dbHelper.deleteNote(id);
    }
    selectedNotes.clear();
    await _loadNotes();
  }

  void _onNoteTap(Note note) {
    if (selectedNotes.isNotEmpty) {
      _toggleNoteSelection(note.id);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => NoteEditPage(note: note)),
      ).then((_) => _loadNotes());
    }
  }

  Widget _buildNoteCard(Note note) {
    final isSelected = selectedNotes.contains(note.id);

    return GestureDetector(
      onLongPress: () => _toggleNoteSelection(note.id),
      onTap: () => _onNoteTap(note),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[100] : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade200,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          title: Text(
            note.title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.blue : Colors.black,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            note.content,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSelecting = selectedNotes.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        leading: isSelecting
            ? IconButton(
                icon: Icon(Icons.close),
                onPressed: () => setState(() => selectedNotes.clear()),
              )
            : null,
        title: Text(
          isSelecting ? "${selectedNotes.length} selected" : "My Notes",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: isSelecting
            ? [
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: _deleteSelectedNotes,
                )
              ]
            : [],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : notes.isEmpty
              ? Center(child: Text('No notes yet!'))
              : RefreshIndicator(
                  onRefresh: _loadNotes,
                  child: ListView.builder(
                    physics: AlwaysScrollableScrollPhysics(),
                    itemCount: notes.length,
                    itemBuilder: (_, index) => _buildNoteCard(notes[index]),
                  ),
                ),
      floatingActionButton: isSelecting
          ? null
          : FloatingActionButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => NoteEditPage()),
                );
                _loadNotes();
              },
              child: Icon(Icons.add),
              tooltip: 'Add Note',
            ),
    );
  }
}
