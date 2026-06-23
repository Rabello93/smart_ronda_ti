import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('ronda_hospitalar.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2, // Incrementei a versão para aplicar mudanças de schema
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Aqui poderiam entrar scripts de migração se o app já estivesse em produção
    }
  }

  Future _createDB(Database db, int version) async {
    // Ativar suporte a chaves estrangeiras
    await db.execute('PRAGMA foreign_keys = ON');

    // Tabela de setores
    await db.execute('''
      CREATE TABLE setores (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT UNIQUE NOT NULL
      )
    ''');

    // Tabela de rondas
    await db.execute('''
      CREATE TABLE rondas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        data_inicio TEXT,
        data_fim TEXT,
        setor TEXT,
        usuario TEXT,
        itens_total INTEGER,
        trocas_total INTEGER,
        defeitos_total INTEGER
      )
    ''');

    // Tabela de equipamentos
    await db.execute('''
      CREATE TABLE equipamentos_ronda (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ronda_id INTEGER,
        tipo TEXT,
        patrimonio TEXT,
        carregador INTEGER,
        mouse INTEGER,
        teclado INTEGER,
        monitor INTEGER,
        status TEXT,
        observacao TEXT,
        FOREIGN KEY (ronda_id) REFERENCES rondas (id) ON DELETE CASCADE
      )
    ''');

    // Tabela de trocas
    await db.execute('''
      CREATE TABLE trocas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ronda_id INTEGER,
        equipamento_antigo TEXT,
        equipamento_novo TEXT,
        patrimonio_antigo TEXT,
        patrimonio_novo TEXT,
        hora_retirada TEXT,
        hora_instalacao TEXT,
        tempo_troca_minutos INTEGER,
        motivo TEXT,
        FOREIGN KEY (ronda_id) REFERENCES rondas (id) ON DELETE CASCADE
      )
    ''');
  }

  // ==========================
  // SETORES
  // ==========================

  Future<int> insertSetor(String nome) async {
    final db = await instance.database;
    return await db.insert(
      'setores',
      {'nome': nome},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<List<Map<String, dynamic>>> getSetores() async {
    final db = await instance.database;
    return await db.query('setores', orderBy: 'nome ASC');
  }

  Future<int> deleteSetor(int id) async {
    final db = await instance.database;
    return await db.delete(
      'setores',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==========================
  // RONDAS
  // ==========================

  Future<int> insertRonda(Map<String, dynamic> ronda) async {
    final db = await instance.database;
    return await db.insert('rondas', ronda);
  }

  Future<int> updateRonda(Map<String, dynamic> ronda) async {
    final db = await instance.database;
    return await db.update(
      'rondas',
      ronda,
      where: 'id = ?',
      whereArgs: [ronda['id']],
    );
  }

  Future<List<Map<String, dynamic>> > getRondas() async {
    final db = await instance.database;
    return await db.query('rondas', orderBy: 'id DESC');
  }

  Future<int> deleteRonda(int id) async {
    final db = await instance.database;
    return await db.delete(
      'rondas',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==========================
  // EQUIPAMENTOS
  // ==========================

  Future<int> insertEquipamento(Map<String, dynamic> equipamento) async {
    final db = await instance.database;
    return await db.insert('equipamentos_ronda', equipamento);
  }

  Future<List<Map<String, dynamic>>> getEquipamentosPorRonda(int rondaId) async {
    final db = await instance.database;
    return await db.query(
      'equipamentos_ronda',
      where: 'ronda_id = ?',
      whereArgs: [rondaId],
    );
  }

  Future<int> deleteEquipamento(int id) async {
    final db = await instance.database;
    return await db.delete(
      'equipamentos_ronda',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==========================
  // TROCAS
  // ==========================

  Future<int> insertTroca(Map<String, dynamic> troca) async {
    final db = await instance.database;
    return await db.insert('trocas', troca);
  }

  Future<List<Map<String, dynamic>>> getTrocasPorRonda(int rondaId) async {
    final db = await instance.database;
    return await db.query(
      'trocas',
      where: 'ronda_id = ?',
      whereArgs: [rondaId],
    );
  }

  // ==========================
  // FECHAR BANCO
  // ==========================

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}