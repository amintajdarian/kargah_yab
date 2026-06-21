import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'workshop_form.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('workshops_v3.db'); // Incremented version to add industrialTown field
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE workshops (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        factoryName TEXT NOT NULL,
        managerName TEXT NOT NULL,
        phone1 TEXT NOT NULL,
        phone2 TEXT NOT NULL,
        product TEXT NOT NULL,
        industrialTown TEXT NOT NULL,
        address TEXT NOT NULL,
        website TEXT NOT NULL,
        socialMedia TEXT NOT NULL,
        description TEXT NOT NULL,
        latitude REAL,
        longitude REAL,
        neshanAddress TEXT NOT NULL,
        registeredBy TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  Future<int> insertWorkshop(WorkshopFormModel workshop) async {
    final db = await instance.database;
    return await db.insert('workshops', workshop.toMap());
  }

  Future<List<WorkshopFormModel>> fetchAllWorkshops() async {
    final db = await instance.database;
    final maps = await db.query('workshops', orderBy: 'id DESC');

    return maps.map((map) => WorkshopFormModel.fromMap(map)).toList();
  }

  Future<List<WorkshopFormModel>> fetchWorkshopsByDate(String date) async {
    final db = await instance.database;
    final maps = await db.query(
      'workshops',
      where: 'createdAt LIKE ?',
      whereArgs: ['$date%'],
      orderBy: 'id DESC',
    );

    return maps.map((map) => WorkshopFormModel.fromMap(map)).toList();
  }

  Future<int> deleteWorkshop(int id) async {
    final db = await instance.database;
    return await db.delete(
      'workshops',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearAll() async {
    final db = await instance.database;
    await db.delete('workshops');
  }

  Future<void> close() async {
    final db = await _database;
    if (db != null) {
      await db.close();
    }
  }
}
