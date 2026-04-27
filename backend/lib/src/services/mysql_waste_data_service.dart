import 'dart:convert';

import 'package:mysql1/mysql1.dart';

import '../config/database_config.dart';
import '../models/app_models.dart';
import 'waste_data_service.dart';

/// MySQL-backed implementation of [WasteDataService].
///
/// This service:
/// - creates the target database if needed
/// - creates all required tables if missing
/// - inserts seed data when tables are empty
/// - serves all API data from MySQL
class MySqlWasteDataService implements WasteDataService {
  MySqlWasteDataService._({
    required DatabaseConfig config,
    required MySqlConnection connection,
  }) : _config = config,
       _connection = connection;

  final DatabaseConfig _config;
  final MySqlConnection _connection;

  /// Initializes schema/tables/seed-data and returns a ready service instance.
  static Future<MySqlWasteDataService> initialize(DatabaseConfig config) async {
    await _createDatabaseIfNeeded(config);
    final connection = await MySqlConnection.connect(
      config.toDatabaseConnectionSettings(),
    );

    final service = MySqlWasteDataService._(
      config: config,
      connection: connection,
    );
    await service._createTablesIfNeeded();
    await service._seedDataIfNeeded();
    return service;
  }

  static Future<void> _createDatabaseIfNeeded(DatabaseConfig config) async {
    final connection = await MySqlConnection.connect(
      config.toServerConnectionSettings(),
    );
    try {
      await connection.query(
        'CREATE DATABASE IF NOT EXISTS `${config.database}` '
        'DEFAULT CHARACTER SET ${config.charset}',
      );
    } finally {
      await connection.close();
    }
  }

  Future<void> _createTablesIfNeeded() async {
    await _connection.query('''
      CREATE TABLE IF NOT EXISTS waste_categories (
        id VARCHAR(32) PRIMARY KEY,
        title VARCHAR(128) NOT NULL,
        description TEXT NOT NULL,
        bin_color VARCHAR(32) NOT NULL,
        examples_json TEXT NOT NULL,
        recycling_tips_json TEXT NOT NULL
      ) ENGINE=InnoDB DEFAULT CHARSET=${_config.charset}
    ''');

    await _connection.query('''
      CREATE TABLE IF NOT EXISTS eco_actions (
        id VARCHAR(32) PRIMARY KEY,
        title VARCHAR(255) NOT NULL,
        impact VARCHAR(255) NOT NULL,
        points INT NOT NULL,
        completed TINYINT(1) NOT NULL
      ) ENGINE=InnoDB DEFAULT CHARSET=${_config.charset}
    ''');

    await _connection.query('''
      CREATE TABLE IF NOT EXISTS rewards (
        id VARCHAR(32) PRIMARY KEY,
        title VARCHAR(255) NOT NULL,
        description TEXT NOT NULL,
        required_points INT NOT NULL,
        redeemed TINYINT(1) NOT NULL
      ) ENGINE=InnoDB DEFAULT CHARSET=${_config.charset}
    ''');

    await _connection.query('''
      CREATE TABLE IF NOT EXISTS forum_posts (
        id VARCHAR(32) PRIMARY KEY,
        author VARCHAR(128) NOT NULL,
        title VARCHAR(255) NOT NULL,
        content TEXT NOT NULL,
        tag VARCHAR(64) NOT NULL,
        likes INT NOT NULL,
        replies INT NOT NULL,
        created_at VARCHAR(64) NOT NULL
      ) ENGINE=InnoDB DEFAULT CHARSET=${_config.charset}
    ''');

    await _connection.query('''
      CREATE TABLE IF NOT EXISTS message_threads (
        id VARCHAR(32) PRIMARY KEY,
        sender VARCHAR(128) NOT NULL,
        preview VARCHAR(255) NOT NULL,
        updated_at VARCHAR(64) NOT NULL,
        unread TINYINT(1) NOT NULL
      ) ENGINE=InnoDB DEFAULT CHARSET=${_config.charset}
    ''');

    await _connection.query('''
      CREATE TABLE IF NOT EXISTS app_users (
        id VARCHAR(32) PRIMARY KEY,
        name VARCHAR(128) NOT NULL,
        email VARCHAR(255) NOT NULL,
        city VARCHAR(128) NOT NULL,
        level VARCHAR(128) NOT NULL,
        green_score INT NOT NULL,
        total_recycled_kg DOUBLE NOT NULL,
        avatar_initials VARCHAR(16) NOT NULL
      ) ENGINE=InnoDB DEFAULT CHARSET=${_config.charset}
    ''');
  }

  Future<void> _seedDataIfNeeded() async {
    await _seedCategoriesIfNeeded();
    await _seedEcoActionsIfNeeded();
    await _seedRewardsIfNeeded();
    await _seedForumPostsIfNeeded();
    await _seedMessagesIfNeeded();
    await _seedProfileIfNeeded();
  }

  Future<void> _seedCategoriesIfNeeded() async {
    final result = await _connection.query(
      'SELECT COUNT(*) AS count FROM waste_categories',
    );
    final count = _readInt(result.first.fields['count']);
    if (count > 0) {
      return;
    }

    final categories = <WasteCategory>[
      const WasteCategory(
        id: 'recyclable',
        title: 'Recyclable Waste',
        description: 'Clean paper, plastic, glass, and metal that can be reused.',
        binColor: 'Blue',
        examples: ['Plastic bottles', 'Cardboard', 'Glass jars', 'Aluminum cans'],
        recyclingTips: [
          'Rinse containers before disposal.',
          'Flatten cardboard to save space.',
        ],
      ),
      const WasteCategory(
        id: 'organic',
        title: 'Organic Waste',
        description: 'Food scraps and biodegradable materials for composting.',
        binColor: 'Green',
        examples: ['Fruit peels', 'Vegetable scraps', 'Tea leaves', 'Eggshells'],
        recyclingTips: [
          'Drain extra liquid before disposal.',
          'Keep plastic bags out of organic bins.',
        ],
      ),
      const WasteCategory(
        id: 'hazardous',
        title: 'Hazardous Waste',
        description: 'Items that require special handling to protect people and nature.',
        binColor: 'Red',
        examples: ['Batteries', 'Paint', 'Medicine', 'Pesticide bottles'],
        recyclingTips: [
          'Never mix hazardous waste with household waste.',
          'Use official collection points.',
        ],
      ),
      const WasteCategory(
        id: 'residual',
        title: 'Residual Waste',
        description: 'Non-recyclable daily waste after sorting useful materials.',
        binColor: 'Gray',
        examples: ['Used tissues', 'Ceramics', 'Dust', 'Contaminated packaging'],
        recyclingTips: [
          'Reduce usage when possible.',
          'Separate recyclables before final disposal.',
        ],
      ),
    ];

    for (final category in categories) {
      await _connection.query(
        '''
        INSERT INTO waste_categories (
          id, title, description, bin_color, examples_json, recycling_tips_json
        ) VALUES (?, ?, ?, ?, ?, ?)
        ''',
        [
          category.id,
          category.title,
          category.description,
          category.binColor,
          jsonEncode(category.examples),
          jsonEncode(category.recyclingTips),
        ],
      );
    }
  }

  Future<void> _seedEcoActionsIfNeeded() async {
    final result = await _connection.query('SELECT COUNT(*) AS count FROM eco_actions');
    final count = _readInt(result.first.fields['count']);
    if (count > 0) {
      return;
    }

    const data = [
      EcoAction(
        id: 'a1',
        title: 'Sorted breakfast waste correctly',
        impact: 'Reduced mixed waste by 0.6 kg',
        points: 18,
        completed: true,
      ),
      EcoAction(
        id: 'a2',
        title: 'Reused a shopping bag',
        impact: 'Avoided one single-use plastic bag',
        points: 12,
        completed: true,
      ),
      EcoAction(
        id: 'a3',
        title: 'Join the campus cleanup mission',
        impact: 'Estimated 2.0 kg waste collection',
        points: 40,
        completed: false,
      ),
    ];

    for (final item in data) {
      await _connection.query(
        'INSERT INTO eco_actions (id, title, impact, points, completed) '
        'VALUES (?, ?, ?, ?, ?)',
        [item.id, item.title, item.impact, item.points, item.completed ? 1 : 0],
      );
    }
  }

  Future<void> _seedRewardsIfNeeded() async {
    final result = await _connection.query('SELECT COUNT(*) AS count FROM rewards');
    final count = _readInt(result.first.fields['count']);
    if (count > 0) {
      return;
    }

    const data = [
      Reward(
        id: 'r1',
        title: 'Campus Cafe Coupon',
        description: 'Redeem a 10% discount for a reusable cup order.',
        requiredPoints: 120,
        redeemed: false,
      ),
      Reward(
        id: 'r2',
        title: 'Green Volunteer Badge',
        description: 'Unlock a profile badge for community participation.',
        requiredPoints: 80,
        redeemed: true,
      ),
      Reward(
        id: 'r3',
        title: 'Eco Market Voucher',
        description: 'Use points for sustainable products at partner stores.',
        requiredPoints: 260,
        redeemed: false,
      ),
    ];

    for (final item in data) {
      await _connection.query(
        'INSERT INTO rewards (id, title, description, required_points, redeemed) '
        'VALUES (?, ?, ?, ?, ?)',
        [
          item.id,
          item.title,
          item.description,
          item.requiredPoints,
          item.redeemed ? 1 : 0,
        ],
      );
    }
  }

  Future<void> _seedForumPostsIfNeeded() async {
    final result = await _connection.query('SELECT COUNT(*) AS count FROM forum_posts');
    final count = _readInt(result.first.fields['count']);
    if (count > 0) {
      return;
    }

    const data = [
      ForumPost(
        id: 'p1',
        author: 'Mia Chen',
        title: 'How do you sort takeaway boxes?',
        content: 'I rinse clean paper boxes, but oily ones still confuse me.',
        tag: 'Sorting Tips',
        likes: 42,
        replies: 12,
        createdAt: 'Today',
      ),
      ForumPost(
        id: 'p2',
        author: 'Leo Wang',
        title: 'Weekend river cleanup team',
        content: 'We are forming a small group near the east gate this Saturday.',
        tag: 'Volunteer',
        likes: 35,
        replies: 8,
        createdAt: 'Yesterday',
      ),
      ForumPost(
        id: 'p3',
        author: 'Ava Smith',
        title: 'Battery collection point updated',
        content:
            'The new collection box is now beside the library service desk.',
        tag: 'Campus News',
        likes: 58,
        replies: 6,
        createdAt: '2 days ago',
      ),
    ];

    for (final item in data) {
      await _connection.query(
        '''
        INSERT INTO forum_posts (
          id, author, title, content, tag, likes, replies, created_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        [
          item.id,
          item.author,
          item.title,
          item.content,
          item.tag,
          item.likes,
          item.replies,
          item.createdAt,
        ],
      );
    }
  }

  Future<void> _seedMessagesIfNeeded() async {
    final result = await _connection.query(
      'SELECT COUNT(*) AS count FROM message_threads',
    );
    final count = _readInt(result.first.fields['count']);
    if (count > 0) {
      return;
    }

    const data = [
      MessageThread(
        id: 'm1',
        sender: 'EcoSort AI',
        preview: 'Your weekly green report is ready.',
        updatedAt: '09:30',
        unread: true,
      ),
      MessageThread(
        id: 'm2',
        sender: 'Campus Green Club',
        preview: 'Thanks for joining the recycling challenge.',
        updatedAt: 'Yesterday',
        unread: false,
      ),
      MessageThread(
        id: 'm3',
        sender: 'Reward Center',
        preview: 'You have enough points for a new reward.',
        updatedAt: 'Apr 16',
        unread: true,
      ),
    ];

    for (final item in data) {
      await _connection.query(
        'INSERT INTO message_threads (id, sender, preview, updated_at, unread) '
        'VALUES (?, ?, ?, ?, ?)',
        [
          item.id,
          item.sender,
          item.preview,
          item.updatedAt,
          item.unread ? 1 : 0,
        ],
      );
    }
  }

  Future<void> _seedProfileIfNeeded() async {
    final result = await _connection.query('SELECT COUNT(*) AS count FROM app_users');
    final count = _readInt(result.first.fields['count']);
    if (count > 0) {
      return;
    }

    const user = AppUser(
      id: 'u1',
      name: 'Alex Green',
      email: 'alex.green@example.com',
      city: 'Shanghai',
      level: 'Eco Pioneer',
      greenScore: 836,
      totalRecycledKg: 48.5,
      avatarInitials: 'AG',
    );

    await _connection.query(
      '''
      INSERT INTO app_users (
        id, name, email, city, level, green_score, total_recycled_kg, avatar_initials
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        user.id,
        user.name,
        user.email,
        user.city,
        user.level,
        user.greenScore,
        user.totalRecycledKg,
        user.avatarInitials,
      ],
    );
  }

  @override
  Future<List<WasteCategory>> getCategories() async {
    final result = await _connection.query(
      'SELECT id, title, description, bin_color, examples_json, recycling_tips_json '
      'FROM waste_categories ORDER BY id',
    );

    return result.map(_toWasteCategory).toList(growable: false);
  }

  @override
  Future<List<EcoAction>> getEcoActions() async {
    final result = await _connection.query(
      'SELECT id, title, impact, points, completed FROM eco_actions ORDER BY id',
    );

    return result
        .map(
          (row) => EcoAction(
            id: row[0] as String,
            title: row[1] as String,
            impact: row[2] as String,
            points: _readInt(row[3]),
            completed: _readBool(row[4]),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<List<Reward>> getRewards() async {
    final result = await _connection.query(
      'SELECT id, title, description, required_points, redeemed FROM rewards ORDER BY id',
    );

    return result
        .map(
          (row) => Reward(
            id: row[0] as String,
            title: row[1] as String,
            description: row[2] as String,
            requiredPoints: _readInt(row[3]),
            redeemed: _readBool(row[4]),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<List<ForumPost>> getForumPosts() async {
    final result = await _connection.query(
      'SELECT id, author, title, content, tag, likes, replies, created_at '
      'FROM forum_posts ORDER BY id',
    );

    return result
        .map(
          (row) => ForumPost(
            id: row[0] as String,
            author: row[1] as String,
            title: row[2] as String,
            content: row[3] as String,
            tag: row[4] as String,
            likes: _readInt(row[5]),
            replies: _readInt(row[6]),
            createdAt: row[7] as String,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<List<MessageThread>> getMessages() async {
    final result = await _connection.query(
      'SELECT id, sender, preview, updated_at, unread FROM message_threads ORDER BY id',
    );

    return result
        .map(
          (row) => MessageThread(
            id: row[0] as String,
            sender: row[1] as String,
            preview: row[2] as String,
            updatedAt: row[3] as String,
            unread: _readBool(row[4]),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<AppUser> getProfile() async {
    final result = await _connection.query(
      'SELECT id, name, email, city, level, green_score, total_recycled_kg, avatar_initials '
      'FROM app_users ORDER BY id LIMIT 1',
    );
    if (result.isEmpty) {
      throw StateError('No user profile data found in app_users.');
    }

    final row = result.first;
    return AppUser(
      id: row[0] as String,
      name: row[1] as String,
      email: row[2] as String,
      city: row[3] as String,
      level: row[4] as String,
      greenScore: _readInt(row[5]),
      totalRecycledKg: _readDouble(row[6]),
      avatarInitials: row[7] as String,
    );
  }

  @override
  Future<bool> pingDatabase() async {
    try {
      await _connection.query('SELECT 1');
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<ClassificationResult> classify(String itemName) async {
    final categories = await getCategories();
    final normalized = itemName.toLowerCase();
    final category = _matchCategory(normalized, categories);

    return ClassificationResult(
      itemName: itemName.trim(),
      category: category,
      confidence: _confidenceFor(normalized),
      suggestions: category.recyclingTips,
    );
  }

  WasteCategory _toWasteCategory(ResultRow row) {
    return WasteCategory(
      id: row[0] as String,
      title: row[1] as String,
      description: row[2] as String,
      binColor: row[3] as String,
      examples: _readStringList(row[4]),
      recyclingTips: _readStringList(row[5]),
    );
  }

  WasteCategory _matchCategory(String normalized, List<WasteCategory> categories) {
    if (_containsAny(normalized, ['battery', 'medicine', 'paint', 'pesticide'])) {
      return _categoryById(categories, 'hazardous');
    }
    if (_containsAny(normalized, ['food', 'banana', 'apple', 'leaf', 'peel'])) {
      return _categoryById(categories, 'organic');
    }
    if (_containsAny(normalized, ['tissue', 'ceramic', 'dust', 'dirty'])) {
      return _categoryById(categories, 'residual');
    }
    return _categoryById(categories, 'recyclable');
  }

  WasteCategory _categoryById(List<WasteCategory> categories, String id) {
    return categories.firstWhere((item) => item.id == id);
  }

  bool _containsAny(String text, List<String> keywords) {
    return keywords.any(text.contains);
  }

  double _confidenceFor(String normalized) {
    if (normalized.length < 3) {
      return 0.62;
    }
    if (_containsAny(normalized, [
      'bottle',
      'battery',
      'banana',
      'medicine',
      'cardboard',
      'glass',
      'tissue',
    ])) {
      return 0.94;
    }
    return 0.82;
  }

  List<String> _readStringList(Object? value) {
    if (value == null) {
      return const [];
    }
    final decoded = jsonDecode(value as String);
    if (decoded is! List) {
      return const [];
    }
    return decoded.map((item) => item.toString()).toList(growable: false);
  }

  int _readInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.parse(value.toString());
  }

  double _readDouble(Object? value) {
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.parse(value.toString());
  }

  bool _readBool(Object? value) {
    if (value is bool) {
      return value;
    }
    if (value is int) {
      return value == 1;
    }
    return value.toString() == '1' || value.toString().toLowerCase() == 'true';
  }

  @override
  Future<void> close() async {
    await _connection.close();
  }
}
