# Walkthrough - Versão 3.2.7

Implementada a inteligência de substituição de ativos e o novo relatório detalhado de trocas.

## Alterações Realizadas

### Inteligência e Automação
- **[round_repository.dart](file:///C:/Users/fabio/ronda_equipamentos/smart_ronda_ti/lib/features/operation/rounds/repositories/round_repository.dart)**:
    - Adicionada inteligência que detecta substituições ao finalizar uma ronda.
    - O equipamento sinalizado como **Patrimônio Antigo** é automaticamente transferido para o setor **TI** com o status **Reservado** no Inventário Mestre.
    - Uma observação interna é gerada detalhando o setor de origem e o motivo da troca.

### Central de Relatórios
- **[reports_page.dart](file:///C:/Users/fabio/ronda_equipamentos/smart_ronda_ti/lib/features/management/reports/pages/reports_page.dart)**:
    - Adicionado o botão de filtro **🔄 SUBSTITUIÇÕES**.
- **[report_controller.dart](file:///C:/Users/fabio/ronda_equipamentos/smart_ronda_ti/lib/features/management/reports/controllers/report_controller.dart)**:
    - Nova lógica para consolidar eventos de troca de todas as rondas, enriquecendo os dados com informações do Castelo.
- **[report_repository.dart](file:///C:/Users/fabio/ronda_equipamentos/smart_ronda_ti/lib/features/management/reports/repositories/report_repository.dart)**:
    - Implementadas as funções de exportação (PDF e XLSX) para Substituições com as colunas solicitadas: Tipo, Patrimônio, Marca, Modelo, Série, Locadora, Depto Anterior, Data, Depto Atual (TI), Status e Motivo.

### Alinhamento Global (v3.2.7)
- Atualizada a versão em:
    - `pubspec.yaml`
    - `android/app/build.gradle.kts` (versionCode 43)
    - `dashboard_page.dart` (Rodapé)
    - `about_page.dart` (Log de Atualizações)
    - `report_repository.dart` (Rodapés dos documentos)

## Verificação
- O build APK deve ser gerado com o nome `smart_ronda_ti_v3.2.7.apk`.
- O log de atualizações reflete as melhorias de inteligência e relatórios.
