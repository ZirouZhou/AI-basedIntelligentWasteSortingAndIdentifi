import '../models/app_models.dart';
import '../models/vision_models.dart';

/// Defines the data operations required by the API routes.
///
/// Implementations may use MySQL, mock data, or another persistence mechanism.
abstract class WasteDataService {
  Future<List<WasteCategory>> getCategories();

  Future<List<EcoAction>> getEcoActions();

  Future<List<Reward>> getRewards();

  Future<List<ForumPost>> getForumPosts();

  Future<List<MessageThread>> getMessages();

  Future<AppUser> getProfile();

  Future<List<EcoActionCatalogItem>> getEcoActionCatalog();

  Future<List<EcoActionRecord>> getEcoActionHistory({
    required String userId,
    int limit = 20,
  });

  Future<EcoActionEvaluationResult> evaluateEcoAction({
    required String userId,
    required String catalogActionId,
    required double quantity,
    String? note,
  });

  Future<List<Badge>> getBadges({required String userId});

  Future<BadgeRedeemResult> redeemBadge({
    required String userId,
    required String badgeId,
  });

  Future<EcoDashboard> getEcoDashboard({required String userId});

  Future<bool> pingDatabase();

  /// Classifies [itemName] into one of the available waste categories.
  Future<ClassificationResult> classify(String itemName);

  /// Classifies waste from image bytes using a remote AI service.
  ///
  /// Implementations should persist recognition logs for auditing.
  Future<ClassificationResult> classifyImage({
    required List<int> imageBytes,
    required String fileName,
    String? submittedBy,
  });

  /// Returns the latest raw image-recognition logs for diagnostics/admin.
  Future<List<AliyunRubbishResponse>> getRecentVisionLogs({int limit = 20});

  /// Releases held resources (like DB connections).
  Future<void> close();
}
