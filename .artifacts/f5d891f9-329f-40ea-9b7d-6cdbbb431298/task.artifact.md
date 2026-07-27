# Task List - v3.2.11 (Rastreabilidade e BI) 🛰️📊

### 🛰️ Step 1: Rastreabilidade Automática
- [ ] Refatorar `RoundRepository.saveCompleteRound` para detectar mudanças de setor.
- [ ] Implementar gravação na sub-coleção `movimentacoes` de cada ativo.

### 📉 Step 2: Dashboard de Divergências
- [ ] Criar lógica `getDivergenceRanking` no `DashboardController`.
- [ ] Implementar visualização de Ranking de Divergências no `DashboardPage`.
- [ ] Adicionar métricas de porcentagem de erro por setor.

### 🚀 Step 3: Alinhamento e Finalização
- [ ] Atualizar versão para 3.2.11 em `pubspec.yaml` e `build.gradle.kts`.
- [ ] Atualizar log de novidades na `AboutPage`.
- [ ] Gerar APK v3.2.11.
