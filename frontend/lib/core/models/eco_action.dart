// ------------------------------------------------------------------------------------------------
// EcoSort AI Flutter App — EcoAction Model
// ------------------------------------------------------------------------------------------------
//
// [EcoAction] represents a sustainability task or event that a user can
// complete to earn green points. Displayed on the Rewards page under
// "Recent Eco Actions".
// ------------------------------------------------------------------------------------------------

/// A sustainability task or volunteering event.
///
/// * [id]        – unique identifier
/// * [title]     – short action description
/// * [impact]    – environmental benefit summary
/// * [points]    – green points awarded on completion
/// * [completed] – whether the user has finished this action
class EcoAction {
  const EcoAction({
    required this.id,
    required this.title,
    required this.impact,
    required this.points,
    required this.completed,
  });

  final String id;
  final String title;
  final String impact;
  final int points;
  final bool completed;

  /// Constructs an [EcoAction] from a JSON map received from the backend.
  factory EcoAction.fromJson(Map<String, dynamic> json) {
    return EcoAction(
      id: json['id'] as String,
      title: json['title'] as String,
      impact: json['impact'] as String,
      points: json['points'] as int,
      completed: json['completed'] as bool,
    );
  }
}
