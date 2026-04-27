import '../models/app_models.dart';

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

  Future<bool> pingDatabase();

  /// Classifies [itemName] into one of the available waste categories.
  Future<ClassificationResult> classify(String itemName);

  /// Releases held resources (like DB connections).
  Future<void> close();
}
