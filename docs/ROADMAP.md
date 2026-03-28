# 🚀 GymCash - Roadmap

## ✅ Concluído (v1.0 — MVP)
- [x] Onboarding sem fricção (só nome, sem cadastro)
- [x] Criação e gestão de grupos com controle de membros
- [x] Registro e edição de contribuição mensal com meta individual
- [x] Ranking em tempo real baseado em `amount / goal` — valores nunca expostos
- [x] Fechamento automático de mês com snapshot imutável
- [x] Histórico de rankings expansível com vencedor registrado

## ✅ Concluído (v1.1 — Polimento e Gamificação)
- [x] **LocalStorageService:** Gateway único com tratamento de erros em PT-BR
- [x] **TransactionListView:** Extrato de contribuições com identidade Deep Black & Electric Blue
- [x] **Achievement Toasts:** Notificações animadas em Overlay (persiste após troca de rota)
- [x] **Meta Atingida:** Lógica de `isGoalNotified` + diálogo animado com haptic feedback
- [x] **ProfileScreen:** Tela de perfil com streak, patente, acumulado e conquistas
- [x] **Renomear grupos:** Disponível na HomeScreen e na GroupScreen
- [x] **Streak:** Sequência de meses consecutivos com feedback visual progressivo
- [x] **Patentes:** Bronze → Prata → Ouro → Platina → Diamante
- [x] **11 Achievements:** Cobrindo depósitos, vitórias, streaks e patentes

## ✅ Concluído (pré-v1.2 — Qualidade e Robustez)
- [x] **IdGenerator:** Substitui timestamp puro por timestamp + contador atômico — elimina risco de colisão de IDs em operações rápidas
- [x] **Testes unitários:** 51 casos cobrindo `StreakService`, `LocalStorageService`, `RankModel` e `ContributionModel`
- [x] **Smoke test real:** `widget_test.dart` com validação de renderização e campos do onboarding
- [x] **TransactionListView:** Remove botão de debug "Simular transação"; adiciona barra de progresso e badge de meta nos tiles

## 🛠️ Próximos Passos (v1.2)
- [ ] **Ordenação de grupos:** Escolher entre ordem alfabética ou mais recentes
- [ ] **Gráficos de evolução:** Visualizar progresso mensal em barras ou linha
- [ ] **Exportação de dados:** Gerar relatório CSV ou PDF do extrato

## 📋 Planejado (v2.0)
- [ ] Backend Firebase + autenticação Google
- [ ] Multiusuário real com dados sincronizados
- [ ] Migração de dados locais para Firestore

## 📋 Planejado (v2.1)
- [ ] Convites por link para grupos
- [ ] Notificações push mensais

## 💡 Conceitual (v3.0)
- [ ] Insights financeiros personalizados
- [ ] Relatórios de consistência e evolução
