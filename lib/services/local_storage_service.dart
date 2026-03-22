// lib/services/local_storage_service.dart

// Importe o novo modelo de resultado no topo do arquivo:
// import '../models/contribution_save_result.dart';

Future<ContributionSaveResult> saveContribution({
  required String userId,
  required String groupId,
  required double amount,
  required double goal,
}) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final monthKey = "${now.year}-${now.month.toString().padLeft(2, '0')}";
    
    // 1. Carregar lista atual
    final String? contributionsJson = prefs.getString('contributions');
    List<ContributionModel> allContributions = [];
    
    if (contributionsJson != null) {
      final List<dynamic> decoded = json.decode(contributionsJson);
      allContributions = decoded.map((item) => ContributionModel.fromJson(item)).toList();
    }

    // 2. Procurar se já existe registro para este Usuário/Grupo/Mês
    final index = allContributions.indexWhere(
      (c) => c.userId == userId && c.groupId == groupId && c.month == monthKey
    );

    bool goalJustReached = false;
    ContributionModel contribution;

    if (index != -1) {
      // Atualização de registro existente
      final existing = allContributions[index];
      
      // LÓGICA DE META: 
      // Se (novo saldo >= meta) E (ainda não foi notificado) E (meta > 0)
      if (amount >= goal && !existing.isGoalNotified && goal > 0) {
        goalJustReached = true;
      }

      contribution = existing.copyWith(
        amount: amount,
        goal: goal,
        isGoalNotified: goalJustReached ? true : existing.isGoalNotified,
      );
      allContributions[index] = contribution;
    } else {
      // Novo registro
      goalJustReached = (amount >= goal && goal > 0);
      
      contribution = ContributionModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        groupId: groupId,
        amount: amount,
        goal: goal,
        month: monthKey,
        isGoalNotified: goalJustReached,
      );
      allContributions.add(contribution);
    }

    // 3. Salvar de volta
    final success = await prefs.setString(
      'contributions', 
      json.encode(allContributions.map((e) => e.toJson()).toList())
    );

    if (!success) {
      throw LocalStorageException('Erro técnico ao persistir dados no dispositivo.');
    }

    return ContributionSaveResult(
      contribution: contribution,
      goalJustReached: goalJustReached,
    );
  } catch (e) {
    if (e is LocalStorageException) rethrow;
    throw LocalStorageException('Falha ao salvar contribuição: ${e.toString()}');
  }
}