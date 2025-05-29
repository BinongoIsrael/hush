import 'package:sqflite/sqflite.dart';
import '../models/account.dart';
import '../models/post.dart';

class DatabaseService {
  static final DatabaseService _databaseService = DatabaseService._internal();
  factory DatabaseService() => _databaseService;
  DatabaseService._internal();

  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<void> deleteReaction(String postId, String userId) async {
    final db = await database;
    await db.delete(
      'reaction',
      where: 'post_id = ? AND user_id = ?',
      whereArgs: [postId, userId],
    );
    await db.rawUpdate(
      'UPDATE post SET reaction_count = reaction_count - 1 WHERE id = ? AND reaction_count > 0',
      [postId],
    );
  }


  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = '$databasePath/hush_app.db';
    final database = await openDatabase(
      path,
      version: 3, // Incremented version to trigger _onUpgrade
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async => await db.execute('PRAGMA foreign_keys = ON'),
    );
    _database = database;
    return database;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute(
        """
      CREATE TABLE account (
        uuid TEXT PRIMARY KEY,
        api_id TEXT,
        user_level INTEGER DEFAULT 0,
        api_name TEXT,
        api_email TEXT,
        api_photo_url TEXT,
        is_signed_in INTEGER DEFAULT 0,
        is_public INTEGER DEFAULT 0,
        is_contributor_mode INTEGER DEFAULT 0,
        is_restricted INTEGER DEFAULT 0,
        is_synchronized INTEGER DEFAULT 0,
        ttl TEXT,
        created_at TEXT NOT NULL
      );
      """
    );
    await db.execute(
        """
      CREATE TABLE post (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        content TEXT,
        is_anonymous INTEGER DEFAULT 0,
        tags TEXT,
        reaction_count INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES account(uuid)
      );
      """
    );
    await db.execute(
        """
      CREATE TABLE comment (
        id TEXT PRIMARY KEY,
        post_id TEXT,
        user_id TEXT,
        content TEXT,
        is_anonymous INTEGER DEFAULT 0,
        parent_comment_id TEXT, 
        created_at TEXT NOT NULL,
        FOREIGN KEY (post_id) REFERENCES post(id),
        FOREIGN KEY (user_id) REFERENCES account(uuid),
        FOREIGN KEY (parent_comment_id) REFERENCES comment(id)
      );
      """
    );
    await db.execute(
        """
      CREATE TABLE reaction (
        id TEXT PRIMARY KEY,
        post_id TEXT,
        user_id TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (post_id) REFERENCES post(id),
        FOREIGN KEY (user_id) REFERENCES account(uuid)
      );
      """
    );
    await db.execute(
        """
      CREATE TABLE report (
        id TEXT PRIMARY KEY,
        content_id TEXT,
        content_type TEXT,
        reason TEXT,
        user_id TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES account(uuid)
      );
      """
    );
  }

// Update _onUpgrade to handle schema migration
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Previous table creations for version 1 to 2
      await db.execute(
          """
        CREATE TABLE post (
          id TEXT PRIMARY KEY,
          user_id TEXT,
          content TEXT,
          is_anonymous INTEGER DEFAULT 0,
          tags TEXT,
          reaction_count INTEGER DEFAULT 0,
          created_at TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES account(uuid)
        );
        """
      );
      await db.execute(
          """
        CREATE TABLE comment (
          id TEXT PRIMARY KEY,
          post_id TEXT,
          user_id TEXT,
          content TEXT,
          is_anonymous INTEGER DEFAULT 0,
          parent_comment_id TEXT, -- Added for threaded replies
          created_at TEXT NOT NULL,
          FOREIGN KEY (post_id) REFERENCES post(id),
          FOREIGN KEY (user_id) REFERENCES account(uuid),
          FOREIGN KEY (parent_comment_id) REFERENCES comment(id)
        );
        """
      );
      await db.execute(
          """
        CREATE TABLE reaction (
          id TEXT PRIMARY KEY,
          post_id TEXT,
          user_id TEXT,
          created_at TEXT NOT NULL,
          FOREIGN KEY (post_id) REFERENCES post(id),
          FOREIGN KEY (user_id) REFERENCES account(uuid)
        );
        """
      );
      await db.execute(
          """
        CREATE TABLE report (
          id TEXT PRIMARY KEY,
          content_id TEXT,
          content_type TEXT,
          reason TEXT,
          user_id TEXT,
          created_at TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES account(uuid)
        );
        """
      );
    }
    if (oldVersion < 3) {
      // Add parent_comment_id column for existing databases
      await db.execute("ALTER TABLE comment ADD COLUMN parent_comment_id TEXT");
      await db.execute("UPDATE comment SET parent_comment_id = NULL");
      await db.execute(
          "ALTER TABLE comment ADD FOREIGN KEY (parent_comment_id) REFERENCES comment(id)");
    }
  }

  Future<void> insertAccount(Account account) async {
    final db = await database;
    await db.insert('account', account.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateAccount(Account account) async {
    final db = await database;
    await db.update('account', account.toMap(), where: 'uuid = ?', whereArgs: [account.uuid]);
  }

  Future<List<Account>> getAccount(String uuid) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('account', where: 'uuid = ?', whereArgs: [uuid]);
    return List.generate(maps.length, (index) => Account.fromMap(maps[index]));
  }

  Future<List<Account>> getSignedAccount() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'account',
      where: 'is_signed_in = 1',
      orderBy: 'created_at DESC',
      limit: 1,
    );
    return List.generate(maps.length, (index) => Account.fromMap(maps[index]));
  }

  Future<List<Account>> getAccounts(int limit) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('account', limit: limit);
    return List.generate(maps.length, (index) => Account.fromMap(maps[index]));
  }

  Future<void> signOutAccount(String accountId) async {
    final db = await database;
    await db.update(
      'account',
      {'is_signed_in': 0},
      where: 'uuid = ?',
      whereArgs: [accountId],
    );
  }

  Future<void> clearAccounts() async {
    final db = await database;
    await db.delete('account');
  }

  Future<void> insertPost(Post post) async {
    final db = await database;
    await db.insert('post', post.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Post>> getPosts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('post', orderBy: 'created_at DESC');
    return List.generate(maps.length, (index) => Post.fromMap(maps[index]));
  }

  Future<void> insertComment(Comment comment) async {
    final db = await database;
    await db.insert('comment', comment.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Comment>> getComments(String postId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'comment',
      where: 'post_id = ?',
      whereArgs: [postId],
      orderBy: 'created_at ASC',
    );
    return List.generate(maps.length, (index) => Comment.fromMap(maps[index]));
  }

  Future<void> insertReaction(String id, String postId, String userId, String createdAt) async {
    final db = await database;
    await db.insert(
      'reaction',
      {'id': id, 'post_id': postId, 'user_id': userId, 'created_at': createdAt},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await db.rawUpdate('UPDATE post SET reaction_count = reaction_count + 1 WHERE id = ?', [postId]);
  }

  Future<bool> hasReacted(String postId, String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'reaction',
      where: 'post_id = ? AND user_id = ?',
      whereArgs: [postId, userId],
    );
    return maps.isNotEmpty;
  }

  Future<void> insertReport(String id, String contentId, String contentType, String reason, String userId, String createdAt) async {
    final db = await database;
    await db.insert(
      'report',
      {
        'id': id,
        'content_id': contentId,
        'content_type': contentType,
        'reason': reason,
        'user_id': userId,
        'created_at': createdAt,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> getReactionCount(String postId) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      'post',
      columns: ['reaction_count'],
      where: 'id = ?',
      whereArgs: [postId],
    );
    if (result.isNotEmpty) {
      return result.first['reaction_count'] as int? ?? 0;
    }
    return 0;
  }

}

