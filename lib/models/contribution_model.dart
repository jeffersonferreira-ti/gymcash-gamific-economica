// lib/models/contribution_model.dart
class ContributionModel {
  final String id;
  final String userId;
  final String groupId;
  final double amount;
  final double goal;
  final String month; // formato: "YYYY-MM"
  final bool isGoalNotified; // Indica se o usuário já viu o parabéns da meta

  ContributionModel({
    required this.id,
    required this.userId,
    required this.groupId,
    required this.amount,
    required this.goal,
    required this.month,
    this.isGoalNotified = false,
  });

  ContributionModel copyWith({
    String? id,
    String? userId,
    String? groupId,
    double? amount,
    double? goal,
    String? month,
    bool? isGoalNotified,
  }) {
    return ContributionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      groupId: groupId ?? this.groupId,
      amount: amount ?? this.amount,
      goal: goal ?? this.goal,
      month: month ?? this.month,
      isGoalNotified: isGoalNotified ?? this.isGoalNotified,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'groupId': groupId,
        'amount': amount,
        'goal': goal,
        'month': month,
        'isGoalNotified': isGoalNotified,
      };

  factory ContributionModel.fromJson(Map<String, dynamic> json) {
    return ContributionModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      groupId: json['groupId'] as String,
      amount: (json['amount'] as num).toDouble(),
      goal: (json['goal'] as num).toDouble(),
      month: json['month'] as String,
      isGoalNotified: json['isGoalNotified'] as bool? ?? false,
    );
  }
}