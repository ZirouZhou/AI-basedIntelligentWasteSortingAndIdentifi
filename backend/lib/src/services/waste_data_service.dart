// ------------------------------------------------------------------------------------------------
// EcoSort AI Backend — Waste Data Service
// ------------------------------------------------------------------------------------------------
//
// [WasteDataService] is the single source of truth for all demo / canned data
// returned by the EcoSort REST API. It holds the four waste categories, eco
// actions, rewards, forum posts, messages, and a sample user profile. It also
// implements a lightweight keyword-based classifier that predicts which waste
// bin an item belongs to.
//
// In a production system this class would be backed by a database and a real
// ML model, but for the current prototype it returns hard-coded seed data.
// ------------------------------------------------------------------------------------------------

import '../models/app_models.dart';

/// Provides all application data and classification logic.
///
/// Create an instance with [WasteDataService.seeded] to obtain a service
/// pre-populated with realistic demo data.
class WasteDataService {
  const WasteDataService({
    required this.categories,
    required this.ecoActions,
    required this.rewards,
    required this.forumPosts,
    required this.messages,
    required this.profile,
  });

  /// The four standard waste-sorting categories.
  final List<WasteCategory> categories;

  /// Eco-friendly actions the user can take to earn green points.
  final List<EcoAction> ecoActions;

  /// Rewards available for point redemption.
  final List<Reward> rewards;

  /// Posts in the community discussion forum.
  final List<ForumPost> forumPosts;

  /// The user's in-app message threads.
  final List<MessageThread> messages;

  /// The currently signed-in user's profile.
  final AppUser profile;

  // ------------------------------------------------------------------------------------------------
  // Factory: seeded demo data
  // ------------------------------------------------------------------------------------------------

  /// Creates a [WasteDataService] populated with hard-coded demo data.
  ///
  /// This factory is the primary way to obtain a service instance during
  /// development and prototyping.
  factory WasteDataService.seeded() {
    // --------------------------------------------------------------------------------------------
    // Waste categories
    // --------------------------------------------------------------------------------------------
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

    return WasteDataService(
      categories: categories,
      // ------------------------------------------------------------------------------------------
      // Eco actions
      // ------------------------------------------------------------------------------------------
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
      // ------------------------------------------------------------------------------------------
      // Rewards
      // ------------------------------------------------------------------------------------------
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
      // ------------------------------------------------------------------------------------------
      // Forum posts
      // ------------------------------------------------------------------------------------------
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
      // ------------------------------------------------------------------------------------------
      // Messages
      // ------------------------------------------------------------------------------------------
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
      // ------------------------------------------------------------------------------------------
      // User profile
      // ------------------------------------------------------------------------------------------
      profile: const AppUser(
        id: 'u1',
        name: 'Alex Green',
        email: 'alex.green@example.com',
        city: 'Shanghai',
        level: 'Eco Pioneer',
        greenScore: 836,
        totalRecycledKg: 48.5,
        avatarInitials: 'AG',
      ),
    );
  }

  // ------------------------------------------------------------------------------------------------
  // Classification
  // ------------------------------------------------------------------------------------------------

  /// Classifies [itemName] into one of the four waste categories.
  ///
  /// The algorithm normalises the input to lower-case, then uses a simple
  /// keyword-matching strategy to determine the most likely category. Items
  /// that do not match any specific keyword default to "Recyclable".
  ClassificationResult classify(String itemName) {
    final normalized = itemName.toLowerCase();
    final category = _matchCategory(normalized);

    return ClassificationResult(
      itemName: itemName.trim(),
      category: category,
      confidence: _confidenceFor(normalized),
      suggestions: category.recyclingTips,
    );
  }

  /// Selects the best-matching [WasteCategory] by scanning [normalized] text
  /// for known keywords in priority order.
  WasteCategory _matchCategory(String normalized) {
    // Hazardous keywords take highest priority because misclassification is
    // the most dangerous.
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
    // Default fallback: most consumer packaging is recyclable.
    return categories.firstWhere((item) => item.id == 'recyclable');
  }

  /// Returns `true` when [text] contains any of the given [keywords].
  bool _containsAny(String text, List<String> keywords) {
    return keywords.any(text.contains);
  }

  /// Returns a confidence score (0.0 – 1.0) based on how well the input
  /// matches known item names.
  ///
  /// * Very short inputs (< 3 characters) get a low confidence (0.62).
  /// * Inputs matching a highly recognisable keyword (bottle, battery, etc.)
  ///   receive a high confidence (0.94).
  /// * Everything else gets a medium confidence (0.82).
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
}
