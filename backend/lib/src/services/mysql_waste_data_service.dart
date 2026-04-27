import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:mysql1/mysql1.dart';

import '../config/aliyun_config.dart';
import '../config/database_config.dart';
import '../models/app_models.dart';
import '../models/vision_models.dart';
import 'aliyun_vision_client.dart';
import 'waste_data_service.dart';

/// MySQL-backed implementation of [WasteDataService].
class MySqlWasteDataService implements WasteDataService {
  MySqlWasteDataService._({
    required DatabaseConfig config,
    required MySqlConnection connection,
    required AliyunConfig aliyunConfig,
  }) : _config = config,
       _connection = connection,
       _aliyunClient = aliyunConfig.isConfigured
           ? AliyunVisionClient(aliyunConfig)
           : null;

  final DatabaseConfig _config;
  final MySqlConnection _connection;
  final AliyunVisionClient? _aliyunClient;
  final Random _secureRandom = Random.secure();

  static const _defaultUserId = 'u1';

  /// Initializes schema/tables/seed-data and returns a ready service instance.
  static Future<MySqlWasteDataService> initialize(DatabaseConfig config) async {
    await _createDatabaseIfNeeded(config);
    final connection = await MySqlConnection.connect(
      config.toDatabaseConnectionSettings(),
    );

    final service = MySqlWasteDataService._(
      config: config,
      connection: connection,
      aliyunConfig: AliyunConfig.fromEnvironment(),
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
        author_id VARCHAR(32) NULL,
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
      CREATE TABLE IF NOT EXISTS forum_post_likes (
        post_id VARCHAR(32) NOT NULL,
        user_id VARCHAR(32) NOT NULL,
        created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (post_id, user_id),
        INDEX idx_forum_post_likes_user (user_id),
        CONSTRAINT fk_forum_post_likes_post
          FOREIGN KEY (post_id) REFERENCES forum_posts(id)
          ON DELETE CASCADE
      ) ENGINE=InnoDB DEFAULT CHARSET=${_config.charset}
    ''');

    await _connection.query('''
      CREATE TABLE IF NOT EXISTS forum_comments (
        id VARCHAR(40) PRIMARY KEY,
        post_id VARCHAR(32) NOT NULL,
        parent_comment_id VARCHAR(40) NULL,
        author_id VARCHAR(32) NULL,
        author VARCHAR(128) NOT NULL,
        content TEXT NOT NULL,
        likes INT NOT NULL DEFAULT 0,
        created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        INDEX idx_forum_comments_post_time (post_id, created_at DESC),
        INDEX idx_forum_comments_parent (parent_comment_id),
        CONSTRAINT fk_forum_comments_post
          FOREIGN KEY (post_id) REFERENCES forum_posts(id)
          ON DELETE CASCADE,
        CONSTRAINT fk_forum_comments_parent
          FOREIGN KEY (parent_comment_id) REFERENCES forum_comments(id)
          ON DELETE CASCADE
      ) ENGINE=InnoDB DEFAULT CHARSET=${_config.charset}
    ''');

    await _connection.query('''
      CREATE TABLE IF NOT EXISTS forum_comment_likes (
        comment_id VARCHAR(40) NOT NULL,
        user_id VARCHAR(32) NOT NULL,
        created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (comment_id, user_id),
        INDEX idx_forum_comment_likes_user (user_id),
        CONSTRAINT fk_forum_comment_likes_comment
          FOREIGN KEY (comment_id) REFERENCES forum_comments(id)
          ON DELETE CASCADE
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
        avatar_initials VARCHAR(16) NOT NULL,
        avatar_url TEXT NULL,
        password_hash VARCHAR(255) NOT NULL DEFAULT '',
        total_co2_reduction_kg DOUBLE NOT NULL DEFAULT 0
      ) ENGINE=InnoDB DEFAULT CHARSET=${_config.charset}
    ''');

    await _connection.query('''
      CREATE TABLE IF NOT EXISTS user_accounts (
        user_id VARCHAR(32) PRIMARY KEY,
        email VARCHAR(255) NOT NULL,
        password_hash VARCHAR(255) NOT NULL,
        created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        UNIQUE KEY uniq_user_accounts_email (email),
        CONSTRAINT fk_user_accounts_user
          FOREIGN KEY (user_id) REFERENCES app_users(id)
          ON DELETE CASCADE
      ) ENGINE=InnoDB DEFAULT CHARSET=${_config.charset}
    ''');

    await _connection.query('''
      CREATE TABLE IF NOT EXISTS auth_sessions (
        token VARCHAR(128) PRIMARY KEY,
        user_id VARCHAR(32) NOT NULL,
        expires_at DATETIME NOT NULL,
        created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        INDEX idx_auth_sessions_user (user_id),
        INDEX idx_auth_sessions_expires (expires_at),
        CONSTRAINT fk_auth_sessions_user
          FOREIGN KEY (user_id) REFERENCES app_users(id)
          ON DELETE CASCADE
      ) ENGINE=InnoDB DEFAULT CHARSET=${_config.charset}
    ''');

    await _connection.query('''
      CREATE TABLE IF NOT EXISTS chat_conversations (
        id VARCHAR(64) PRIMARY KEY,
        conversation_type VARCHAR(16) NOT NULL DEFAULT 'direct',
        latest_message_id BIGINT NULL,
        created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        INDEX idx_chat_conversations_updated (updated_at DESC)
      ) ENGINE=InnoDB DEFAULT CHARSET=${_config.charset}
    ''');

    await _connection.query('''
      CREATE TABLE IF NOT EXISTS chat_conversation_participants (
        conversation_id VARCHAR(64) NOT NULL,
        user_id VARCHAR(32) NOT NULL,
        joined_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        last_read_message_id BIGINT NULL,
        last_read_at DATETIME NULL,
        PRIMARY KEY (conversation_id, user_id),
        INDEX idx_chat_participants_user (user_id),
        CONSTRAINT fk_chat_participants_conversation
          FOREIGN KEY (conversation_id) REFERENCES chat_conversations(id)
          ON DELETE CASCADE,
        CONSTRAINT fk_chat_participants_user
          FOREIGN KEY (user_id) REFERENCES app_users(id)
      ) ENGINE=InnoDB DEFAULT CHARSET=${_config.charset}
    ''');

    await _connection.query('''
      CREATE TABLE IF NOT EXISTS chat_messages (
        id BIGINT PRIMARY KEY AUTO_INCREMENT,
        conversation_id VARCHAR(64) NOT NULL,
        sender_id VARCHAR(32) NOT NULL,
        message_type VARCHAR(16) NOT NULL,
        content MEDIUMTEXT NOT NULL,
        created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        INDEX idx_chat_messages_conversation_id (conversation_id, id),
        CONSTRAINT fk_chat_messages_conversation
          FOREIGN KEY (conversation_id) REFERENCES chat_conversations(id)
          ON DELETE CASCADE,
        CONSTRAINT fk_chat_messages_sender
          FOREIGN KEY (sender_id) REFERENCES app_users(id)
      ) ENGINE=InnoDB DEFAULT CHARSET=${_config.charset}
    ''');

    await _connection.query('''
      CREATE TABLE IF NOT EXISTS eco_action_catalog (
        id VARCHAR(32) PRIMARY KEY,
        title VARCHAR(255) NOT NULL,
        description TEXT NOT NULL,
        unit_label VARCHAR(64) NOT NULL,
        co2_kg_per_unit DOUBLE NOT NULL,
        points_per_unit INT NOT NULL,
        active TINYINT(1) NOT NULL DEFAULT 1
      ) ENGINE=InnoDB DEFAULT CHARSET=${_config.charset}
    ''');

    await _connection.query('''
      CREATE TABLE IF NOT EXISTS user_eco_action_records (
        id BIGINT PRIMARY KEY AUTO_INCREMENT,
        user_id VARCHAR(32) NOT NULL,
        catalog_action_id VARCHAR(32) NOT NULL,
        quantity DOUBLE NOT NULL,
        co2_reduction_kg DOUBLE NOT NULL,
        points_awarded INT NOT NULL,
        note VARCHAR(255) NULL,
        created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        INDEX idx_action_record_user_time (user_id, created_at DESC),
        CONSTRAINT fk_action_record_user
          FOREIGN KEY (user_id) REFERENCES app_users(id),
        CONSTRAINT fk_action_record_catalog
          FOREIGN KEY (catalog_action_id) REFERENCES eco_action_catalog(id)
      ) ENGINE=InnoDB DEFAULT CHARSET=${_config.charset}
    ''');

    await _connection.query('''
      CREATE TABLE IF NOT EXISTS badges (
        id VARCHAR(32) PRIMARY KEY,
        title VARCHAR(128) NOT NULL,
        description TEXT NOT NULL,
        required_points INT NOT NULL,
        icon VARCHAR(64) NOT NULL,
        active TINYINT(1) NOT NULL DEFAULT 1
      ) ENGINE=InnoDB DEFAULT CHARSET=${_config.charset}
    ''');

    await _connection.query('''
      CREATE TABLE IF NOT EXISTS user_badges (
        id BIGINT PRIMARY KEY AUTO_INCREMENT,
        user_id VARCHAR(32) NOT NULL,
        badge_id VARCHAR(32) NOT NULL,
        redeemed_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        UNIQUE KEY uniq_user_badge (user_id, badge_id),
        CONSTRAINT fk_user_badges_user
          FOREIGN KEY (user_id) REFERENCES app_users(id),
        CONSTRAINT fk_user_badges_badge
          FOREIGN KEY (badge_id) REFERENCES badges(id)
      ) ENGINE=InnoDB DEFAULT CHARSET=${_config.charset}
    ''');

    await _connection.query('''
      CREATE TABLE IF NOT EXISTS point_transactions (
        id BIGINT PRIMARY KEY AUTO_INCREMENT,
        user_id VARCHAR(32) NOT NULL,
        change_amount INT NOT NULL,
        transaction_type VARCHAR(32) NOT NULL,
        related_id VARCHAR(64) NULL,
        remark VARCHAR(255) NULL,
        created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        INDEX idx_point_tx_user_time (user_id, created_at DESC),
        CONSTRAINT fk_point_tx_user
          FOREIGN KEY (user_id) REFERENCES app_users(id)
      ) ENGINE=InnoDB DEFAULT CHARSET=${_config.charset}
    ''');

    await _ensureSchemaUpgrades();

    await _connection.query('''
      CREATE TABLE IF NOT EXISTS vision_classification_logs (
        id BIGINT PRIMARY KEY AUTO_INCREMENT,
        submitted_by VARCHAR(128) NULL,
        source_file_name VARCHAR(255) NOT NULL,
        image_url TEXT NOT NULL,
        request_id VARCHAR(128) NOT NULL,
        category_label VARCHAR(128) NOT NULL,
        category_score DOUBLE NOT NULL,
        rubbish_label VARCHAR(255) NOT NULL,
        rubbish_score DOUBLE NOT NULL,
        mapped_category_id VARCHAR(32) NOT NULL,
        mapped_category_title VARCHAR(128) NOT NULL,
        raw_response_json LONGTEXT NOT NULL,
        created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        INDEX idx_vision_logs_created (created_at DESC)
      ) ENGINE=InnoDB DEFAULT CHARSET=${_config.charset}
    ''');
  }

  Future<void> _ensureSchemaUpgrades() async {
    await _addColumnIfMissing(
      table: 'app_users',
      column: 'total_co2_reduction_kg',
      ddl: 'ALTER TABLE app_users ADD COLUMN total_co2_reduction_kg DOUBLE NOT NULL DEFAULT 0',
    );

    await _addColumnIfMissing(
      table: 'eco_action_catalog',
      column: 'active',
      ddl: 'ALTER TABLE eco_action_catalog ADD COLUMN active TINYINT(1) NOT NULL DEFAULT 1',
    );

    await _addColumnIfMissing(
      table: 'badges',
      column: 'active',
      ddl: 'ALTER TABLE badges ADD COLUMN active TINYINT(1) NOT NULL DEFAULT 1',
    );

    await _addColumnIfMissing(
      table: 'forum_posts',
      column: 'author_id',
      ddl: 'ALTER TABLE forum_posts ADD COLUMN author_id VARCHAR(32) NULL',
    );

    await _addColumnIfMissing(
      table: 'app_users',
      column: 'avatar_url',
      ddl: 'ALTER TABLE app_users ADD COLUMN avatar_url TEXT NULL',
    );

    await _addColumnIfMissing(
      table: 'app_users',
      column: 'password_hash',
      ddl: "ALTER TABLE app_users ADD COLUMN password_hash VARCHAR(255) NOT NULL DEFAULT ''",
    );

    await _backfillForumAuthorIds();
    await _upgradeChatMessageContentTypeIfNeeded();
  }

  Future<void> _backfillForumAuthorIds() async {
    await _connection.query(
      '''
      UPDATE forum_posts
      SET author_id = CASE author
        WHEN 'Mia Chen' THEN 'u2'
        WHEN 'Leo Wang' THEN 'u3'
        WHEN 'Ava Smith' THEN 'u4'
        ELSE author_id
      END
      WHERE author IN ('Mia Chen', 'Leo Wang', 'Ava Smith')
        AND (author_id IS NULL OR author_id = '' OR author_id = 'u1')
      ''',
    );
  }

  Future<void> _upgradeChatMessageContentTypeIfNeeded() async {
    final typeResult = await _connection.query(
      '''
      SELECT DATA_TYPE
      FROM INFORMATION_SCHEMA.COLUMNS
      WHERE TABLE_SCHEMA = ?
        AND TABLE_NAME = 'chat_messages'
        AND COLUMN_NAME = 'content'
      LIMIT 1
      ''',
      [_config.database],
    );
    if (typeResult.isEmpty) {
      return;
    }
    final dataType = _readText(typeResult.first[0]).toLowerCase();
    if (dataType == 'text') {
      await _connection.query(
        'ALTER TABLE chat_messages MODIFY content MEDIUMTEXT NOT NULL',
      );
    }
  }

  @override
  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final safeName = name.trim();
    final safeEmail = email.trim().toLowerCase();
    final safePassword = password.trim();
    if (safeName.isEmpty) {
      throw StateError('name is required.');
    }
    if (safeEmail.isEmpty) {
      throw StateError('email is required.');
    }
    if (!safeEmail.contains('@')) {
      throw StateError('email format is invalid.');
    }
    if (safePassword.length < 6) {
      throw StateError('password must be at least 6 characters.');
    }

    final exists = await _connection.query(
      'SELECT COUNT(*) AS count FROM user_accounts WHERE email = ?',
      [safeEmail],
    );
    if (_readInt(exists.first.fields['count']) > 0) {
      throw StateError('email already registered.');
    }

    final userId = _newUserId();
    final avatarInitials = _buildAvatarInitials(safeName);
    await _connection.transaction((tx) async {
      await tx.query(
        '''
        INSERT INTO app_users (
          id, name, email, city, level, green_score, total_recycled_kg, avatar_initials, total_co2_reduction_kg
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        [
          userId,
          safeName,
          safeEmail,
          'Shanghai',
          'Eco Beginner',
          0,
          0.0,
          avatarInitials,
          0.0,
        ],
      );
      await tx.query(
        '''
        INSERT INTO user_accounts (user_id, email, password_hash, created_at)
        VALUES (?, ?, ?, NOW())
        ''',
        [userId, safeEmail, _hashPassword(safePassword)],
      );
    });

    final user = (await _getUserById(userId))!;
    return _createSessionForUser(user.id);
  }

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final safeEmail = email.trim().toLowerCase();
    final safePassword = password.trim();
    if (safeEmail.isEmpty || safePassword.isEmpty) {
      throw StateError('email and password are required.');
    }

    final result = await _connection.query(
      '''
      SELECT user_id, password_hash
      FROM user_accounts
      WHERE email = ?
      LIMIT 1
      ''',
      [safeEmail],
    );
    if (result.isEmpty) {
      throw StateError('Invalid email or password.');
    }

    final row = result.first;
    final userId = _readText(row[0]);
    final storedHash = _readText(row[1]);
    if (!_verifyPassword(safePassword, storedHash)) {
      throw StateError('Invalid email or password.');
    }

    return _createSessionForUser(userId);
  }

  @override
  Future<AppUser> requireUserByToken(String token) async {
    final safeToken = token.trim();
    if (safeToken.isEmpty) {
      throw StateError('Authorization token is required.');
    }

    final result = await _connection.query(
      '''
      SELECT user_id
      FROM auth_sessions
      WHERE token = ?
        AND expires_at > NOW()
      LIMIT 1
      ''',
      [safeToken],
    );
    if (result.isEmpty) {
      throw StateError('Unauthorized. Please login again.');
    }
    final userId = _readText(result.first[0]);
    final user = await _getUserById(userId);
    if (user == null) {
      throw StateError('User not found.');
    }
    return user;
  }

  Future<void> _addColumnIfMissing({
    required String table,
    required String column,
    required String ddl,
  }) async {
    final exists = await _columnExists(table: table, column: column);
    if (!exists) {
      await _connection.query(ddl);
    }
  }

  Future<bool> _columnExists({
    required String table,
    required String column,
  }) async {
    final result = await _connection.query(
      '''
      SELECT COUNT(*) AS count
      FROM INFORMATION_SCHEMA.COLUMNS
      WHERE TABLE_SCHEMA = ?
        AND TABLE_NAME = ?
        AND COLUMN_NAME = ?
      ''',
      [_config.database, table, column],
    );
    return _readInt(result.first.fields['count']) > 0;
  }

  Future<void> _seedDataIfNeeded() async {
    await _seedCategoriesIfNeeded();
    await _seedEcoActionsIfNeeded();
    await _seedRewardsIfNeeded();
    await _seedForumPostsIfNeeded();
    await _seedMessagesIfNeeded();
    await _seedProfileIfNeeded();
    await _seedDefaultAccountIfNeeded();
    await _seedAdditionalUsersIfNeeded();
    await _seedAdditionalAccountsIfNeeded();
    await _seedChatIfNeeded();
    await _seedEcoActionCatalogIfNeeded();
    await _seedBadgesIfNeeded();
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
    final result = await _connection.query(
      'SELECT COUNT(*) AS count FROM eco_actions',
    );
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
        authorId: 'u2',
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
        authorId: 'u3',
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
        authorId: 'u4',
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
          id, author_id, author, title, content, tag, likes, replies, created_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        [
          item.id,
          item.authorId,
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
      id: _defaultUserId,
      name: 'Alex Green',
      email: 'alex.green@example.com',
      city: 'Shanghai',
      level: 'Eco Pioneer',
      greenScore: 836,
      totalRecycledKg: 48.5,
      avatarInitials: 'AG',
      totalCo2ReductionKg: 12.4,
    );

    await _connection.query(
      '''
      INSERT INTO app_users (
        id, name, email, city, level, green_score, total_recycled_kg, avatar_initials, avatar_url, password_hash, total_co2_reduction_kg
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
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
        null,
        '',
        user.totalCo2ReductionKg,
      ],
    );
  }

  Future<void> _seedDefaultAccountIfNeeded() async {
    await _upsertAccount(
      userId: _defaultUserId,
      email: 'alex.green@example.com',
      password: '123456',
    );
  }

  Future<void> _seedAdditionalUsersIfNeeded() async {
    const users = [
      AppUser(
        id: 'u2',
        name: 'Mia Chen',
        email: 'mia.chen@example.com',
        city: 'Shanghai',
        level: 'Eco Contributor',
        greenScore: 420,
        totalRecycledKg: 21.8,
        avatarInitials: 'MC',
        totalCo2ReductionKg: 5.6,
      ),
      AppUser(
        id: 'u3',
        name: 'Leo Wang',
        email: 'leo.wang@example.com',
        city: 'Shanghai',
        level: 'Eco Partner',
        greenScore: 368,
        totalRecycledKg: 18.2,
        avatarInitials: 'LW',
        totalCo2ReductionKg: 4.2,
      ),
      AppUser(
        id: 'u4',
        name: 'Ava Smith',
        email: 'ava.smith@example.com',
        city: 'Shanghai',
        level: 'Eco Volunteer',
        greenScore: 512,
        totalRecycledKg: 26.4,
        avatarInitials: 'AS',
        totalCo2ReductionKg: 7.1,
      ),
    ];

    for (final user in users) {
      final exists = await _connection.query(
        'SELECT COUNT(*) AS count FROM app_users WHERE id = ?',
        [user.id],
      );
      if (_readInt(exists.first.fields['count']) > 0) {
        continue;
      }
      await _connection.query(
        '''
        INSERT INTO app_users (
          id, name, email, city, level, green_score, total_recycled_kg, avatar_initials, avatar_url, password_hash, total_co2_reduction_kg
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
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
          null,
          '',
          user.totalCo2ReductionKg,
        ],
      );
    }
  }

  Future<void> _seedAdditionalAccountsIfNeeded() async {
    await _upsertAccount(
      userId: 'u2',
      email: 'mia.chen@example.com',
      password: '123456',
    );
    await _upsertAccount(
      userId: 'u3',
      email: 'leo.wang@example.com',
      password: '123456',
    );
    await _upsertAccount(
      userId: 'u4',
      email: 'ava.smith@example.com',
      password: '123456',
    );
  }

  Future<void> _seedChatIfNeeded() async {
    final countResult = await _connection.query(
      'SELECT COUNT(*) AS count FROM chat_messages',
    );
    if (_readInt(countResult.first.fields['count']) > 0) {
      return;
    }

    Future<void> seedDirectConversation({
      required String conversationId,
      required String userA,
      required String userB,
      required List<_SeedChatMessage> messages,
    }) async {
      await _connection.query(
        '''
        INSERT IGNORE INTO chat_conversations (id, conversation_type, latest_message_id, created_at, updated_at)
        VALUES (?, 'direct', NULL, NOW(), NOW())
        ''',
        [conversationId],
      );

      await _connection.query(
        '''
        INSERT IGNORE INTO chat_conversation_participants (
          conversation_id, user_id, joined_at, last_read_message_id, last_read_at
        ) VALUES (?, ?, NOW(), NULL, NULL)
        ''',
        [conversationId, userA],
      );
      await _connection.query(
        '''
        INSERT IGNORE INTO chat_conversation_participants (
          conversation_id, user_id, joined_at, last_read_message_id, last_read_at
        ) VALUES (?, ?, NOW(), NULL, NULL)
        ''',
        [conversationId, userB],
      );

      int? latestId;
      for (final message in messages) {
        final insert = await _connection.query(
          '''
          INSERT INTO chat_messages (conversation_id, sender_id, message_type, content, created_at)
          VALUES (?, ?, ?, ?, ?)
          ''',
          [
            conversationId,
            message.senderId,
            message.messageType,
            message.content,
            message.createdAt,
          ],
        );
        latestId = _readInt(insert.insertId);
      }

      if (latestId != null) {
        await _connection.query(
          '''
          UPDATE chat_conversations
          SET latest_message_id = ?, updated_at = NOW()
          WHERE id = ?
          ''',
          [latestId, conversationId],
        );
      }
    }

    await seedDirectConversation(
      conversationId: _buildDirectConversationId('u1', 'u2'),
      userA: 'u1',
      userB: 'u2',
      messages: const [
        _SeedChatMessage(
          senderId: 'u2',
          messageType: 'text',
          content: 'Hi! Do you know where to dispose oily takeaway boxes?',
          createdAt: '2026-04-27 10:12:00',
        ),
        _SeedChatMessage(
          senderId: 'u1',
          messageType: 'text',
          content: 'Usually residual waste. If clean, paper recycle bin.',
          createdAt: '2026-04-27 10:13:40',
        ),
      ],
    );

    await seedDirectConversation(
      conversationId: _buildDirectConversationId('u1', 'u3'),
      userA: 'u1',
      userB: 'u3',
      messages: const [
        _SeedChatMessage(
          senderId: 'u3',
          messageType: 'image',
          content:
              'https://images.unsplash.com/photo-1605600659873-d808a13e4f2a?w=1200',
          createdAt: '2026-04-27 09:05:00',
        ),
      ],
    );

    await seedDirectConversation(
      conversationId: _buildDirectConversationId('u1', 'u4'),
      userA: 'u1',
      userB: 'u4',
      messages: const [
        _SeedChatMessage(
          senderId: 'u4',
          messageType: 'text',
          content: 'Battery collection point has moved near the library.',
          createdAt: '2026-04-26 20:01:12',
        ),
      ],
    );

    await _connection.query(
      '''
      UPDATE chat_conversation_participants p
      INNER JOIN (
        SELECT conversation_id, MAX(id) AS latest_id
        FROM chat_messages
        GROUP BY conversation_id
      ) m ON m.conversation_id = p.conversation_id
      SET
        p.last_read_message_id = CASE
          WHEN p.user_id = ? THEN m.latest_id
          ELSE NULL
        END,
        p.last_read_at = CASE
          WHEN p.user_id = ? THEN NOW()
          ELSE NULL
        END
      ''',
      [_defaultUserId, _defaultUserId],
    );
  }

  Future<void> _seedEcoActionCatalogIfNeeded() async {
    final result = await _connection.query(
      'SELECT COUNT(*) AS count FROM eco_action_catalog',
    );
    final count = _readInt(result.first.fields['count']);
    if (count > 0) {
      return;
    }

    const data = [
      EcoActionCatalogItem(
        id: 'reuse_bag',
        title: 'Use Reusable Shopping Bag',
        description: 'Replace single-use plastic bags with reusable bags.',
        unitLabel: 'times',
        co2KgPerUnit: 0.06,
        pointsPerUnit: 3,
        active: true,
      ),
      EcoActionCatalogItem(
        id: 'bus_commute',
        title: 'Take Bus Instead of Car',
        description: 'Choose public transportation for daily commute.',
        unitLabel: 'km',
        co2KgPerUnit: 0.14,
        pointsPerUnit: 2,
        active: true,
      ),
      EcoActionCatalogItem(
        id: 'recycle_paper',
        title: 'Recycle Paper Waste',
        description: 'Sort and recycle clean paper products.',
        unitLabel: 'kg',
        co2KgPerUnit: 0.9,
        pointsPerUnit: 8,
        active: true,
      ),
      EcoActionCatalogItem(
        id: 'recycle_plastic',
        title: 'Recycle Plastic Packaging',
        description: 'Clean and place recyclable plastic in correct bin.',
        unitLabel: 'kg',
        co2KgPerUnit: 1.7,
        pointsPerUnit: 12,
        active: true,
      ),
      EcoActionCatalogItem(
        id: 'food_waste_compost',
        title: 'Compost Food Waste',
        description: 'Separate kitchen waste for composting.',
        unitLabel: 'kg',
        co2KgPerUnit: 0.45,
        pointsPerUnit: 6,
        active: true,
      ),
    ];

    for (final item in data) {
      await _connection.query(
        '''
        INSERT INTO eco_action_catalog (
          id, title, description, unit_label, co2_kg_per_unit, points_per_unit, active
        ) VALUES (?, ?, ?, ?, ?, ?, ?)
        ''',
        [
          item.id,
          item.title,
          item.description,
          item.unitLabel,
          item.co2KgPerUnit,
          item.pointsPerUnit,
          item.active ? 1 : 0,
        ],
      );
    }
  }

  Future<void> _seedBadgesIfNeeded() async {
    final result = await _connection.query('SELECT COUNT(*) AS count FROM badges');
    final count = _readInt(result.first.fields['count']);
    if (count > 0) {
      return;
    }

    const data = [
      Badge(
        id: 'bronze_guardian',
        title: 'Bronze Carbon Guardian',
        description: 'Awarded to users reaching 100 points.',
        requiredPoints: 100,
        icon: 'B',
        redeemed: false,
        redeemable: false,
      ),
      Badge(
        id: 'silver_guardian',
        title: 'Silver Carbon Guardian',
        description: 'Awarded to users reaching 250 points.',
        requiredPoints: 250,
        icon: 'S',
        redeemed: false,
        redeemable: false,
      ),
      Badge(
        id: 'gold_guardian',
        title: 'Gold Carbon Guardian',
        description: 'Awarded to users reaching 500 points.',
        requiredPoints: 500,
        icon: 'G',
        redeemed: false,
        redeemable: false,
      ),
    ];

    for (final item in data) {
      await _connection.query(
        'INSERT INTO badges (id, title, description, required_points, icon, active) '
        'VALUES (?, ?, ?, ?, ?, ?)',
        [
          item.id,
          item.title,
          item.description,
          item.requiredPoints,
          item.icon,
          1,
        ],
      );
    }
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
      '''
      SELECT
        p.id,
        COALESCE(p.author_id, '') AS author_id,
        p.author,
        p.title,
        p.content,
        p.tag,
        p.likes,
        (
          SELECT COUNT(*)
          FROM forum_comments c
          WHERE c.post_id = p.id
        ) AS replies,
        p.created_at,
        EXISTS(
          SELECT 1
          FROM forum_post_likes l
          WHERE l.post_id = p.id AND l.user_id = ?
        ) AS liked_by_me
      FROM forum_posts p
      ORDER BY p.created_at DESC
      ''',
      [_defaultUserId],
    );

    return result
        .map(
          (row) => ForumPost(
            id: _readText(row[0]),
            authorId: _readText(row[1]),
            author: _readText(row[2]),
            title: _readText(row[3]),
            content: _readText(row[4]),
            tag: _readText(row[5]),
            likes: _readInt(row[6]),
            replies: _readInt(row[7]),
            createdAt: _readText(row[8]),
            likedByMe: _readBool(row[9]),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<ForumPost> createForumPost({
    required String authorId,
    required String title,
    required String content,
    required String tag,
  }) async {
    final user = await _getUserById(authorId);
    if (user == null) {
      throw StateError('User not found: $authorId');
    }

    final postId = _newPostId();
    final safeTitle = title.trim();
    final safeContent = content.trim();
    final safeTag = tag.trim().isEmpty ? 'General' : tag.trim();

    if (safeTitle.isEmpty || safeContent.isEmpty) {
      throw StateError('title and content are required.');
    }

    await _connection.query(
      '''
      INSERT INTO forum_posts (
        id, author_id, author, title, content, tag, likes, replies, created_at
      ) VALUES (?, ?, ?, ?, ?, ?, 0, 0, ?)
      ''',
      [
        postId,
        authorId,
        user.name,
        safeTitle,
        safeContent,
        safeTag,
        _nowAsString(),
      ],
    );

    final posts = await getForumPosts();
    return posts.firstWhere((item) => item.id == postId);
  }

  @override
  Future<ForumPost> toggleForumPostLike({
    required String postId,
    required String userId,
  }) async {
    final postExists = await _connection.query(
      'SELECT COUNT(*) AS count FROM forum_posts WHERE id = ?',
      [postId],
    );
    if (_readInt(postExists.first.fields['count']) == 0) {
      throw StateError('Forum post not found: $postId');
    }

    await _connection.transaction((tx) async {
      final liked = await tx.query(
        'SELECT COUNT(*) AS count FROM forum_post_likes WHERE post_id = ? AND user_id = ?',
        [postId, userId],
      );
      final hasLiked = _readInt(liked.first.fields['count']) > 0;
      if (hasLiked) {
        await tx.query(
          'DELETE FROM forum_post_likes WHERE post_id = ? AND user_id = ?',
          [postId, userId],
        );
        await tx.query(
          'UPDATE forum_posts SET likes = GREATEST(likes - 1, 0) WHERE id = ?',
          [postId],
        );
      } else {
        await tx.query(
          'INSERT INTO forum_post_likes (post_id, user_id) VALUES (?, ?)',
          [postId, userId],
        );
        await tx.query(
          'UPDATE forum_posts SET likes = likes + 1 WHERE id = ?',
          [postId],
        );
      }
    });

    final posts = await getForumPosts();
    return posts.firstWhere((item) => item.id == postId);
  }

  @override
  Future<List<ForumComment>> getForumComments({
    required String postId,
    String? userId,
  }) async {
    final viewer = (userId?.trim().isNotEmpty ?? false) ? userId!.trim() : _defaultUserId;
    final rows = await _connection.query(
      '''
      SELECT
        c.id,
        c.post_id,
        c.parent_comment_id,
        COALESCE(c.author_id, '') AS author_id,
        c.author,
        c.content,
        c.likes,
        DATE_FORMAT(c.created_at, '%Y-%m-%d %H:%i:%s') AS created_at,
        EXISTS(
          SELECT 1
          FROM forum_comment_likes l
          WHERE l.comment_id = c.id AND l.user_id = ?
        ) AS liked_by_me
      FROM forum_comments c
      WHERE c.post_id = ?
      ORDER BY c.created_at ASC, c.id ASC
      ''',
      [viewer, postId],
    );

    final flat = rows
        .map(
          (row) => ForumComment(
            id: _readText(row[0]),
            postId: _readText(row[1]),
            parentCommentId: _readNullableText(row[2]),
            authorId: _readText(row[3]),
            author: _readText(row[4]),
            content: _readText(row[5]),
            likes: _readInt(row[6]),
            createdAt: _readText(row[7]),
            likedByMe: _readBool(row[8]),
          ),
        )
        .toList(growable: false);

    return _buildCommentTree(flat);
  }

  @override
  Future<ForumComment> createForumComment({
    required String postId,
    required String authorId,
    required String content,
    String? parentCommentId,
  }) async {
    final postExists = await _connection.query(
      'SELECT COUNT(*) AS count FROM forum_posts WHERE id = ?',
      [postId],
    );
    if (_readInt(postExists.first.fields['count']) == 0) {
      throw StateError('Forum post not found: $postId');
    }

    final user = await _getUserById(authorId);
    if (user == null) {
      throw StateError('User not found: $authorId');
    }

    final safeContent = content.trim();
    if (safeContent.isEmpty) {
      throw StateError('Comment content is required.');
    }

    final safeParentId =
        parentCommentId?.trim().isEmpty ?? true ? null : parentCommentId!.trim();
    if (safeParentId != null) {
      final parentExists = await _connection.query(
        'SELECT COUNT(*) AS count FROM forum_comments WHERE id = ? AND post_id = ?',
        [safeParentId, postId],
      );
      if (_readInt(parentExists.first.fields['count']) == 0) {
        throw StateError('Parent comment not found for this post.');
      }
    }

    final commentId = _newCommentId();
    await _connection.query(
      '''
      INSERT INTO forum_comments (
        id, post_id, parent_comment_id, author_id, author, content, likes, created_at
      ) VALUES (?, ?, ?, ?, ?, ?, 0, ?)
      ''',
      [
        commentId,
        postId,
        safeParentId,
        authorId,
        user.name,
        safeContent,
        _nowAsString(),
      ],
    );

    await _connection.query(
      '''
      UPDATE forum_posts p
      SET p.replies = (
        SELECT COUNT(*)
        FROM forum_comments c
        WHERE c.post_id = p.id
      )
      WHERE p.id = ?
      ''',
      [postId],
    );

    final rows = await _connection.query(
      '''
      SELECT
        id,
        post_id,
        parent_comment_id,
        COALESCE(author_id, '') AS author_id,
        author,
        content,
        likes,
        DATE_FORMAT(created_at, '%Y-%m-%d %H:%i:%s') AS created_at
      FROM forum_comments
      WHERE id = ?
      LIMIT 1
      ''',
      [commentId],
    );
    final row = rows.first;
    return ForumComment(
      id: _readText(row[0]),
      postId: _readText(row[1]),
      parentCommentId: _readNullableText(row[2]),
      authorId: _readText(row[3]),
      author: _readText(row[4]),
      content: _readText(row[5]),
      likes: _readInt(row[6]),
      createdAt: _readText(row[7]),
      likedByMe: false,
    );
  }

  @override
  Future<ForumComment> toggleForumCommentLike({
    required String commentId,
    required String userId,
  }) async {
    final commentRows = await _connection.query(
      'SELECT id, post_id FROM forum_comments WHERE id = ? LIMIT 1',
      [commentId],
    );
    if (commentRows.isEmpty) {
      throw StateError('Forum comment not found: $commentId');
    }

    await _connection.transaction((tx) async {
      final liked = await tx.query(
        'SELECT COUNT(*) AS count FROM forum_comment_likes WHERE comment_id = ? AND user_id = ?',
        [commentId, userId],
      );
      final hasLiked = _readInt(liked.first.fields['count']) > 0;
      if (hasLiked) {
        await tx.query(
          'DELETE FROM forum_comment_likes WHERE comment_id = ? AND user_id = ?',
          [commentId, userId],
        );
        await tx.query(
          'UPDATE forum_comments SET likes = GREATEST(likes - 1, 0) WHERE id = ?',
          [commentId],
        );
      } else {
        await tx.query(
          'INSERT INTO forum_comment_likes (comment_id, user_id) VALUES (?, ?)',
          [commentId, userId],
        );
        await tx.query(
          'UPDATE forum_comments SET likes = likes + 1 WHERE id = ?',
          [commentId],
        );
      }
    });

    final row = await _connection.query(
      '''
      SELECT
        c.id,
        c.post_id,
        c.parent_comment_id,
        COALESCE(c.author_id, '') AS author_id,
        c.author,
        c.content,
        c.likes,
        DATE_FORMAT(c.created_at, '%Y-%m-%d %H:%i:%s') AS created_at,
        EXISTS(
          SELECT 1
          FROM forum_comment_likes l
          WHERE l.comment_id = c.id AND l.user_id = ?
        ) AS liked_by_me
      FROM forum_comments c
      WHERE c.id = ?
      LIMIT 1
      ''',
      [userId, commentId],
    );

    final item = row.first;
    return ForumComment(
      id: _readText(item[0]),
      postId: _readText(item[1]),
      parentCommentId: _readNullableText(item[2]),
      authorId: _readText(item[3]),
      author: _readText(item[4]),
      content: _readText(item[5]),
      likes: _readInt(item[6]),
      createdAt: _readText(item[7]),
      likedByMe: _readBool(item[8]),
    );
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
  Future<List<ChatConversationSummary>> getChatConversations({
    required String userId,
  }) async {
    final user = await _getUserById(userId);
    if (user == null) {
      throw StateError('User not found: $userId');
    }

    final result = await _connection.query(
      '''
      SELECT
        c.id AS conversation_id,
        peer.id AS peer_user_id,
        peer.name AS peer_name,
        peer.avatar_initials AS peer_avatar_initials,
        m.message_type,
        m.content,
        DATE_FORMAT(m.created_at, '%Y-%m-%d %H:%i:%s') AS latest_created_at,
        (
          SELECT COUNT(*)
          FROM chat_messages um
          WHERE um.conversation_id = c.id
            AND um.id > COALESCE(self.last_read_message_id, 0)
            AND um.sender_id <> ?
        ) AS unread_count
      FROM chat_conversations c
      INNER JOIN chat_conversation_participants self
        ON self.conversation_id = c.id
       AND self.user_id = ?
      INNER JOIN chat_conversation_participants peer_participant
        ON peer_participant.conversation_id = c.id
       AND peer_participant.user_id <> ?
      INNER JOIN app_users peer
        ON peer.id = peer_participant.user_id
      LEFT JOIN chat_messages m
        ON m.id = c.latest_message_id
      WHERE c.conversation_type = 'direct'
      ORDER BY c.updated_at DESC
      ''',
      [userId, userId, userId],
    );

    return result.map((row) {
      final messageType = _readText(row[4]);
      final content = _readText(row[5]);
      final preview = messageType == 'image'
          ? '[Image]'
          : (content.length > 120 ? '${content.substring(0, 120)}...' : content);
      return ChatConversationSummary(
        id: _readText(row[0]),
        peerUserId: _readText(row[1]),
        peerName: _readText(row[2]),
        peerAvatarInitials: _readText(row[3]),
        preview: preview,
        updatedAt: _readText(row[6]),
        unreadCount: _readInt(row[7]),
        latestMessageType: messageType.isEmpty ? 'text' : messageType,
      );
    }).toList(growable: false);
  }

  @override
  Future<String> getOrCreateDirectConversation({
    required String userId,
    required String peerUserId,
  }) async {
    if (userId == peerUserId) {
      throw StateError('Cannot create conversation with yourself.');
    }
    final user = await _getUserById(userId);
    if (user == null) {
      throw StateError('User not found: $userId');
    }
    final peer = await _getUserById(peerUserId);
    if (peer == null) {
      throw StateError('Peer user not found: $peerUserId');
    }

    final conversationId = _buildDirectConversationId(userId, peerUserId);
    await _connection.transaction((tx) async {
      await tx.query(
        '''
        INSERT IGNORE INTO chat_conversations (
          id, conversation_type, latest_message_id, created_at, updated_at
        ) VALUES (?, 'direct', NULL, NOW(), NOW())
        ''',
        [conversationId],
      );
      await tx.query(
        '''
        INSERT IGNORE INTO chat_conversation_participants (
          conversation_id, user_id, joined_at, last_read_message_id, last_read_at
        ) VALUES (?, ?, NOW(), NULL, NULL)
        ''',
        [conversationId, userId],
      );
      await tx.query(
        '''
        INSERT IGNORE INTO chat_conversation_participants (
          conversation_id, user_id, joined_at, last_read_message_id, last_read_at
        ) VALUES (?, ?, NOW(), NULL, NULL)
        ''',
        [conversationId, peerUserId],
      );
    });

    return conversationId;
  }

  @override
  Future<List<ChatMessage>> getChatMessages({
    required String userId,
    required String conversationId,
    int? afterMessageId,
    int limit = 50,
  }) async {
    final inConversation = await _connection.query(
      '''
      SELECT COUNT(*) AS count
      FROM chat_conversation_participants
      WHERE conversation_id = ? AND user_id = ?
      ''',
      [conversationId, userId],
    );
    if (_readInt(inConversation.first.fields['count']) == 0) {
      throw StateError('Conversation not found or access denied.');
    }

    final safeLimit = limit.clamp(1, 200);
    final result = await _connection.query(
      '''
      SELECT
        m.id,
        m.conversation_id,
        m.sender_id,
        u.name AS sender_name,
        u.avatar_initials AS sender_avatar_initials,
        m.message_type,
        m.content,
        DATE_FORMAT(m.created_at, '%Y-%m-%d %H:%i:%s') AS created_at
      FROM chat_messages m
      INNER JOIN app_users u ON u.id = m.sender_id
      WHERE m.conversation_id = ?
        AND (? IS NULL OR m.id > ?)
      ORDER BY m.id ASC
      LIMIT ?
      ''',
      [conversationId, afterMessageId, afterMessageId, safeLimit],
    );

    return result
        .map(
          (row) => ChatMessage(
            id: _readInt(row[0]),
            conversationId: _readText(row[1]),
            senderId: _readText(row[2]),
            senderName: _readText(row[3]),
            senderAvatarInitials: _readText(row[4]),
            messageType: _readText(row[5]),
            content: _readText(row[6]),
            createdAt: _readText(row[7]),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<ChatMessage> sendChatTextMessage({
    required String userId,
    required String conversationId,
    required String content,
  }) async {
    return _sendChatMessage(
      userId: userId,
      conversationId: conversationId,
      messageType: 'text',
      content: content,
    );
  }

  @override
  Future<ChatMessage> sendChatImageMessage({
    required String userId,
    required String conversationId,
    required String imageUrl,
  }) async {
    return _sendChatMessage(
      userId: userId,
      conversationId: conversationId,
      messageType: 'image',
      content: imageUrl,
    );
  }

  @override
  Future<void> markConversationRead({
    required String userId,
    required String conversationId,
  }) async {
    final participant = await _connection.query(
      '''
      SELECT COUNT(*) AS count
      FROM chat_conversation_participants
      WHERE conversation_id = ? AND user_id = ?
      ''',
      [conversationId, userId],
    );
    if (_readInt(participant.first.fields['count']) == 0) {
      throw StateError('Conversation not found or access denied.');
    }

    await _connection.query(
      '''
      UPDATE chat_conversation_participants p
      LEFT JOIN (
        SELECT conversation_id, MAX(id) AS latest_id
        FROM chat_messages
        WHERE conversation_id = ?
        GROUP BY conversation_id
      ) m ON m.conversation_id = p.conversation_id
      SET
        p.last_read_message_id = m.latest_id,
        p.last_read_at = NOW()
      WHERE p.conversation_id = ? AND p.user_id = ?
      ''',
      [conversationId, conversationId, userId],
    );
  }

  @override
  Future<AppUser> getProfile({required String userId}) async {
    final user = await _getUserById(userId);
    if (user == null) {
      throw StateError('No user profile data found in app_users.');
    }
    return user;
  }

  @override
  Future<AppUser> updateProfile({
    required String userId,
    required String name,
    required String email,
    required String city,
  }) async {
    final safeName = name.trim();
    final safeEmail = email.trim().toLowerCase();
    final safeCity = city.trim();
    if (safeName.isEmpty || safeEmail.isEmpty || safeCity.isEmpty) {
      throw StateError('name, email and city are required.');
    }
    if (!safeEmail.contains('@')) {
      throw StateError('email format is invalid.');
    }

    final user = await _getUserById(userId);
    if (user == null) {
      throw StateError('User not found: $userId');
    }

    final duplicate = await _connection.query(
      '''
      SELECT user_id
      FROM user_accounts
      WHERE email = ? AND user_id <> ?
      LIMIT 1
      ''',
      [safeEmail, userId],
    );
    if (duplicate.isNotEmpty) {
      throw StateError('email already registered by another account.');
    }

    await _connection.transaction((tx) async {
      await tx.query(
        '''
        UPDATE app_users
        SET
          name = ?,
          email = ?,
          city = ?,
          avatar_initials = ?
        WHERE id = ?
        ''',
        [safeName, safeEmail, safeCity, _initialsFromName(safeName), userId],
      );

      await tx.query(
        '''
        UPDATE user_accounts
        SET email = ?
        WHERE user_id = ?
        ''',
        [safeEmail, userId],
      );
    });

    final updated = await _getUserById(userId);
    if (updated == null) {
      throw StateError('Failed to load updated profile.');
    }
    return updated;
  }

  @override
  Future<void> updateAvatar({
    required String userId,
    required String avatarUrl,
  }) async {
    final safeUrl = avatarUrl.trim();
    if (safeUrl.isEmpty) {
      throw StateError('avatarUrl is required.');
    }
    final user = await _getUserById(userId);
    if (user == null) {
      throw StateError('User not found: $userId');
    }
    await _connection.query(
      'UPDATE app_users SET avatar_url = ? WHERE id = ?',
      [safeUrl, userId],
    );
  }

  @override
  Future<void> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    final safeCurrent = currentPassword.trim();
    final safeNew = newPassword.trim();
    if (safeCurrent.isEmpty || safeNew.isEmpty) {
      throw StateError('currentPassword and newPassword are required.');
    }
    if (safeNew.length < 6) {
      throw StateError('newPassword must be at least 6 characters.');
    }

    final rows = await _connection.query(
      '''
      SELECT password_hash
      FROM user_accounts
      WHERE user_id = ?
      LIMIT 1
      ''',
      [userId],
    );
    if (rows.isEmpty) {
      throw StateError('User not found: $userId');
    }
    final storedHash = _readText(rows.first[0]);
    if (!_verifyPassword(safeCurrent, storedHash)) {
      throw StateError('Current password is incorrect.');
    }

    final nextHash = _hashPassword(safeNew);
    await _connection.query(
      '''
      UPDATE user_accounts
      SET password_hash = ?
      WHERE user_id = ?
      ''',
      [nextHash, userId],
    );
  }

  @override
  Future<List<UserRecognitionRecord>> getRecognitionHistory({
    required String userId,
    int limit = 50,
  }) async {
    final safeLimit = limit.clamp(1, 200);
    final result = await _connection.query(
      '''
      SELECT
        id,
        source_file_name,
        image_url,
        mapped_category_title,
        rubbish_label,
        rubbish_score,
        DATE_FORMAT(created_at, '%Y-%m-%d %H:%i:%s') AS created_at
      FROM vision_classification_logs
      WHERE submitted_by = ?
      ORDER BY created_at DESC
      LIMIT ?
      ''',
      [userId, safeLimit],
    );

    return result
        .map(
          (row) => UserRecognitionRecord(
            id: _readInt(row[0]),
            fileName: _readText(row[1]),
            imageUrl: _readText(row[2]),
            categoryLabel: _readText(row[3]),
            rubbishLabel: _readText(row[4]),
            confidence: _readDouble(row[5]),
            createdAt: _readText(row[6]),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<List<UserPointHistoryRecord>> getPointHistory({
    required String userId,
    int limit = 50,
  }) async {
    final safeLimit = limit.clamp(1, 300);
    final result = await _connection.query(
      '''
      SELECT
        id,
        user_id,
        change_amount,
        transaction_type,
        related_id,
        remark,
        DATE_FORMAT(created_at, '%Y-%m-%d %H:%i:%s') AS created_at
      FROM point_transactions
      WHERE user_id = ?
      ORDER BY created_at DESC
      LIMIT ?
      ''',
      [userId, safeLimit],
    );

    return result
        .map(
          (row) => UserPointHistoryRecord(
            id: _readInt(row[0]),
            userId: _readText(row[1]),
            changeAmount: _readInt(row[2]),
            transactionType: _readText(row[3]),
            relatedId: _readNullableText(row[4]),
            remark: _readNullableText(row[5]),
            createdAt: _readText(row[6]),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<List<UserBadgeHistoryRecord>> getBadgeHistory({
    required String userId,
    int limit = 50,
  }) async {
    final safeLimit = limit.clamp(1, 300);
    final result = await _connection.query(
      '''
      SELECT
        ub.id,
        ub.user_id,
        ub.badge_id,
        b.title,
        b.icon,
        b.required_points,
        DATE_FORMAT(ub.redeemed_at, '%Y-%m-%d %H:%i:%s') AS redeemed_at
      FROM user_badges ub
      INNER JOIN badges b ON b.id = ub.badge_id
      WHERE ub.user_id = ?
      ORDER BY ub.redeemed_at DESC
      LIMIT ?
      ''',
      [userId, safeLimit],
    );

    return result
        .map(
          (row) => UserBadgeHistoryRecord(
            id: _readInt(row[0]),
            userId: _readText(row[1]),
            badgeId: _readText(row[2]),
            badgeTitle: _readText(row[3]),
            badgeIcon: _readText(row[4]),
            requiredPoints: _readInt(row[5]),
            redeemedAt: _readText(row[6]),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<List<ForumPost>> getUserForumPosts({
    required String userId,
    int limit = 50,
  }) async {
    final safeLimit = limit.clamp(1, 300);
    final result = await _connection.query(
      '''
      SELECT
        p.id,
        COALESCE(p.author_id, '') AS author_id,
        p.author,
        p.title,
        p.content,
        p.tag,
        p.likes,
        (
          SELECT COUNT(*)
          FROM forum_comments c
          WHERE c.post_id = p.id
        ) AS replies,
        p.created_at,
        EXISTS(
          SELECT 1
          FROM forum_post_likes l
          WHERE l.post_id = p.id AND l.user_id = ?
        ) AS liked_by_me
      FROM forum_posts p
      WHERE p.author_id = ?
      ORDER BY p.created_at DESC
      LIMIT ?
      ''',
      [userId, userId, safeLimit],
    );

    return result
        .map(
          (row) => ForumPost(
            id: _readText(row[0]),
            authorId: _readText(row[1]),
            author: _readText(row[2]),
            title: _readText(row[3]),
            content: _readText(row[4]),
            tag: _readText(row[5]),
            likes: _readInt(row[6]),
            replies: _readInt(row[7]),
            createdAt: _readText(row[8]),
            likedByMe: _readBool(row[9]),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<List<EcoActionCatalogItem>> getEcoActionCatalog() async {
    final result = await _connection.query(
      '''
      SELECT id, title, description, unit_label, co2_kg_per_unit, points_per_unit, active
      FROM eco_action_catalog
      WHERE active = 1
      ORDER BY id
      ''',
    );

    return result
        .map(
          (row) => EcoActionCatalogItem(
            id: row[0] as String,
            title: _readText(row[1]),
            description: _readText(row[2]),
            unitLabel: _readText(row[3]),
            co2KgPerUnit: _readDouble(row[4]),
            pointsPerUnit: _readInt(row[5]),
            active: _readBool(row[6]),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<List<EcoActionRecord>> getEcoActionHistory({
    required String userId,
    int limit = 20,
  }) async {
    final safeLimit = limit.clamp(1, 200);
    final result = await _connection.query(
      '''
      SELECT
        r.id,
        r.user_id,
        r.catalog_action_id,
        c.title,
        r.quantity,
        c.unit_label,
        r.co2_reduction_kg,
        r.points_awarded,
        DATE_FORMAT(r.created_at, '%Y-%m-%d %H:%i:%s') AS created_at,
        r.note
      FROM user_eco_action_records r
      INNER JOIN eco_action_catalog c ON c.id = r.catalog_action_id
      WHERE r.user_id = ?
      ORDER BY r.created_at DESC
      LIMIT ?
      ''',
      [userId, safeLimit],
    );

    return result
        .map(
          (row) => EcoActionRecord(
            id: _readInt(row[0]),
            userId: row[1] as String,
            catalogActionId: row[2] as String,
            actionTitle: row[3] as String,
            quantity: _readDouble(row[4]),
            unitLabel: row[5] as String,
            co2ReductionKg: _readDouble(row[6]),
            pointsAwarded: _readInt(row[7]),
            createdAt: row[8] as String,
            note: row[9] as String?,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<EcoActionEvaluationResult> evaluateEcoAction({
    required String userId,
    required String catalogActionId,
    required double quantity,
    String? note,
  }) async {
    if (quantity <= 0) {
      throw StateError('quantity must be greater than 0.');
    }

    final user = await _getUserById(userId);
    if (user == null) {
      throw StateError('User not found: $userId');
    }

    final catalogResult = await _connection.query(
      '''
      SELECT id, title, unit_label, co2_kg_per_unit, points_per_unit, active
      FROM eco_action_catalog
      WHERE id = ?
      LIMIT 1
      ''',
      [catalogActionId],
    );
    if (catalogResult.isEmpty) {
      throw StateError('Eco action type not found: $catalogActionId');
    }
    final catalogRow = catalogResult.first;
    final isActive = _readBool(catalogRow[5]);
    if (!isActive) {
      throw StateError('Eco action type is inactive: $catalogActionId');
    }

    final title = _readText(catalogRow[1]);
    final co2KgPerUnit = _readDouble(catalogRow[3]);
    final pointsPerUnit = _readInt(catalogRow[4]);

    final co2ReductionKg = _round2(quantity * co2KgPerUnit);
    final pointsAwarded = _roundToInt(quantity * pointsPerUnit);

    await _connection.transaction((tx) async {
      await tx.query(
        '''
        INSERT INTO user_eco_action_records (
          user_id, catalog_action_id, quantity, co2_reduction_kg, points_awarded, note
        ) VALUES (?, ?, ?, ?, ?, ?)
        ''',
        [
          userId,
          catalogActionId,
          quantity,
          co2ReductionKg,
          pointsAwarded,
          note?.trim().isEmpty ?? true ? null : note!.trim(),
        ],
      );

      await tx.query(
        '''
        UPDATE app_users
        SET
          green_score = green_score + ?,
          total_co2_reduction_kg = total_co2_reduction_kg + ?
        WHERE id = ?
        ''',
        [pointsAwarded, co2ReductionKg, userId],
      );

      await tx.query(
        '''
        INSERT INTO point_transactions (
          user_id, change_amount, transaction_type, related_id, remark
        ) VALUES (?, ?, 'EVALUATION_REWARD', ?, ?)
        ''',
        [userId, pointsAwarded, catalogActionId, 'Eco action evaluated: $title'],
      );
    });

    final history = await getEcoActionHistory(userId: userId, limit: 1);
    final latestRecord = history.first;
    final dashboard = await getEcoDashboard(userId: userId);
    return EcoActionEvaluationResult(
      record: latestRecord,
      newPointsBalance: dashboard.currentPoints,
      totalCo2ReductionKg: dashboard.totalCo2ReductionKg,
    );
  }

  @override
  Future<List<Badge>> getBadges({required String userId}) async {
    final user = await _getUserById(userId);
    if (user == null) {
      throw StateError('User not found: $userId');
    }

    final result = await _connection.query(
      '''
      SELECT
        b.id,
        b.title,
        b.description,
        b.required_points,
        b.icon,
        ub.redeemed_at
      FROM badges b
      LEFT JOIN user_badges ub
        ON ub.badge_id = b.id
       AND ub.user_id = ?
      WHERE b.active = 1
      ORDER BY b.required_points ASC
      ''',
      [userId],
    );

    return result
        .map((row) {
          final redeemedAt = row[5]?.toString();
          final redeemed = redeemedAt != null && redeemedAt.isNotEmpty;
          return Badge(
            id: row[0] as String,
            title: _readText(row[1]),
            description: _readText(row[2]),
            requiredPoints: _readInt(row[3]),
            icon: _readText(row[4]),
            redeemed: redeemed,
            redeemable: !redeemed && user.greenScore >= _readInt(row[3]),
            redeemedAt: redeemed ? redeemedAt : null,
          );
        })
        .toList(growable: false);
  }

  @override
  Future<BadgeRedeemResult> redeemBadge({
    required String userId,
    required String badgeId,
  }) async {
    final user = await _getUserById(userId);
    if (user == null) {
      throw StateError('User not found: $userId');
    }

    final badgeResult = await _connection.query(
      '''
      SELECT id, title, description, required_points, icon, active
      FROM badges
      WHERE id = ?
      LIMIT 1
      ''',
      [badgeId],
    );
    if (badgeResult.isEmpty) {
      throw StateError('Badge not found: $badgeId');
    }

    final row = badgeResult.first;
    final active = _readBool(row[5]);
    if (!active) {
      throw StateError('Badge is inactive: $badgeId');
    }

    final requiredPoints = _readInt(row[3]);
    if (user.greenScore < requiredPoints) {
      throw StateError(
        'Insufficient points. Required: $requiredPoints, current: ${user.greenScore}.',
      );
    }

    final redeemedCheck = await _connection.query(
      'SELECT COUNT(*) AS count FROM user_badges WHERE user_id = ? AND badge_id = ?',
      [userId, badgeId],
    );
    if (_readInt(redeemedCheck.first.fields['count']) > 0) {
      throw StateError('Badge already redeemed: $badgeId');
    }

    await _connection.transaction((tx) async {
      await tx.query(
        'INSERT INTO user_badges (user_id, badge_id) VALUES (?, ?)',
        [userId, badgeId],
      );

      await tx.query(
        'UPDATE app_users SET green_score = green_score - ? WHERE id = ?',
        [requiredPoints, userId],
      );

      await tx.query(
        '''
        INSERT INTO point_transactions (
          user_id, change_amount, transaction_type, related_id, remark
        ) VALUES (?, ?, 'BADGE_REDEEM', ?, ?)
        ''',
        [userId, -requiredPoints, badgeId, 'Redeemed badge: ${row[1]}'],
      );
    });

    final badges = await getBadges(userId: userId);
    final redeemedBadge = badges.firstWhere((badge) => badge.id == badgeId);
    final dashboard = await getEcoDashboard(userId: userId);

    return BadgeRedeemResult(
      badge: redeemedBadge,
      newPointsBalance: dashboard.currentPoints,
    );
  }

  @override
  Future<EcoDashboard> getEcoDashboard({required String userId}) async {
    final user = await _getUserById(userId);
    if (user == null) {
      throw StateError('User not found: $userId');
    }

    final evalCountResult = await _connection.query(
      'SELECT COUNT(*) AS count FROM user_eco_action_records WHERE user_id = ?',
      [userId],
    );
    final badgeCountResult = await _connection.query(
      'SELECT COUNT(*) AS count FROM user_badges WHERE user_id = ?',
      [userId],
    );

    return EcoDashboard(
      userId: userId,
      currentPoints: user.greenScore,
      totalCo2ReductionKg: user.totalCo2ReductionKg,
      totalEvaluations: _readInt(evalCountResult.first.fields['count']),
      badgesRedeemed: _readInt(badgeCountResult.first.fields['count']),
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
    final ukMapping = _toUkCategory(category.id);
    final identifiedItem = itemName.trim().isEmpty
        ? 'Unknown item'
        : _toEnglishItemName(itemName.trim());

    return ClassificationResult(
      itemName: itemName.trim(),
      category: category,
      confidence: _confidenceFor(normalized),
      suggestions: category.recyclingTips,
      identifiedItem: identifiedItem,
      englandCategoryName: ukMapping.name,
      ukDisposalBin: ukMapping.bin,
      ukDisposalTips: ukMapping.tips,
    );
  }

  @override
  Future<ClassificationResult> classifyImage({
    required List<int> imageBytes,
    required String fileName,
    String? submittedBy,
  }) async {
    final categories = await getCategories();
    final sourceName = fileName.trim().isEmpty ? 'upload.jpg' : fileName.trim();

    final client = _aliyunClient;
    if (client == null) {
      throw StateError(
        'Aliyun image recognition is not configured. '
        'Set ALIYUN_ACCESS_KEY_ID and ALIYUN_ACCESS_KEY_SECRET, then restart backend.',
      );
    }

    final response = await client.classifyRubbishByImageBytes(
      imageBytes: Uint8List.fromList(imageBytes),
      fileName: sourceName,
    );
    final bestElement = _pickBestElement(response);
    final mappedCategory = _mapAliyunCategory(
      aliyunCategory: bestElement.category,
      labels: bestElement.rubbish,
      categories: categories,
    );
    final ukMapping = _toUkCategory(mappedCategory.id);
    final identifiedItem = bestElement.rubbish.isEmpty
        ? sourceName
        : _toEnglishItemName(bestElement.rubbish);

    await _connection.query(
      '''
      INSERT INTO vision_classification_logs (
        submitted_by,
        source_file_name,
        image_url,
        request_id,
        category_label,
        category_score,
        rubbish_label,
        rubbish_score,
        mapped_category_id,
        mapped_category_title,
        raw_response_json
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        submittedBy?.trim().isEmpty ?? true ? null : submittedBy!.trim(),
        sourceName,
        response.imageUrl,
        response.requestId,
        bestElement.category,
        bestElement.categoryScore,
        bestElement.rubbish,
        bestElement.rubbishScore,
        mappedCategory.id,
        mappedCategory.title,
        jsonEncode(response.rawPayload),
      ],
    );

    return ClassificationResult(
      itemName: identifiedItem,
      category: mappedCategory,
      confidence: bestElement.rubbishScore > 0
          ? bestElement.rubbishScore
          : bestElement.categoryScore,
      suggestions: mappedCategory.recyclingTips,
      identifiedItem: identifiedItem,
      englandCategoryName: ukMapping.name,
      ukDisposalBin: ukMapping.bin,
      ukDisposalTips: ukMapping.tips,
    );
  }

  @override
  Future<List<AliyunRubbishResponse>> getRecentVisionLogs({int limit = 20}) async {
    final safeLimit = limit.clamp(1, 200);
    final result = await _connection.query(
      '''
      SELECT request_id, image_url, category_label, category_score, rubbish_label, rubbish_score, raw_response_json
      FROM vision_classification_logs
      ORDER BY created_at DESC
      LIMIT ?
      ''',
      [safeLimit],
    );

    return result.map((row) {
      final payloadText = row[6]?.toString() ?? '{}';
      final payload = jsonDecode(payloadText);
      final safePayload = payload is Map<String, dynamic>
          ? payload
          : <String, dynamic>{};
      return AliyunRubbishResponse(
        requestId: row[0]?.toString() ?? '',
        sensitive: false,
        imageUrl: row[1]?.toString() ?? '',
        elements: [
          AliyunRubbishElement(
            category: row[2]?.toString() ?? '',
            categoryScore: _readDouble(row[3]),
            rubbish: row[4]?.toString() ?? '',
            rubbishScore: _readDouble(row[5]),
          ),
        ],
        rawPayload: safePayload,
      );
    }).toList(growable: false);
  }

  AliyunRubbishElement _pickBestElement(AliyunRubbishResponse response) {
    if (response.elements.isEmpty) {
      throw StateError('Aliyun returned no classification elements.');
    }
    final sorted = response.elements.toList(growable: false)
      ..sort((a, b) => b.rubbishScore.compareTo(a.rubbishScore));
    return sorted.first;
  }

  WasteCategory _mapAliyunCategory({
    required String aliyunCategory,
    required String labels,
    required List<WasteCategory> categories,
  }) {
    final normalizedCategory = aliyunCategory.toLowerCase().trim();
    final normalizedLabels = labels.toLowerCase();

    if (normalizedCategory.contains('harm') ||
        normalizedCategory.contains('hazard') ||
        normalizedCategory.contains('dangerous') ||
        normalizedCategory.contains('有害') ||
        normalizedLabels.contains('battery') ||
        normalizedLabels.contains('paint') ||
        normalizedLabels.contains('medicine') ||
        normalizedLabels.contains('chemical') ||
        normalizedLabels.contains('电池') ||
        normalizedLabels.contains('药')) {
      return _categoryById(categories, 'hazardous');
    }

    if (normalizedCategory.contains('kitchen') ||
        normalizedCategory.contains('food') ||
        normalizedCategory.contains('wet') ||
        normalizedCategory.contains('organic') ||
        normalizedCategory.contains('厨余') ||
        normalizedCategory.contains('湿') ||
        normalizedLabels.contains('banana') ||
        normalizedLabels.contains('vegetable') ||
        normalizedLabels.contains('fruit') ||
        normalizedLabels.contains('food') ||
        normalizedLabels.contains('果') ||
        normalizedLabels.contains('菜')) {
      return _categoryById(categories, 'organic');
    }

    if (normalizedCategory.contains('recycle') ||
        normalizedCategory.contains('recyclable') ||
        normalizedCategory.contains('可回收') ||
        normalizedLabels.contains('bottle') ||
        normalizedLabels.contains('paper') ||
        normalizedLabels.contains('cardboard') ||
        normalizedLabels.contains('can') ||
        normalizedLabels.contains('plastic') ||
        normalizedLabels.contains('glass') ||
        normalizedLabels.contains('纸') ||
        normalizedLabels.contains('塑料') ||
        normalizedLabels.contains('金属') ||
        normalizedLabels.contains('玻璃')) {
      return _categoryById(categories, 'recyclable');
    }

    return _categoryById(categories, 'residual');
  }

  WasteCategory _toWasteCategory(ResultRow row) {
    return WasteCategory(
      id: _readText(row[0]),
      title: _readText(row[1]),
      description: _readText(row[2]),
      binColor: _readText(row[3]),
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

  _UkCategoryMapping _toUkCategory(String categoryId) {
    switch (categoryId) {
      case 'recyclable':
        return const _UkCategoryMapping(
          name: 'Mixed Recyclables',
          bin: 'Household recycling bin',
          tips: [
            'Rinse food residue from bottles, cans, and jars.',
            'Follow your local council list for accepted recyclables.',
          ],
        );
      case 'organic':
        return const _UkCategoryMapping(
          name: 'Food Waste',
          bin: 'Food waste caddy',
          tips: [
            'Place scraps in the food caddy with compostable liner if allowed.',
            'Keep plastics and packaging out of food waste collection.',
          ],
        );
      case 'hazardous':
        return const _UkCategoryMapping(
          name: 'Household Hazardous Waste',
          bin: 'Household Waste Recycling Centre (HWRC)',
          tips: [
            'Do not place hazardous items in normal household bins.',
            'Take batteries, chemicals, and paint to approved collection points.',
          ],
        );
      default:
        return const _UkCategoryMapping(
          name: 'General Waste',
          bin: 'General waste (black/grey bin)',
          tips: [
            'Only dispose non-recyclable items in general waste.',
            'Try to separate recyclable and food waste first.',
          ],
        );
    }
  }

  String _toEnglishItemName(String raw) {
    final text = raw.trim();
    if (text.isEmpty) {
      return 'Unknown item';
    }
    final lower = text.toLowerCase();
    if (lower == '电池' || lower.contains('battery')) {
      return 'Battery';
    }
    if (lower == '塑料瓶' || lower.contains('plastic bottle')) {
      return 'Plastic bottle';
    }
    if (lower == '纸张' || lower == '废纸' || lower.contains('paper')) {
      return 'Paper';
    }
    if (lower == '玻璃瓶' || lower.contains('glass')) {
      return 'Glass bottle';
    }
    if (lower == '易拉罐' || lower.contains('can')) {
      return 'Aluminium can';
    }
    if (lower == '果皮' || lower.contains('fruit peel')) {
      return 'Fruit peel';
    }
    if (lower == '菜叶' || lower.contains('vegetable')) {
      return 'Vegetable scraps';
    }
    if (lower == '药品' || lower.contains('medicine')) {
      return 'Medicine';
    }
    if (lower == '油漆' || lower.contains('paint')) {
      return 'Paint';
    }
    if (lower == '餐巾纸' || lower.contains('tissue')) {
      return 'Used tissue';
    }
    if (RegExp(r'[\u4e00-\u9fff]').hasMatch(text)) {
      return 'Unspecified item';
    }
    return text;
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

  Future<AppUser?> _getUserById(String userId) async {
    final result = await _connection.query(
      '''
      SELECT
        id, name, email, city, level, green_score, total_recycled_kg, avatar_initials, avatar_url, total_co2_reduction_kg
      FROM app_users
      WHERE id = ?
      LIMIT 1
      ''',
      [userId],
    );
    if (result.isEmpty) {
      return null;
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
      avatarUrl: _readNullableText(row[8]),
      totalCo2ReductionKg: _readDouble(row[9]),
    );
  }

  Future<void> _upsertAccount({
    required String userId,
    required String email,
    required String password,
  }) async {
    final safeEmail = email.trim().toLowerCase();
    final exists = await _connection.query(
      'SELECT COUNT(*) AS count FROM user_accounts WHERE user_id = ?',
      [userId],
    );
    if (_readInt(exists.first.fields['count']) > 0) {
      await _connection.query(
        '''
        UPDATE user_accounts
        SET email = ?, password_hash = ?
        WHERE user_id = ?
        ''',
        [safeEmail, _hashPassword(password), userId],
      );
      return;
    }

    await _connection.query(
      '''
      INSERT INTO user_accounts (user_id, email, password_hash, created_at)
      VALUES (?, ?, ?, NOW())
      ''',
      [userId, safeEmail, _hashPassword(password)],
    );
  }

  Future<AuthSession> _createSessionForUser(String userId) async {
    final user = await _getUserById(userId);
    if (user == null) {
      throw StateError('User not found.');
    }
    final token = _generateToken();
    final expiresAt = DateTime.now().add(const Duration(days: 7));
    final expiresAtText = _formatDateTime(expiresAt);

    await _connection.query(
      '''
      INSERT INTO auth_sessions (token, user_id, expires_at, created_at)
      VALUES (?, ?, ?, NOW())
      ''',
      [token, userId, expiresAtText],
    );

    return AuthSession(
      token: token,
      expiresAt: expiresAt.toIso8601String(),
      user: user,
    );
  }

  String _hashPassword(String raw) {
    final bytes = utf8.encode(raw);
    return sha256.convert(bytes).toString();
  }

  bool _verifyPassword(String raw, String hash) {
    return _hashPassword(raw) == hash;
  }

  String _generateToken() {
    final bytes = List<int>.generate(32, (_) => _secureRandom.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  String _newUserId() {
    return 'u${DateTime.now().microsecondsSinceEpoch}';
  }

  String _buildAvatarInitials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) {
      return 'U';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    final first = parts.first.substring(0, 1);
    final last = parts.last.substring(0, 1);
    return '$first$last'.toUpperCase();
  }

  String _formatDateTime(DateTime value) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${value.year}-${two(value.month)}-${two(value.day)} '
        '${two(value.hour)}:${two(value.minute)}:${two(value.second)}';
  }

  Future<ChatMessage> _sendChatMessage({
    required String userId,
    required String conversationId,
    required String messageType,
    required String content,
  }) async {
    final safeContent = content.trim();
    if (safeContent.isEmpty) {
      throw StateError(
        messageType == 'image' ? 'imageUrl is required.' : 'content is required.',
      );
    }
    if (messageType != 'text' && messageType != 'image') {
      throw StateError('Unsupported messageType: $messageType');
    }

    final sender = await _getUserById(userId);
    if (sender == null) {
      throw StateError('User not found: $userId');
    }
    final inConversation = await _connection.query(
      '''
      SELECT COUNT(*) AS count
      FROM chat_conversation_participants
      WHERE conversation_id = ? AND user_id = ?
      ''',
      [conversationId, userId],
    );
    if (_readInt(inConversation.first.fields['count']) == 0) {
      throw StateError('Conversation not found or access denied.');
    }

    int messageId = 0;
    await _connection.transaction((tx) async {
      final insert = await tx.query(
        '''
        INSERT INTO chat_messages (conversation_id, sender_id, message_type, content, created_at)
        VALUES (?, ?, ?, ?, NOW())
        ''',
        [conversationId, userId, messageType, safeContent],
      );
      messageId = _readInt(insert.insertId);

      await tx.query(
        '''
        UPDATE chat_conversations
        SET latest_message_id = ?, updated_at = NOW()
        WHERE id = ?
        ''',
        [messageId, conversationId],
      );

      await tx.query(
        '''
        UPDATE chat_conversation_participants
        SET
          last_read_message_id = ?,
          last_read_at = NOW()
        WHERE conversation_id = ? AND user_id = ?
        ''',
        [messageId, conversationId, userId],
      );
    });

    final result = await _connection.query(
      '''
      SELECT
        m.id,
        m.conversation_id,
        m.sender_id,
        u.name,
        u.avatar_initials,
        m.message_type,
        m.content,
        DATE_FORMAT(m.created_at, '%Y-%m-%d %H:%i:%s') AS created_at
      FROM chat_messages m
      INNER JOIN app_users u ON u.id = m.sender_id
      WHERE m.id = ?
      LIMIT 1
      ''',
      [messageId],
    );

    final row = result.first;
    return ChatMessage(
      id: _readInt(row[0]),
      conversationId: _readText(row[1]),
      senderId: _readText(row[2]),
      senderName: _readText(row[3]).isEmpty ? sender.name : _readText(row[3]),
      senderAvatarInitials: _readText(row[4]).isEmpty
          ? sender.avatarInitials
          : _readText(row[4]),
      messageType: _readText(row[5]),
      content: _readText(row[6]),
      createdAt: _readText(row[7]),
    );
  }

  String _buildDirectConversationId(String userA, String userB) {
    final ids = [userA.trim(), userB.trim()]..sort();
    return 'direct-${ids[0]}-${ids[1]}';
  }

  List<String> _readStringList(Object? value) {
    if (value == null) {
      return const [];
    }
    final text = _readText(value);
    if (text.trim().isEmpty) {
      return const [];
    }
    final decoded = jsonDecode(text);
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

  String _readText(Object? value) {
    if (value == null) {
      return '';
    }
    if (value is String) {
      return value;
    }
    if (value is Blob) {
      return utf8.decode(value.toBytes());
    }
    return value.toString();
  }

  String? _readNullableText(Object? value) {
    if (value == null) {
      return null;
    }
    final text = _readText(value).trim();
    return text.isEmpty ? null : text;
  }

  String _newPostId() {
    return 'p${DateTime.now().microsecondsSinceEpoch}';
  }

  String _newCommentId() {
    return 'c${DateTime.now().microsecondsSinceEpoch}';
  }

  String _nowAsString() {
    final now = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${now.year}-${two(now.month)}-${two(now.day)} ${two(now.hour)}:${two(now.minute)}:${two(now.second)}';
  }

  String _initialsFromName(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) {
      return 'U';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  List<ForumComment> _buildCommentTree(List<ForumComment> flat) {
    final byParent = <String, List<ForumComment>>{};
    final roots = <ForumComment>[];

    for (final item in flat) {
      final parentId = item.parentCommentId;
      if (parentId == null) {
        roots.add(item);
      } else {
        byParent.putIfAbsent(parentId, () => []).add(item);
      }
    }

    ForumComment attach(ForumComment node) {
      final children = (byParent[node.id] ?? const <ForumComment>[])
          .map(attach)
          .toList(growable: false);
      return ForumComment(
        id: node.id,
        postId: node.postId,
        parentCommentId: node.parentCommentId,
        authorId: node.authorId,
        author: node.author,
        content: node.content,
        likes: node.likes,
        createdAt: node.createdAt,
        likedByMe: node.likedByMe,
        replies: children,
      );
    }

    return roots.map(attach).toList(growable: false);
  }

  int _roundToInt(double value) {
    return value.round();
  }

  double _round2(double value) {
    return double.parse(value.toStringAsFixed(2));
  }

  @override
  Future<void> close() async {
    _aliyunClient?.close();
    await _connection.close();
  }
}

class _SeedChatMessage {
  const _SeedChatMessage({
    required this.senderId,
    required this.messageType,
    required this.content,
    required this.createdAt,
  });

  final String senderId;
  final String messageType;
  final String content;
  final String createdAt;
}

class _UkCategoryMapping {
  const _UkCategoryMapping({
    required this.name,
    required this.bin,
    required this.tips,
  });

  final String name;
  final String bin;
  final List<String> tips;
}
