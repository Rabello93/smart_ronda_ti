# Task List - v3.2.11 (Rastreabilidade e BI) 🛰️📊

### 🛰️ Step 1: Rastreabilidade Automática
- [x] Refatorar `RoundRepository.saveCompleteRound` para detectar mudanças de setor.
- [x] Implementar gravação na sub-coleção `movimentacoes` de cada ativo.

### 📉 Step 2: Dashboard de Divergências
- [x] Criar lógica `getDivergenceRanking` no `DashboardController`.
- [x] Implementar visualização de Ranking de Divergências no `DashboardPage`.
- [x] Adicionar métricas de porcentagem de erro por setor.

### 🚀 Step 3: Alinhamento e Finalização
- [x] Atualizar versão para 3.2.11 em `pubspec.yaml` e `build.gradle.kts`.
- [x] Atualizar log de novidades na `AboutPage` (Incluindo restauração da v3.2.8).
- [x] Corrigir erros de compilação de tipos no `ReportController`.
- [x] Melhorar visibilidade de identificação de itens na ronda.
- [x] Adicionar legenda detalhada no mapa de calor.
