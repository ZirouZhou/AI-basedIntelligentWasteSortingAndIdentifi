import '../models/app_models.dart';
import '../models/vision_models.dart';
import 'waste_data_service.dart';

/// In-memory implementation of [WasteDataService].
///
/// Useful for tests and local mocking. Production startup now uses MySQL via
/// [MySqlWasteDataService].
class InMemoryWasteDataService implements WasteDataService {
  const InMemoryWasteDataService({
    required this.categories,
    required this.ecoActions,
    required this.rewards,
    required this.forumPosts,
    required this.messages,
    required this.profile,
  });

  final List<WasteCategory> categories;
  final List<EcoAction> ecoActions;
  final List<Reward> rewards;
  final List<ForumPost> forumPosts;
  final List<MessageThread> messages;
  final AppUser profile;
  static final Map<String, AppUser> _usersByToken = <String, AppUser>{};

  factory InMemoryWasteDataService.seeded() {
    const categories = [
      WasteCategory(
        id: 'recyclable',
        title: 'Recyclable Waste',
        description:
            'Clean paper, plastic, glass, and metal that can be reused.',
        binColor: 'Blue',
        examples: [
          'Plastic bottles',
          'Cardboard',
          'Glass jars',
          'Aluminum cans',
        ],
        recyclingTips: [
          'Rinse containers before disposal.',
          'Flatten cardboard to save space.',
        ],
      ),
      WasteCategory(
        id: 'organic',
        title: 'Organic Waste',
        description:
            'Food scraps and biodegradable materials for composting.',
        binColor: 'Green',
        examples: [
          'Fruit peels',
          'Vegetable scraps',
          'Tea leaves',
          'Eggshells',
        ],
        recyclingTips: [
          'Drain extra liquid before disposal.',
          'Keep plastic bags out of organic bins.',
        ],
      ),
      WasteCategory(
        id: 'hazardous',
        title: 'Hazardous Waste',
        description:
            'Items that require special handling to protect people and nature.',
        binColor: 'Red',
        examples: [
          'Batteries',
          'Paint',
          'Medicine',
          'Pesticide bottles',
        ],
        recyclingTips: [
          'Never mix hazardous waste with household waste.',
          'Use official collection points.',
        ],
      ),
      WasteCategory(
        id: 'residual',
        title: 'Residual Waste',
        description:
            'Non-recyclable daily waste after sorting useful materials.',
        binColor: 'Gray',
        examples: [
          'Used tissues',
          'Ceramics',
          'Dust',
          'Contaminated packaging',
        ],
        recyclingTips: [
          'Reduce usage when possible.',
          'Separate recyclables before final disposal.',
        ],
      ),
    ];

    return InMemoryWasteDataService(
      categories: categories,
      ecoActions: const [
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
      ],
      rewards: const [
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
          description:
              'Use points for sustainable products at partner stores.',
          requiredPoints: 260,
          redeemed: false,
        ),
      ],
      forumPosts: const [
        ForumPost(
          id: 'p1',
          author: 'Mia Chen',
          title: 'How do you sort takeaway boxes?',
          content:
              'I rinse clean paper boxes, but oily ones still confuse me.',
          tag: 'Sorting Tips',
          likes: 42,
          replies: 12,
          createdAt: 'Today',
        ),
        ForumPost(
          id: 'p2',
          author: 'Leo Wang',
          title: 'Weekend river cleanup team',
          content:
              'We are forming a small group near the east gate this Saturday.',
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
      ],
      messages: const [
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
      ],
      profile: const AppUser(
        id: 'u1',
        name: 'Alex Green',
        email: 'alex.green@example.com',
        city: 'Shanghai',
        level: 'Eco Pioneer',
        greenScore: 836,
        totalRecycledKg: 48.5,
        avatarInitials: 'AG',
        totalCo2ReductionKg: 12.4,
      ),
    );
  }

  static const _catalog = <EcoActionCatalogItem>[
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
  ];

  static const _badges = <Badge>[
    Badge(
      id: 'bronze_guardian',
      title: 'Bronze Carbon Guardian',
      description: 'Awarded to users reaching 100 points.',
      requiredPoints: 100,
      icon: '🥉',
      redeemed: false,
      redeemable: true,
    ),
    Badge(
      id: 'silver_guardian',
      title: 'Silver Carbon Guardian',
      description: 'Awarded to users reaching 250 points.',
      requiredPoints: 250,
      icon: '🥈',
      redeemed: false,
      redeemable: true,
    ),
  ];

  static final _memoryMessages = <ChatMessage>[
    ChatMessage(
      id: 1,
      conversationId: 'chat-u1-u2',
      senderId: 'u2',
      senderName: 'Mia Chen',
      senderAvatarInitials: 'MC',
      messageType: 'text',
      content: 'Hi! Do you know where to dispose oily takeaway boxes?',
      createdAt: '2026-04-27 10:12:00',
    ),
    ChatMessage(
      id: 2,
      conversationId: 'chat-u1-u2',
      senderId: 'u1',
      senderName: 'Alex Green',
      senderAvatarInitials: 'AG',
      messageType: 'text',
      content: 'Usually residual waste. If clean, paper recycle bin.',
      createdAt: '2026-04-27 10:13:40',
    ),
    ChatMessage(
      id: 3,
      conversationId: 'chat-u1-u3',
      senderId: 'u3',
      senderName: 'Leo Wang',
      senderAvatarInitials: 'LW',
      messageType: 'image',
      content:
          'https://images.unsplash.com/photo-1605600659873-d808a13e4f2a?w=1200',
      createdAt: '2026-04-27 09:05:00',
    ),
  ];

  @override
  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final user = AppUser(
      id: 'u_mem_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      email: email.trim().toLowerCase(),
      city: 'Shanghai',
      level: 'Eco Beginner',
      greenScore: 0,
      totalRecycledKg: 0,
      avatarInitials: 'NB',
      totalCo2ReductionKg: 0,
    );
    final token = 'mem-token-${DateTime.now().millisecondsSinceEpoch}';
    _usersByToken[token] = user;
    return AuthSession(
      token: token,
      expiresAt: DateTime.now()
          .add(const Duration(days: 7))
          .toIso8601String(),
      user: user,
    );
  }

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final token = 'mem-token-${DateTime.now().millisecondsSinceEpoch}';
    _usersByToken[token] = profile;
    return AuthSession(
      token: token,
      expiresAt: DateTime.now()
          .add(const Duration(days: 7))
          .toIso8601String(),
      user: profile,
    );
  }

  @override
  Future<AppUser> requireUserByToken(String token) async {
    final user = _usersByToken[token.trim()];
    if (user == null) {
      throw StateError('Unauthorized. Please login again.');
    }
    return user;
  }

  @override
  Future<List<WasteCategory>> getCategories() async => categories;

  @override
  Future<List<EcoAction>> getEcoActions() async => ecoActions;

  @override
  Future<List<Reward>> getRewards() async => rewards;

  @override
  Future<List<ForumPost>> getForumPosts() async => forumPosts;

  @override
  Future<ForumPost> createForumPost({
    required String authorId,
    required String title,
    required String content,
    required String tag,
  }) async {
    final author = profile.name;
    return ForumPost(
      id: 'mem-${DateTime.now().millisecondsSinceEpoch}',
      authorId: authorId,
      author: author,
      title: title.trim(),
      content: content.trim(),
      tag: tag.trim().isEmpty ? 'General' : tag.trim(),
      likes: 0,
      replies: 0,
      createdAt: DateTime.now().toIso8601String(),
      likedByMe: false,
    );
  }

  @override
  Future<ForumPost> toggleForumPostLike({
    required String postId,
    required String userId,
  }) async {
    final post = forumPosts.firstWhere((item) => item.id == postId);
    return ForumPost(
      id: post.id,
      authorId: post.authorId,
      author: post.author,
      title: post.title,
      content: post.content,
      tag: post.tag,
      likes: post.likes + 1,
      replies: post.replies,
      createdAt: post.createdAt,
      likedByMe: true,
    );
  }

  @override
  Future<List<ForumComment>> getForumComments({
    required String postId,
    String? userId,
  }) async {
    return const [];
  }

  @override
  Future<ForumComment> createForumComment({
    required String postId,
    required String authorId,
    required String content,
    String? parentCommentId,
  }) async {
    return ForumComment(
      id: 'mem-c-${DateTime.now().millisecondsSinceEpoch}',
      postId: postId,
      parentCommentId: parentCommentId,
      authorId: authorId,
      author: profile.name,
      content: content.trim(),
      likes: 0,
      createdAt: DateTime.now().toIso8601String(),
      likedByMe: false,
    );
  }

  @override
  Future<ForumComment> toggleForumCommentLike({
    required String commentId,
    required String userId,
  }) async {
    return ForumComment(
      id: commentId,
      postId: 'unknown',
      parentCommentId: null,
      authorId: userId,
      author: profile.name,
      content: '',
      likes: 1,
      createdAt: DateTime.now().toIso8601String(),
      likedByMe: true,
    );
  }

  @override
  Future<List<MessageThread>> getMessages() async => messages;

  @override
  Future<List<ChatConversationSummary>> getChatConversations({
    required String userId,
  }) async {
    final all = <ChatConversationSummary>[
      const ChatConversationSummary(
        id: 'chat-u1-u2',
        peerUserId: 'u2',
        peerName: 'Mia Chen',
        peerAvatarInitials: 'MC',
        preview: 'Usually residual waste. If clean, paper recycle bin.',
        updatedAt: '2026-04-27 10:13:40',
        unreadCount: 0,
        latestMessageType: 'text',
      ),
      const ChatConversationSummary(
        id: 'chat-u1-u3',
        peerUserId: 'u3',
        peerName: 'Leo Wang',
        peerAvatarInitials: 'LW',
        preview: '[Image]',
        updatedAt: '2026-04-27 09:05:00',
        unreadCount: 1,
        latestMessageType: 'image',
      ),
      const ChatConversationSummary(
        id: 'chat-u1-u4',
        peerUserId: 'u4',
        peerName: 'Ava Smith',
        peerAvatarInitials: 'AS',
        preview: 'Battery collection point has moved near the library.',
        updatedAt: '2026-04-26 20:01:12',
        unreadCount: 2,
        latestMessageType: 'text',
      ),
    ];
    return all.where((_) => userId == 'u1').toList(growable: false);
  }

  @override
  Future<String> getOrCreateDirectConversation({
    required String userId,
    required String peerUserId,
  }) async {
    final ids = [userId, peerUserId]..sort();
    return 'chat-${ids[0]}-${ids[1]}';
  }

  @override
  Future<List<ChatMessage>> getChatMessages({
    required String userId,
    required String conversationId,
    int? afterMessageId,
    int limit = 50,
  }) async {
    final safeLimit = limit.clamp(1, 200);
    final filtered = _memoryMessages
        .where((item) => item.conversationId == conversationId)
        .where((item) => afterMessageId == null || item.id > afterMessageId)
        .take(safeLimit)
        .toList(growable: false);
    return filtered;
  }

  @override
  Future<ChatMessage> sendChatTextMessage({
    required String userId,
    required String conversationId,
    required String content,
  }) async {
    final text = content.trim();
    if (text.isEmpty) {
      throw StateError('content is required.');
    }
    final now = DateTime.now();
    final id = (_memoryMessages.isEmpty ? 0 : _memoryMessages.last.id) + 1;
    final message = ChatMessage(
      id: id,
      conversationId: conversationId,
      senderId: userId,
      senderName: userId == profile.id ? profile.name : userId,
      senderAvatarInitials: userId == profile.id ? profile.avatarInitials : 'U',
      messageType: 'text',
      content: text,
      createdAt: now.toIso8601String(),
    );
    _memoryMessages.add(message);
    return message;
  }

  @override
  Future<ChatMessage> sendChatImageMessage({
    required String userId,
    required String conversationId,
    required String imageUrl,
  }) async {
    final url = imageUrl.trim();
    if (url.isEmpty) {
      throw StateError('imageUrl is required.');
    }
    final id = (_memoryMessages.isEmpty ? 0 : _memoryMessages.last.id) + 1;
    final message = ChatMessage(
      id: id,
      conversationId: conversationId,
      senderId: userId,
      senderName: userId == profile.id ? profile.name : userId,
      senderAvatarInitials: userId == profile.id ? profile.avatarInitials : 'U',
      messageType: 'image',
      content: url,
      createdAt: DateTime.now().toIso8601String(),
    );
    _memoryMessages.add(message);
    return message;
  }

  @override
  Future<void> markConversationRead({
    required String userId,
    required String conversationId,
  }) async {}

  @override
  Future<AppUser> getProfile({required String userId}) async => profile;

  @override
  Future<AppUser> updateProfile({
    required String userId,
    required String name,
    required String email,
    required String city,
  }) async {
    return AppUser(
      id: profile.id,
      name: name.trim(),
      email: email.trim(),
      city: city.trim(),
      level: profile.level,
      greenScore: profile.greenScore,
      totalRecycledKg: profile.totalRecycledKg,
      avatarInitials: _initialsFromName(name),
      avatarUrl: profile.avatarUrl,
      totalCo2ReductionKg: profile.totalCo2ReductionKg,
    );
  }

  @override
  Future<void> updateAvatar({
    required String userId,
    required String avatarUrl,
  }) async {}

  @override
  Future<void> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) async {}

  @override
  Future<List<UserRecognitionRecord>> getRecognitionHistory({
    required String userId,
    int limit = 50,
  }) async {
    return const [
      UserRecognitionRecord(
        id: 1,
        fileName: 'battery.jpg',
        imageUrl: 'https://example.com/vision/battery.jpg',
        categoryLabel: 'Hazardous Waste',
        rubbishLabel: 'Battery',
        confidence: 0.96,
        createdAt: '2026-04-27 10:10:00',
      ),
      UserRecognitionRecord(
        id: 2,
        fileName: 'bottle.jpg',
        imageUrl: 'https://example.com/vision/bottle.jpg',
        categoryLabel: 'Recyclable Waste',
        rubbishLabel: 'Plastic Bottle',
        confidence: 0.94,
        createdAt: '2026-04-27 09:30:00',
      ),
    ].take(limit).toList(growable: false);
  }

  @override
  Future<List<UserPointHistoryRecord>> getPointHistory({
    required String userId,
    int limit = 50,
  }) async {
    return const [
      UserPointHistoryRecord(
        id: 1,
        userId: 'u1',
        changeAmount: 18,
        transactionType: 'EVALUATION_REWARD',
        relatedId: 'reuse_bag',
        remark: 'Eco action evaluated: Use Reusable Shopping Bag',
        createdAt: '2026-04-27 10:00:00',
      ),
      UserPointHistoryRecord(
        id: 2,
        userId: 'u1',
        changeAmount: -100,
        transactionType: 'BADGE_REDEEM',
        relatedId: 'bronze_guardian',
        remark: 'Redeemed badge: Bronze Carbon Guardian',
        createdAt: '2026-04-26 15:10:00',
      ),
    ].take(limit).toList(growable: false);
  }

  @override
  Future<List<UserBadgeHistoryRecord>> getBadgeHistory({
    required String userId,
    int limit = 50,
  }) async {
    return const [
      UserBadgeHistoryRecord(
        id: 1,
        userId: 'u1',
        badgeId: 'bronze_guardian',
        badgeTitle: 'Bronze Carbon Guardian',
        badgeIcon: '🥎',
        requiredPoints: 100,
        redeemedAt: '2026-04-26 15:10:00',
      ),
    ].take(limit).toList(growable: false);
  }

  @override
  Future<List<ForumPost>> getUserForumPosts({
    required String userId,
    int limit = 50,
  }) async {
    return forumPosts
        .where((item) => item.authorId == userId || item.author == profile.name)
        .take(limit)
        .toList(growable: false);
  }

  @override
  Future<List<EcoActionCatalogItem>> getEcoActionCatalog() async => _catalog;

  @override
  Future<List<EcoActionRecord>> getEcoActionHistory({
    required String userId,
    int limit = 20,
  }) async {
    final records = <EcoActionRecord>[
      const EcoActionRecord(
        id: 1,
        userId: 'u1',
        catalogActionId: 'reuse_bag',
        actionTitle: 'Use Reusable Shopping Bag',
        quantity: 5,
        unitLabel: 'times',
        co2ReductionKg: 0.3,
        pointsAwarded: 15,
        createdAt: '2026-04-27 10:00:00',
        note: 'Weekly grocery',
      ),
      const EcoActionRecord(
        id: 2,
        userId: 'u1',
        catalogActionId: 'bus_commute',
        actionTitle: 'Take Bus Instead of Car',
        quantity: 8,
        unitLabel: 'km',
        co2ReductionKg: 1.12,
        pointsAwarded: 16,
        createdAt: '2026-04-27 08:30:00',
      ),
    ];

    return records.take(limit).toList(growable: false);
  }

  @override
  Future<EcoActionEvaluationResult> evaluateEcoAction({
    required String userId,
    required String catalogActionId,
    required double quantity,
    String? note,
  }) async {
    final catalog = _catalog.firstWhere((item) => item.id == catalogActionId);
    final co2 = double.parse((catalog.co2KgPerUnit * quantity).toStringAsFixed(2));
    final points = (catalog.pointsPerUnit * quantity).round();
    const newBalance = 900;
    return EcoActionEvaluationResult(
      record: EcoActionRecord(
        id: 999,
        userId: userId,
        catalogActionId: catalog.id,
        actionTitle: catalog.title,
        quantity: quantity,
        unitLabel: catalog.unitLabel,
        co2ReductionKg: co2,
        pointsAwarded: points,
        createdAt: '2026-04-27 12:00:00',
        note: note,
      ),
      newPointsBalance: newBalance,
      totalCo2ReductionKg: profile.totalCo2ReductionKg + co2,
    );
  }

  @override
  Future<List<Badge>> getBadges({required String userId}) async => _badges;

  @override
  Future<BadgeRedeemResult> redeemBadge({
    required String userId,
    required String badgeId,
  }) async {
    final badge = _badges.firstWhere((item) => item.id == badgeId);
    return BadgeRedeemResult(badge: badge, newPointsBalance: 700);
  }

  @override
  Future<EcoDashboard> getEcoDashboard({required String userId}) async {
    return EcoDashboard(
      userId: userId,
      currentPoints: profile.greenScore,
      totalCo2ReductionKg: profile.totalCo2ReductionKg,
      totalEvaluations: 2,
      badgesRedeemed: 1,
    );
  }

  @override
  Future<bool> pingDatabase() async => true;

  @override
  Future<ClassificationResult> classify(String itemName) async {
    final normalized = itemName.toLowerCase();
    final category = _matchCategory(normalized);
    final uk = _toUkCategory(category.id);
    final safeName = itemName.trim().isEmpty ? 'Unknown item' : _toEnglishItemName(itemName.trim());

    return ClassificationResult(
      itemName: itemName.trim(),
      category: category,
      confidence: _confidenceFor(normalized),
      suggestions: category.recyclingTips,
      identifiedItem: safeName,
      englandCategoryName: uk.name,
      ukDisposalBin: uk.bin,
      ukDisposalTips: uk.tips,
    );
  }

  @override
  Future<ClassificationResult> classifyImage({
    required List<int> imageBytes,
    required String fileName,
    String? submittedBy,
  }) async {
    // Local fallback path for tests/dev when cloud AI is unavailable.
    return classify(fileName.replaceAll(RegExp(r'\.[^.]+$'), ''));
  }

  @override
  Future<List<AliyunRubbishResponse>> getRecentVisionLogs({int limit = 20}) async {
    return const [];
  }

  WasteCategory _matchCategory(String normalized) {
    if (_containsAny(normalized, [
      'battery',
      'medicine',
      'paint',
      'pesticide',
    ])) {
      return categories.firstWhere((item) => item.id == 'hazardous');
    }
    if (_containsAny(normalized, [
      'food',
      'banana',
      'apple',
      'leaf',
      'peel',
    ])) {
      return categories.firstWhere((item) => item.id == 'organic');
    }
    if (_containsAny(normalized, [
      'tissue',
      'ceramic',
      'dust',
      'dirty',
    ])) {
      return categories.firstWhere((item) => item.id == 'residual');
    }
    return categories.firstWhere((item) => item.id == 'recyclable');
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

  @override
  Future<void> close() async {}

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
