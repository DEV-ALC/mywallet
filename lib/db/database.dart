// lib/bd/database.dart
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';

// Modelo da tarefa
class Task {
  final int? id;
  final String title;
  final bool isCompleted;

  Task({this.id, required this.title, this.isCompleted = false});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted ? 1 : 0,
    };
  }

  @override
  String toString() {
    return 'Task{id: $id, title: $title, isCompleted: $isCompleted}';
  }
}

// Modelo da etiqueta
class Etiqueta {
  final int? id;
  final String title;

  Etiqueta({this.id, required this.title});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
    };
  }

  factory Etiqueta.fromMap(Map<String, dynamic> map) {
    return Etiqueta(
      id: map['id'] as int?,
      title: map['title'] as String,
    );
  }

  @override
  String toString() {
    return 'Etiqueta{id: $id, title: $title}';
  }
}

// Modelo da despesa
class Expense {
  final int? id;
  final String title;
  final double amount; // Renamed from valor
  final DateTime data;
  final List<String> tags; // Renamed from etiquetas

  Expense({
    this.id,
    required this.title,
    required this.amount,
    required this.data,
    required this.tags,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'data': data.toIso8601String(),
      'tags': jsonEncode(tags),
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      data: DateTime.parse(map['data'] as String),
      tags: List<String>.from(jsonDecode(map['tags'] as String)),
    );
  }

  @override
  String toString() {
    return 'Expense{id: $id, title: $title, amount: $amount, data: $data, tags: $tags}';
  }
}

// Gerenciador do banco de dados
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('tasks.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, fileName);

    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        // Criação da tabela tasks
        await db.execute('''
          CREATE TABLE tasks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            isCompleted INTEGER NOT NULL
          )
        ''');
        // Criação da tabela etiquetas
        await db.execute('''
          CREATE TABLE etiquetas (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL
          )
        ''');
        // Criação da tabela expenses
        await db.execute('''
          CREATE TABLE expenses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            amount REAL NOT NULL,
            data TEXT NOT NULL,
            tags TEXT NOT NULL DEFAULT '[]'
          )
        ''');
      },
    );
  }

  // --- Operações para Tasks ---
  Future<void> insertTask(Task task) async {
    final db = await database;
    await db.insert('tasks', task.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Task>> getTasks() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('tasks');
    return maps
        .map((map) => Task(
              id: map['id'] as int?,
              title: map['title'] as String,
              isCompleted: (map['isCompleted'] as int) == 1,
            ))
        .toList();
  }

  Future<void> updateTask(Task task) async {
    final db = await database;
    await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<void> deleteTask(int id) async {
    final db = await database;
    await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- Operações para Etiquetas ---
  Future<void> insertEtiqueta(Etiqueta etiqueta) async {
    final db = await database;
    await db.insert('etiquetas', etiqueta.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Etiqueta>> getEtiquetas() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('etiquetas');
    return maps.map((map) => Etiqueta.fromMap(map)).toList();
  }

  Future<void> updateEtiqueta(Etiqueta etiqueta) async {
    final db = await database;
    await db.update(
      'etiquetas',
      etiqueta.toMap(),
      where: 'id = ?',
      whereArgs: [etiqueta.id],
    );
  }

  Future<void> deleteEtiqueta(int id) async {
    final db = await database;
    await db.delete(
      'etiquetas',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- Operações para Expenses ---
  Future<void> insertExpense(Expense expense) async {
    final db = await database;
    await db.insert('expenses', expense.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Expense>> getExpenses() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('expenses');
    return maps.map((map) => Expense.fromMap(map)).toList();
  }

  Future<void> updateExpense(Expense expense) async {
    final db = await database;
    await db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<void> deleteExpense(int id) async {
    final db = await database;
    await db.delete(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
