# CHANGELOG - Smart Ronda TI 🚀

## [3.3.6] - 2026-08-04
### ✨ Persistência e Estabilidade
- **Correção de Locação**: Restaurada a persistência dos campos `is_locado` e `locadora` no inventário mestre.
- **Ciclo de Vida**: Persistência do campo `ano_fabricacao` normalizada.
- **Limpeza Técnica**: Remoção de avisos de cast e correção de escopo de variáveis no repositório.

## [3.3.5] - 2026-08-02
### ✨ Segurança e Inteligência de Dashboard
- **Restrição de Funções**: Botões de 'Empréstimo' e 'Limpar Tudo' agora são exclusivos para os níveis Master/Gerente.
- **Dashboard Mensal**: A aba 'Geral' agora exibe automaticamente apenas os dados do mês vigente para foco operacional.
- **Inteligência de Backup**: O card de Reservados agora identifica automaticamente qualquer ativo no setor TI que não esteja em manutenção.
- **Contabilidade Retroativa**: Correção nos relatórios de substituição para exibir a data real informada em rondas retroativas.

## [3.3.4] - 2026-08-01
### ✨ Correções de Permissões e Estabilidade Crítica
- **Fim do Permission Denied**: Refatoração da lógica de salvamento para permitir transferências e edições por técnicos sem erros de banco.
- **Rastreio de Manutenção**: Itens substituídos agora preservam o cronômetro de reparo e status 'Em manutenção'.
- **Dashboard Backup**: Novo card dedicado para itens em estoque (Reservados) na TI.
- **Relatórios Saneados**: Filtros de incidências agora rodam sem depender de índices do Firebase.

## [3.3.3] - 2026-07-31
### ✨ Gestão de Saídas e Notificações Inteligentes
- **Módulo de Empréstimo**: Novo status para rastrear ativos fora da unidade (Data, Motivo e Destino).
- **Home Office Restaurado**: Exibição de Responsável, Marca e Modelo nas listagens de ativos externos.
- **Alertas de Auditoria Individual**: Notificações para equipamentos específicos sem visita há mais de 30 dias.
- **Diretrizes de BI (Admin)**: Painel para Gerentes/Master ativarem/desativarem tipos específicos de alertas.
- **Relatórios Enriquecidos**: Inclusão das colunas Número de Série e Processador em todas as exportações.
- **Substituições Precisas**: Possibilidade de informar data personalizada em trocas de equipamentos.

## [3.3.2] - 2026-07-29
### ✨ Refinamentos de Governança e OPEX
- **Rastreabilidade de Manutenção**: Agora exibe Setor de Origem, Local Atual (TI), Dias em Aberto e Motivo no Dashboard.
- **Simulador por Departamento**: Expansão da inteligência de simulação para prever aditivos baseados no perfil de cada setor.
- **Filtros Avançados**: Central de Relatórios agora permite filtrar por Marca, Modelo e Processador.
- **Home Office Facilitado**: Switch de autorização permanente direto na edição do Castelo (Admin).
- **Limpeza de Versão**: Remoção definitiva de tags de build e restauração da hierarquia interativa de ativos.

## [3.3.1] - 2026-07-27
### 📈 Eficiência Executiva
- **Assinatura Profissional**: Relatórios agora saem com nome real do técnico, em preto e negrito.
- **Dados de Contato**: Locadoras agora possuem CNPJ, E-mail, Telefone e Endereço para gestão de suprimentos.
- **Mapa de Calor**: Reordenação para Verde (Seguro) -> Amarelo (Atenção) -> Vermelho (Crítico).

## [3.3.0] - 2026-07-27
### 🧠 Inteligência Preditiva e Cockpit OPEX
- **Health Score (0-100%)**: Inteligência que mede a saúde individual de cada ativo.
- **Plano de Ação Automático**: Sugestões de Capex/Manutenção baseadas no Score.
- **Cockpit de Contratos**: Visão real vs contratado por locadora.

## [3.2.11] - 2026-07-27
### 🔍 Rastreabilidade Automática
- **Histórico de Movimentação**: Registro automático de cada troca de departamento.
- **Ranking de Divergências**: Indicador de ativos fora do lugar por setor.

---
> "Evoluindo a gestão hospitalar através da tecnologia." 🏛️📊🛡️💎⚡🚀
