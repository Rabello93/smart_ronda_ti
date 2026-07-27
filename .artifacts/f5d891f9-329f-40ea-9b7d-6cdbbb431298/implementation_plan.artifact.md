# Implementation Plan - v3.3.0 🚀📈🏛️ (Inteligência Preditiva & OPEX Pro)

Esta versão transforma o Smart Ronda TI em uma plataforma de consultoria estratégica, automatizando o diagnóstico de saúde do parque tecnológico e fornecendo um simulador financeiro para contratos de locação.

## User Review Required

> [!IMPORTANT]
> **Health Score Visível**: A nota de saúde (0-100%) agora será exibida em todos os modais de detalhes do equipamento. Isso mudará a percepção de risco para os técnicos.
> **Simulador de Capacidade**: Criaremos uma ferramenta no Dashboard onde o gestor pode simular o impacto de novos usuários/setores no contrato atual de locação.

## Proposed Changes

### [Management - Dashboard & BI]
#### [MODIFY] [dashboard_page.dart](file:///C:/Users/fabio/ronda_equipamentos/smart_ronda_ti/lib/features/management/dashboard/pages/dashboard_page.dart)
- **Detalhes do Equipamento**: Incluir o campo "Score de Saúde" com cor dinâmica (Verde/Amarelo/Vermelho) nos modais de lista.
- **Aba Contratos**: Implementar o **Simulador de Expansão** (Input de usuários extras e cálculo automático de déficit).

#### [MODIFY] [dashboard_controller.dart](file:///C:/Users/fabio/ronda_equipamentos/smart_ronda_ti/lib/features/management/dashboard/controllers/dashboard_controller.dart)
- Criar método `simulateCapacity(List<AssetModel> currentAssets, Map<String, int> contractedMap, int extraUsers)`:
    - Calcula o déficit imediato baseado na média de itens por usuário ou entrada manual.

### [Management - Admin]
#### [MODIFY] [admin_repository.dart](file:///C:/Users/fabio/ronda_equipamentos/smart_ronda_ti/lib/features/management/admin/repositories/admin_repository.dart)
- Implementar histórico de alterações contratuais para cada locadora (Log de Compliance).

### [Management - Relatórios]
#### [MODIFY] [report_repository.dart](file:///C:/Users/fabio/ronda_equipamentos/smart_ronda_ti/lib/features/management/reports/repositories/report_repository.dart)
- **Refinamento PDF**: Adicionar cores condicionais na coluna "Ação Sugerida" para chamar atenção do gestor para itens críticos.

### [Global/Versão]
#### [MODIFY] [pubspec.yaml](file:///C:/Users/fabio/ronda_equipamentos/smart_ronda_ti/pubspec.yaml), [build.gradle.kts](file:///C:/Users/fabio/ronda_equipamentos/smart_ronda_ti/android/app/build.gradle.kts)
- Finalizar o bump para v3.3.0 Build 48.

## Verification Plan

### Manual Verification
- Acessar o Dashboard > Contratos e simular a entrada de 20 novos usuários. Verificar se o sistema aponta a necessidade de novos notebooks corretamente.
- Abrir os detalhes de um notebook antigo (+5 anos) e validar se o Health Score está abaixo de 70% e em cor amarela/vermelha.
- Gerar um PDF de Inventário e validar as cores na coluna de recomendação.
