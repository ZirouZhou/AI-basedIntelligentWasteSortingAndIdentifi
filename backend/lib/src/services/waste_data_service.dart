import '../models/app_models.dart';
import '../models/vision_models.dart';

/// Defines the data operations required by the API routes.
///
/// Implementations may use MySQL, mock data, or another persistence mechanism.
abstract class WasteDataService {
  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
  });

  Future<AuthSession> login({
    required String email,
    required String password,
  });

  Future<AppUser> requireUserByToken(String token);

  Future<List<WasteCategory>> getCategories();

  Future<List<EcoAction>> getEcoActions();

  Future<List<Reward>> getRewards();

  Future<List<ForumPost>> getForumPosts();

  Future<ForumPost> createForumPost({
    required String authorId,
    required String title,
    required String content,
    required String tag,
  });

  Future<ForumPost> toggleForumPostLike({
    required String postId,
    required String userId,
  });

  Future<List<ForumComment>> getForumComments({
    required String postId,
    String? userId,
  });

  Future<ForumComment> createForumComment({
    required String postId,
    required String authorId,
    required String content,
    String? parentCommentId,
  });

  Future<ForumComment> toggleForumCommentLike({
    required String commentId,
    required String userId,
  });

  Future<List<MessageThread>> getMessages();

  Future<List<ChatConversationSummary>> getChatConversations({
    required String userId,
  });

  Future<String> getOrCreateDirectConversation({
    required String userId,
    required String peerUserId,
  });

  Future<List<ChatMessage>> getChatMessages({
    required String userId,
    required String conversationId,
    int? afterMessageId,
    int limit = 50,
  });

  Future<ChatMessage> sendChatTextMessage({
    required String userId,
    required String conversationId,
    required String content,
  });

  Future<ChatMessage> sendChatImageMessage({
    required String userId,
    required String conversationId,
    required String imageUrl,
  });

  Future<void> markConversationRead({
    required String userId,
    required String conversationId,
  });

  Future<AppUser> getProfile({required String userId});

  Future<AppUser> updateProfile({
    required String userId,
    required String name,
    required String email,
    required String city,
  });

  Future<void> updateAvatar({
    required String userId,
    required String avatarUrl,
  });

  Future<void> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  });

  Future<List<UserRecognitionRecord>> getRecognitionHistory({
    required String userId,
    int limit = 50,
  });

  Future<List<UserPointHistoryRecord>> getPointHistory({
    required String userId,
    int limit = 50,
  });

  Future<List<UserBadgeHistoryRecord>> getBadgeHistory({
    required String userId,
    int limit = 50,
  });

  Future<List<ForumPost>> getUserForumPosts({
    required String userId,
    int limit = 50,
  });

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
