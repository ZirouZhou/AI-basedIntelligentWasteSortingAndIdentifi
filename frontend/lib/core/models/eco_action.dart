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
