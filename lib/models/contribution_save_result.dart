// lib/models/contribution_save_result.dart
import 'contribution_model.dart';

class ContributionSaveResult {
  final ContributionModel contribution;
  final bool goalJustReached; // TRUE se bateu a meta exatamente agora

  ContributionSaveResult({
    required this.contribution,
    required this.goalJustReached,
  });
}
