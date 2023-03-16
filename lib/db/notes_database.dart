import 'dart:math';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
// import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';
// import 'package:sqlite3/open.dart';

import '../model/note.dart';

class NotesDatabase {

  String? _platformVersion = 'Unknown';

  static final NotesDatabase instance = NotesDatabase._init();

  static Database? _database;

  NotesDatabase._init();

  Future<Database> get database async {
    if(_database != null ) return _database!;

    _database = await _initDB('notes.db');

    return _database!;
  }

  Future initPlatformState() async {
    String? platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      // ignore: deprecated_member_use
      platformVersion = await Sqflite.platformVersion;
    } on PlatformException {
      platformVersion = 'Failed to get platform version';
    }

    _platformVersion = platformVersion;
  }

  Future<Database> _initDB(String filePath) async {

    final dbPath = await getDatabasesPath();

    final path = join(dbPath, filePath);

    await initPlatformState();

    return await openDatabase(path, version: 2, onCreate: _createDB, );
  }

  Future _createDB(Database db, int version) async {
    final idType  = 'INTEGER PRIMARY KEY AUTOINCREMENT';

    final textType = 'TEXT NOT NULL';

    final boolType = 'BOOLEAN NOT NULL';

    final integerType = 'INTEGER NOT NULL';

    await db.execute('''
      CREATE TABLE $tableNotes (
        ${NoteFields.id} $idType, 
        ${NoteFields.isImportant} $boolType,
        ${NoteFields.number} $integerType,
        ${NoteFields.title} $textType,
        ${NoteFields.description} $textType,
        ${NoteFields.time} $textType
      )
    ''');

  }

  Future<Note> readNote(int id) async {
    final db = await instance.database;

    final maps = await db.query(
      tableNotes,
      columns: NoteFields.values,
      where: '${NoteFields.id} = ?',
      whereArgs: [id]
    );

    if(maps.isNotEmpty) {
      return Note.fromJson(maps.first);
    } else {
      throw Exception('ID $id not found');
    }
  }

  Future<List<Note>> readAllNotes() async {
    final db = await instance.database;

    final orderBy = '${NoteFields.time} ASC';
    final result = await db.rawQuery('SELECT * FROM $tableNotes ORDER BY $orderBy');
    // final result = await db.query(tableNotes, orderBy: orderBy);

    return result.map((json) => Note.fromJson(json)).toList();
  }

  Future<Note> create(Note note) async {
    final db = await instance.database;

    final json = note.toJson();

    final columns = '${NoteFields.title}, ${NoteFields.description}, ${NoteFields.time}';

    final values = '${json[NoteFields.title]}, ${json[NoteFields.description]}, ${json[NoteFields.time]}';

    // final id = await db.rawInsert('INSERT INTO ${tableNotes} ($columns) VALUES ($values)');
    // final id  = await db.insert(tableNotes, note.toJson());
    final id = await db.insert(tableNotes, note.toJson());

    return note.copy(id: id);
  }

  Future<int> update(Note note) async {
    final db = await instance.database;

    return db.update(
      tableNotes,
      note.toJson(),
      where: '${NoteFields.id} = ?',
      whereArgs: [note.id]
    );
  }

  Future<int> delete(int id) async {
    final db = await instance.database;

    return await db.delete(
      tableNotes,
      where: '${NoteFields.id} = ?',
      whereArgs: [id]
    );
  }

  Future close() async {
    final db = await instance.database;

    db.close();
  }
}