import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/scan_result.dart';

class DatabaseService {
  static Database? _db;

  // Opens (or creates) the database file on the device
  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'hemalens.db');
    return openDatabase(path, version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE results (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            risk_tier TEXT NOT NULL,
            confidence REAL NOT NULL,
            survey_json TEXT NOT NULL,
            timestamp TEXT NOT NULL,
            synced INTEGER DEFAULT 0
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // Drop and recreate to handle schema changes during development
        await db.execute('DROP TABLE IF EXISTS results');
        await db.execute('''
          CREATE TABLE results (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            risk_tier TEXT NOT NULL,
            confidence REAL NOT NULL,
            survey_json TEXT NOT NULL,
            timestamp TEXT NOT NULL,
            synced INTEGER DEFAULT 0
          )
        ''');
      },
    );

  }

  // Save a result; returns the new row ID
  static Future<int> insertResult(ScanResult result) async {
    final db = await database;
    return db.insert('results', result.toMap());
  }

  // Get all saved results, newest first
  static Future<List<Map<String, dynamic>>> getAllResults() async {
    final db = await database;
    return db.query('results', orderBy: 'timestamp DESC');
  }
}
