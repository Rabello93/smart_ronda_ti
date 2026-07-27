# Implementation Plan - Versão 3.2.10 🚀 (Evolução de Governança)

Esta versão foca em expandir a flexibilidade operacional (múltiplas substituições), refinar a inteligência de auditoria (semáforo de risco) e aprofundar o compliance administrativo (baixa patrimonial e contratos).

## User Review Required

> [!IMPORTANT]
> **Múltiplas Trocas**: O fluxo de troca na ronda agora permite uma lista de itens. Não haverá mais limite de uma troca por ronda.
> **Baixa Patrimonial**: O status "Descartado" será oficialmente renomeado para "Baixa Patrimonial", exigindo justificativa obrigatória.

## Proposed Changes

### [Step 1: Múltiplas Substituições na Ronda]
- **[MODIFY] [RoundRepository](file:///C:/Users/fabio/ronda_equipamentos/smart_ronda_ti/lib/features/operation/rounds/repositories/round_repository.dart)**: Alterar `saveCompleteRound` para aceitar `List<Map<String, dynamic>> exchanges`.
- **[MODIFY] [RondaPage](file:///C:/Users/fabio/ronda_equipamentos/smart_ronda_ti/lib/features/operation/rounds/pages/ronda_page.dart)**:
    - Implementar `List<Map<String, dynamic>> _listaTrocas`.
    - UI: Adicionar botão "ADICIONAR TROCA" que valida e move os dados dos campos para a lista.
    - UI: Exibir lista de trocas pendentes com opção de remover.

### [Step 2: Compliance e Baixa Patrimonial]
- **[MODIFY] [AssetModel](file:///C:/Users/fabio/ronda_equipamentos/smart_ronda_ti/lib/features/operation/assets/models/asset_model.dart)**: Adicionar campo `motivoBaixa`.
- **[MODIFY] [RondaPage](file:///C:/Users/fabio/ronda_equipamentos/smart_ronda_ti/lib/features/operation/rounds/pages/ronda_page.dart)**: Renomear status e adicionar campo de texto condicional.

### [Step 3: Central de Relatórios Inteligente]
- **[MODIFY] [ReportsPage](file:///C:/Users/fabio/ronda_equipamentos/smart_ronda_ti/lib/features/management/reports/pages/reports_page.dart)**: Mover o filtro de data para o topo. Tornar obrigatório para relatórios de performance e trocas.
- **[MODIFY] [ReportController](file:///C:/Users/fabio/ronda_equipamentos/smart_ronda_ti/lib/features/management/reports/controllers/report_controller.dart)**: Filtrar relatórios de substituição pelo período selecionado.
- **[MODIFY] [ReportRepository](file:///C:/Users/fabio/ronda_equipamentos/smart_ronda_ti/lib/features/management/reports/repositories/report_repository.dart)**: Incluir nome do emissor no rodapé dos PDFs.

### [Step 4: BI e Dashboard (Semáforo de Risco)]
- **[MODIFY] [DashboardController](file:///C:/Users/fabio/ronda_equipamentos/smart_ronda_ti/lib/features/management/dashboard/controllers/dashboard_controller.dart)**: Criar lógica de semáforo (0-15 Verde, 16-30 Amarelo, 30+ Vermelho).
- **[MODIFY] [DashboardPage](file:///C:/Users/fabio/ronda_equipamentos/smart_ronda_ti/lib/features/management/dashboard/pages/dashboard_page.dart)**: Exibir o mapa de calor de auditoria.

### [Step 5: Gestão Contratual e Perfil]
- **[MODIFY] [AdminPage](file:///C:/Users/fabio/ronda_equipamentos/smart_ronda_ti/lib/features/management/admin/pages/admin_page.dart)**: Submenu de detalhes contratuais para locadoras.
- **[NEW] [ProfilePage](file:///C:/Users/fabio/ronda_equipamentos/smart_ronda_ti/lib/features/system/auth/pages/profile_page.dart)**: Tela de personalização de cargo, nascimento e matrícula.

## Verification Plan

### Step 1
- Realizar ronda com 2 trocas e validar transferência para TI no Castelo.
- Gerar relatório de substituições e validar filtro de data.

### Step 2
- Dar baixa em um item e conferir se o motivo aparece no histórico/relatório.
- Validar rodapé com nome do usuário no PDF.
