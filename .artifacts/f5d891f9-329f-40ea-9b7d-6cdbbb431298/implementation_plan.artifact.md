# Implementation Plan - v3.2.11 (Rastreabilidade e BI) 🛰️📊

Esta versão foca na rastreabilidade histórica dos ativos e no aprofundamento das métricas de divergência por departamento, transformando dados operacionais em insights de gestão.

## User Review Required

> [!IMPORTANT]
> **Histórico de Movimentação**: Cada ativo no "Castelo" passará a ter uma sub-coleção no Firestore chamada `movimentacoes`. Isso registrará automaticamente toda vez que um item mudar de departamento.
> **Impacto no Banco**: A gravação da ronda será ligeiramente mais lenta (frações de segundo) pois verificaremos o local anterior de cada item antes de atualizar.

## Proposed Changes

### [Operation - Rastreabilidade]
#### [MODIFY] [RoundRepository](file:///C:/Users/fabio/ronda_equipamentos/smart_ronda_ti/lib/features/operation/rounds/repositories/round_repository.dart)
- No método `saveCompleteRound`, antes de atualizar o `inventario_mestre`, buscar o documento atual do ativo.
- Se o campo `setor` for diferente do novo setor da ronda:
    - Adicionar um registro na sub-coleção `inventario_mestre > [ID] > movimentacoes`.
    - Campos do registro: `origem`, `destino`, `data`, `tecnico_uid`, `ronda_id`.

### [Management - Dashboard & BI]
#### [MODIFY] [DashboardController](file:///C:/Users/fabio/ronda_equipamentos/smart_ronda_ti/lib/features/management/dashboard/controllers/dashboard_controller.dart)
- Criar método `getDivergenceRanking(List<AssetModel> allAssets)`:
    - Filtrar ativos onde `setorDivergente == true`.
    - Agrupar contagem por departamento (`setor`).
    - Retornar lista ordenada decrescente.

#### [MODIFY] [DashboardPage](file:///C:/Users/fabio/ronda_equipamentos/smart_ronda_ti/lib/features/management/dashboard/pages/dashboard_page.dart)
- Adicionar uma nova seção visual (ou aba) chamada **"Ranking de Divergências"**.
- Exibir os Top 5 departamentos com mais itens fora do lugar, usando porcentagem relativa ao total de ativos do setor.

### [Global/Versão]
#### [MODIFY] [pubspec.yaml](file:///C:/Users/fabio/ronda_equipamentos/smart_ronda_ti/pubspec.yaml)
- Incrementar versão para **3.2.11+15**.

#### [MODIFY] [build.gradle.kts](file:///C:/Users/fabio/ronda_equipamentos/smart_ronda_ti/android/app/build.gradle.kts)
- Atualizar `versionName` para "3.2.11" e `versionCode` para 47.

#### [MODIFY] [about_page.dart](file:///C:/Users/fabio/ronda_equipamentos/smart_ronda_ti/lib/features/system/about/pages/about_page.dart)
- Incluir o log de novidades da v3.2.11.

## Verification Plan

### Rastreabilidade Automática
- Realizar uma ronda no setor "TI" com um item que hoje consta no "Financeiro".
- Verificar no Firestore se a sub-coleção `movimentacoes` do item foi criada com o salto de Financeiro -> TI.

### Dashboard de BI
- Marcar propositalmente 3 itens de setores diferentes como "Divergentes" na ronda.
- Validar se o gráfico de Ranking no Dashboard reflete corretamente esses números.
