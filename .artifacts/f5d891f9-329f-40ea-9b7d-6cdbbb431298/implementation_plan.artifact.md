# Implementation Plan - Redesign Visual "Smart Tech 3.2.9"

Repaginar a interface completa do Smart Ronda TI para um visual tecnológico "Premium", com foco em fluidez, legibilidade e uma experiência de "Mission Control" no Dashboard.

## User Review Required

> [!IMPORTANT]
> **Fontes**: Vou adotar a combinação **Inter** (para textos longos) e **JetBrains Mono** (para números e dados técnicos). Isso requer conexão com a internet no primeiro build para baixar as fontes via `google_fonts`.
> **Cores**: A base do Dark será `0xFF0A0E14` (Deep Navy) com detalhes em `0xFF00E5FF` (Cyan Neon). O Light usará `0xFFF5F7FA` (Cool Grey).

## Proposed Changes

### [Global]
#### [MODIFY] [pubspec.yaml](file:///C:/Users/fabio/ronda_equipamentos/smart_ronda_ti/pubspec.yaml)
- Adicionar dependência `google_fonts: ^6.2.1`.
- Atualizar versão para `3.2.9+13`.

#### [MODIFY] [theme.dart](file:///C:/Users/fabio/ronda_equipamentos/smart_ronda_ti/lib/app/theme.dart)
- Implementar o novo sistema de design centralizado.
- Configurar `ColorScheme`, `TextTheme` (Inter/JetBrains Mono) e `CardTheme` (borderRadius 20dp).

### [Dashboard & Management]
#### [MODIFY] [dashboard_page.dart](file:///C:/Users/fabio/ronda_equipamentos/smart_ronda_ti/lib/features/management/dashboard/pages/dashboard_page.dart)
- Refatorar para o estilo "Mission Control".
- Implementar gradientes nos gráficos e efeito de vidro na Sidebar.
- Atualizar rodapé para v3.2.9.

### [Operational UI]
#### [MODIFY] [home_page.dart](file:///C:/Users/fabio/ronda_equipamentos/smart_ronda_ti/lib/features/operation/rounds/pages/home_page.dart)
- Modernizar botões de ação e banners de alerta.
- Atualizar rodapé para v3.2.9.

#### [MODIFY] [ronda_page.dart](file:///C:/Users/fabio/ronda_equipamentos/smart_ronda_ti/lib/features/operation/rounds/pages/ronda_page.dart)
- Ajustar inputs e chips para o novo padrão fluido.

#### [MODIFY] [about_page.dart](file:///C:/Users/fabio/ronda_equipamentos/smart_ronda_ti/lib/features/system/about/pages/about_page.dart)
- Atualizar log de novidades da v3.2.9.

## Verification Plan

### Manual Verification
- Testar legibilidade nos modos Light e Dark.
- Validar se o Dashboard reflete o novo estilo "Premium Tech".
- Confirmar que a navegação e botões mantêm suas funcionalidades originais.
