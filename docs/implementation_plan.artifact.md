# Reestruturação Arquitetural SmartRonda (Visão CTO)

Este plano visa reorganizar o projeto para uma arquitetura profissional e escalável, dividindo-o em camadas claras e organizando as features por categorias conceituais.

## User Review Required

> [!WARNING]
> Esta é uma refatoração de grande escala. Quase todos os arquivos serão movidos e os imports serão atualizados. Isso pode quebrar referências temporariamente durante o processo.

## Proposed Changes

### Camada App & Core
- Criar `lib/app/` com `app.dart`, `router.dart`, `theme.dart`.
- Expandir `lib/core/` para incluir subpastas de configuração, constantes e rede.

### Camada Shared
- Criar `lib/shared/` para widgets e utilitários transversais.

### Camada Features (Reorganização Crítica)
- **Operation**: Mover `assets/` e `rounds/`. Refatorar internamente para suportar sub-domínios (Audit, Lifecycle, etc.).
- **Management**: Mover `dashboard/`, `reports/`, `admin/`. Incluir `logs/` em Admin.
- **System**: Mover `auth/`, `about/`. Criar placeholders para `notifications/` e `settings/`.

### Eliminação de Módulos "Frankenstein"
- Dissolver `lib/features/history/` e mover as páginas para os respectivos módulos (`rounds/history/` ou similar).

---

## Detalhes da Execução

1. **Fase 1: Infraestrutura (Core/Shared)**
   - Setup das novas pastas e migração de utilitários.
2. **Fase 2: Feature Category - System**
   - Migrar `auth` e `about`. Configurar `settings`.
3. **Fase 3: Feature Category - Operation**
   - Migrar `assets` (e criar sub-pastas como `lifecycle`).
   - Migrar `rounds`.
4. **Fase 4: Feature Category - Management**
   - Migrar `dashboard`, `reports` e `admin`.
5. **Fase 5: App & Main**
   - Refatorar `main.dart` e configurar o roteamento centralizado em `lib/app/`.

## Verification Plan

### Automated Tests
- Executar `flutter analyze` após cada fase para identificar e corrigir imports quebrados.

### Manual Verification
- Verificar se o fluxo de autenticação (Login -> Dashboard/Home) continua funcionando.
- Validar se o carregamento do logo e branding (agora no App layer) funciona corretamente.
- Testar a navegação entre as novas categorias de features.
