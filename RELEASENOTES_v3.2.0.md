# 📑 Relatório de Entrega e Notas de Lançamento

**Versão:** 3.2.0 Stable
**Data:** 25 de Junho de 2024
**Responsável:** Smart Ronda TI - Development Team

---

## 🚀 O que há de novo na v3.2.0?

Nesta atualização, focamos em **Segurança**, **Profissionalismo** e **Performance**. O sistema agora conta com autenticação biométrica e uma identidade visual mais executiva.

### 🛡️ Segurança e Acesso
*   **Autenticação Biométrica**: Adicionada compatibilidade com Impressão Digital e FaceID. Agora o técnico pode entrar no sistema instantaneamente após o primeiro login.
*   **Alertas de Cadastro**: Gestores (Master/Gerente) recebem notificações em tempo real no app quando um novo usuário se cadastra e aguarda aprovação.
*   **Armazenamento Seguro**: As credenciais são criptografadas e armazenadas localmente usando `FlutterSecureStorage` (AES/RSA).

### 📊 Relatórios e Gestão
*   **Central de Relatórios Unificada**: Nova seção dentro da aba Admin que centraliza todos os relatórios de Inventário e Performance em um único lugar.
*   **Padronização de Arquivos**: Todos os arquivos exportados (PDF, CSV, XML) agora seguem o padrão `relatorio_[timestamp].ext`, garantindo compatibilidade total.
*   **Títulos Executivos**: Alteração de rótulos informais para termos corporativos. Exemplo: "Quem fez o quê" agora é **"Histórico de Atividades Recentes"**.
*   **Gestão Home Office**: Implementado rastreio de ativos externos com indicação de responsável e filtro dedicado na central de relatórios.
*   **Lupa Inteligente**: Busca no inventário agora prioriza automaticamente os itens do setor onde a ronda está sendo realizada.

### ⚡ Performance e Estabilidade
*   **Otimização de Memória**: Refatoração profunda utilizando modificadores `const` em widgets estáticos, reduzindo o consumo de CPU e bateria.
*   **Code Quality**: Resolução de 100% dos avisos (warnings) do analisador de código, garantindo um binário mais estável e livre de bugs latentes.
*   **Compatibilidade**: Atualização das dependências `local_auth` e `flutter_secure_storage` para as versões mais recentes.

---

## 🛠️ Detalhes Técnicos (Checklist de Entrega)
*   [x] **Versão do App**: `3.2.0` (Sincronizada no pubspec e rodapés).
*   [x] **Version Code**: `36`.
*   [x] **Biometria**: Ativada para Android (FragmentActivity) e iOS.
*   [x] **Build**: APK Release gerado com sucesso.

---

## 📋 Como atualizar?
1. Execute `flutter pub get` para baixar as novas dependências de biometria.
2. Certifique-se de que o dispositivo possui biometria cadastrada no sistema operacional.
3. No primeiro login, use e-mail e senha. O app perguntará se deseja usar a biometria nas próximas vezes.

---
**Smart Ronda TI** - *Governança de Ativos com Inteligência Estratégica.*
