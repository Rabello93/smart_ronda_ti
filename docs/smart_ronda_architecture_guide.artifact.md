# SmartRonda Architecture Guide

Este guia define a estrutura arquitetural do projeto **SmartRonda TI**, garantindo escalabilidade, manutenibilidade e uma separação clara de responsabilidades.

## 🏗️ Estrutura de Camadas

A arquitetura é dividida em quatro camadas principais:

### 1. App (`lib/app/`)
Responsável pela configuração global do aplicativo.
- `app.dart`: O widget raiz do MaterialApp.
- `router.dart` / `routes.dart`: Gerenciamento de rotas e navegação.
- `theme.dart`: Definições globais de estilo (Claro/Escuro).

### 2. Core (`lib/core/`)
O "motor" do sistema. Contém funcionalidades essenciais e independentes de feature.
- `config/`: Configurações de ambiente (Firebase, APIs).
- `constants/`: Strings, cores fixas, dimensões.
- `database/`: Helpers de persistência local ou remota.
- `errors/`: Definições de exceções e falhas.
- `network/`: Cliente HTTP e interceptadores.
- `services/`: Serviços globais (Notificações, Conectividade).
- `utils/`: Funções auxiliares e extensões.

### 3. Shared (`lib/shared/`)
Componentes reutilizáveis por múltiplas features.
- `widgets/`: Botões, inputs e componentes genéricos.
- `dialogs/`: Alertas e modais padronizados.
- `cards/`: Layouts de cartões reutilizáveis.
- `forms/`: Mixins ou componentes de validação.

### 4. Features (`lib/features/`)
Onde reside a lógica de negócio, organizada por domínio e categoria.

#### **Operação (`operation/`)**
Ações do dia a dia no campo.
- `assets/`: Catálogo, Manutenção, Ciclo de Vida (Lifecycle), Anexos.
- `rounds/`: Scanner, Auditoria, Divergências, Checklist.

#### **Gestão (`management/`)**
Visão analítica e administrativa.
- `dashboard/`: Visões gerais e rankings.
- `reports/`: Exportação e filtros avançados.
- `admin/`: Gestão de usuários, setores e logs.

#### **Sistema (`system/`)**
Funcionalidades de suporte e infraestrutura de usuário.
- `auth/`: Login, Registro, Recuperação.
- `notifications/`: Centro de mensagens.
- `settings/`: Preferências (Idioma, Backup).
- `about/`: Informações da versão.

---

## 🛠️ Regras de Comunicação

1.  **Independência de Módulo**: Uma feature não deve depender diretamente de outra feature se possível. Use `Shared` ou `Core` para comunicação.
2.  **Propriedade da Informação**: O histórico de uma entidade pertence ao seu respectivo módulo (ex: `assets/history/` em vez de um módulo `history/` global).
3.  **Fluxo de Dados**: Repository -> Controller -> Page/Widget.

## 🚀 Como Adicionar uma Nova Feature

1.  Identifique a categoria (`operation`, `management` ou `system`).
2.  Crie a pasta dentro de `features/[categoria]/[nome_feature]`.
3.  Siga a estrutura interna: `controllers/`, `models/`, `repositories/`, `pages/`, `widgets/`.
4.  Registre as rotas em `lib/app/routes.dart`.
