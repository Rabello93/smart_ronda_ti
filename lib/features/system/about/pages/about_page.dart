import 'package:flutter/material.dart';
import 'package:smart_ronda_ti/features/management/reports/repositories/report_repository.dart';
import 'package:smart_ronda_ti/features/system/auth/controllers/auth_controller.dart';
import 'package:smart_ronda_ti/features/system/auth/models/user_model.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = AuthController();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Sobre o Sistema"),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<UserModel?>(
        stream: authController.profileStream,
        builder: (context, snapshot) {
          final user = snapshot.data;
          final isMaster = user?.isMaster ?? false;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Column(
                    children: [
                      Icon(Icons.checklist_rtl, size: 80, color: Colors.blue),
                      SizedBox(height: 10),
                      Text("Smart Ronda TI", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  Text("Versão 3.2.2", style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 30),
            _sectionTitle("🚀 Governança e Inteligência"),
            const Text(
              "O Smart Ronda TI é um ecossistema inteligente de governança e auditoria de ativos, que transforma rondas técnicas em campo em inteligência estratégica para a tomada de decisão corporativa.",
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 20),
            _sectionTitle("🚀 Log de Atualizações"),
            _buildUpdate(
              "3.2.2 (Atual)",
              "• RELATÓRIOS: Inteligência de união de filtros (OU) e novo Mapa de Incidências Críticas (Manutenções/Divergências).\n• GESTÃO: Reativação da vassourinha laranja e edição de Patrimônio direto no Castelo.\n• DASHBOARD: Expansão da aba Locação para 'Gestão de Ativos', incluindo patrimônio próprio.\n• OPERAÇÃO: Conversão automática de itens 'Sem Placa' para 'Com Patrimônio' via Lupa.\n• BI: Novo filtro e relatório exclusivo para itens sem patrimônio físico.",
            ),
            _buildUpdate(
              "3.2.1",
              "• RELATÓRIOS: Correção na exibição de patrimônio nos relatórios técnicos de rondas.\n• INTELIGÊNCIA: Subtítulos dinâmicos nos relatórios que refletem os filtros selecionados.\n• UI/UX: Melhoria na visibilidade dos botões de filtro no modo escuro.\n• ESTABILIDADE: Ajuste na persistência de dados do patrimônio durante a gravação da ronda.",
            ),
            _buildUpdate(
              "3.2.0",
              "• SEGURANÇA: Login por biometria e alertas em tempo real de novos cadastros para gestores.\n• RELATÓRIOS: Nova Central de Relatórios unificada na aba Admin com filtros avançados.\n• HOME OFFICE: Rastreio de ativos externos com indicação de responsável e relatórios dedicados.\n• INTELIGÊNCIA: Lupa de busca contextual que prioriza ativos do setor atual na ronda.\n• ARQUITETURA: Implementação de ReportController e limpeza completa de avisos de performance.",
            ),
                _buildUpdate(
                  "3.1.2",
                  "• UI/UX: Nova Sidebar Interativa com controle de expansão manual.\n• RESPONSIVIDADE: Adaptação completa do Dashboard para dispositivos móveis.\n• BRANDING: Logo de 100px no Dashboard com ajuste dinâmico.\n• CORREÇÃO: Resolução de erro de contraste e textos invisíveis no modo claro.",
                ),
                _buildUpdate(
                  "3.1.1",
                  "• DASHBOARD: Gráficos de Tendência, Alertas Críticos e Cobertura de Inventário.\n• METAS: Nova aba com KPIs em tempo real e comparativos mensais.\n• RELATÓRIOS: Performance de Metas em PDF (com Branding) e exportação XML para Excel.",
                ),
                _buildUpdate(
                  "3.1.0",
                  "• ARQUITETURA: Reestruturação completa para escalabilidade futurista (Capex, Intelligence, Audit).\n• STATUS: Aba Status do Dashboard com análise dinâmica de equipamentos em manutenção.",
                ),
                _buildUpdate(
                  "3.0.2",
                  "• CATEGORIAS: Acessórios dinâmicos que mudam conforme o tipo de item (Notebook, Impressora, etc).\n• MANUTENÇÃO: Itens em manutenção são vinculados automaticamente ao TI com motivo obrigatório.\n• DIVERGÊNCIA: Seleção de setor atual e justificativa para itens fora do local original.",
                ),
                _buildUpdate(
                  "2.1.11",
                  "• RELATÓRIOS: Inteligência de busca no 'Castelo' para itens obsoletos.",
                ),
                const SizedBox(height: 30),
                if (isMaster) ...[
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () => ReportRepository.exportarPropostaComercial(context),
                      icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                      label: const Text("GERAR APRESENTAÇÃO PARA VENDA"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade800, foregroundColor: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                const Center(
                  child: Text(
                    "Desenvolvido por Fábio Rabelo",
                    style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                  ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
    );
  }

  Widget _buildUpdate(String version, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(version, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          Text(description, style: const TextStyle(fontSize: 13, color: Colors.blueGrey)),
          const Divider(),
        ],
      ),
    );
  }
}
