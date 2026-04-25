// ------------------------------------------------------------------------------------------------
// EcoSort AI Flutter App — Mock / Demo Data
// ------------------------------------------------------------------------------------------------
//
// [MockData] provides static canned data for development, prototyping, and
// UI testing. All feature pages use this data directly as a fallback when the
// backend is not running or when [AppConfig.useMockFallback] is enabled.
//
// This file mirrors the seed data in the backend [WasteDataService.seeded]
// factory so that the frontend can render complete screens without any network
// dependency.
// ------------------------------------------------------------------------------------------------

import '../models/app_user.dart';
import '../models/eco_action.dart';
import '../models/forum_post.dart';
import '../models/message_thread.dart';
import '../models/reward.dart';
import '../models/waste_category.dart';

/// Central repository of static demo data for the EcoSort AI frontend.
class MockData {
  MockData._(); // Prevent instantiation — all members are static.

  // ----------------------------------------------------------------------------------------------
  // Waste categories
  // ----------------------------------------------------------------------------------------------

  /// The four standard waste-sorting categories (Blue / Green / Red / Gray).
  static const categories = <WasteCategory>[
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
      description: 'Food scraps and biodegradable materials for composting.',
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

  // ----------------------------------------------------------------------------------------------
  // Sample classification result
  // ----------------------------------------------------------------------------------------------

  /// A hard-coded demo classification result used as the default display.
  static const demoClassification = ClassificationResult(
    itemName: 'Plastic bottle',
    category: categories[0], // Recyclable
    confidence: 0.94,
    suggestions: [
      'Remove the cap and rinse before recycling.',
      'Crush to save space in the blue bin.',
    ],
  );

  // ----------------------------------------------------------------------------------------------
  // Eco actions
  // ----------------------------------------------------------------------------------------------

  /// Sample eco-friendly actions the user has completed or can join.
  static const ecoActions = <EcoAction>[
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

  // ----------------------------------------------------------------------------------------------
  // Rewards
  // ----------------------------------------------------------------------------------------------

  /// Items available in the reward store.
  static const rewards = <Reward>[
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

  // ----------------------------------------------------------------------------------------------
  // Forum posts
  // ----------------------------------------------------------------------------------------------

  /// Sample community forum discussions.
  static const forumPosts = <ForumPost>[
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
      content: 'The new collection box is now beside the library service desk.',
      tag: 'Campus News',
      likes: 58,
      replies: 6,
      createdAt: '2 days ago',
    ),
  ];

  // ----------------------------------------------------------------------------------------------
  // Messages
  // ----------------------------------------------------------------------------------------------

  /// Sample in-app message conversations.
  static const messages = <MessageThread>[
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

  // ----------------------------------------------------------------------------------------------
  // User profile
  // ----------------------------------------------------------------------------------------------

  /// The demo user profile displayed throughout the app.
  static const user = AppUser(
    id: 'u1',
    name: 'Alex Green',
    email: 'alex.green@example.com',
    city: 'Shanghai',
    level: 'Eco Pioneer',
    greenScore: 836,
    totalRecycledKg: 48.5,
    avatarInitials: 'AG',
  );
}
