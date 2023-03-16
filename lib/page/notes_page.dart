// Project Package
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
// Project Files
import 'package:flutter_crud_sqflite/db/notes_database.dart';
import 'package:flutter_crud_sqflite/model/note.dart';
import 'package:flutter_crud_sqflite/page/edit_note_page.dart';
import 'package:flutter_crud_sqflite/page/note_detail_page.dart';
import 'package:flutter_crud_sqflite/widget/note_card_widget.dart';

class NotesPage extends StatefulWidget {
  @override
  _NotesPageState createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  late List<Note> notes;
  String labelNotes = 'Notes';
  String labelNoNotes = 'No Notes';
  bool isLoading = false;

  @override
  void initState(){
    super.initState();
    refreshNotes();
  }

  @override
  void dispose(){
    NotesDatabase.instance.close();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        labelNotes,
        style: TextStyle(fontSize: 24)
      ),
      actions: const [
        Icon(Icons.search),
        SizedBox(width: 12)
      ]
    ),
    body: Center(
      child: isLoading ? CircularProgressIndicator()
      : notes.isEmpty
        ? Text(
          labelNoNotes,
          style: TextStyle(color: Colors.white)
        )
      : buildNotes(),
    ),
    floatingActionButton: FloatingActionButton(
      backgroundColor: Colors.black,
      child: Icon(Icons.add),
      onPressed: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => AddEditNotePage())
        );

        refreshNotes();
      },
    )
  );

  Widget buildNotes() => StaggeredGridView.countBuilder(
    padding: EdgeInsets.all(8),
    itemCount: notes.length,
    staggeredTileBuilder: (index) => StaggeredTile.fit(2),// StaggeredTitle.fit(2),
    crossAxisCount: 4,
    mainAxisSpacing: 4,
    crossAxisSpacing: 4,
    itemBuilder: (context, index) {
      final note = notes[index];

      return GestureDetector(
        onTap: () async {
          await Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => NoteDetailPage(noteId: note.id!)
          ));

          refreshNotes();
        },
        child: NoteCardWidget(note: note, index: index),
      );
    },
  );

  Future refreshNotes() async {
    setState(() => isLoading = true);

    this.notes = await NotesDatabase.instance.readAllNotes();

    setState(() => isLoading = false);
  }

}