import 'package:flutter/material.dart';
import 'package:smart_ronda_ti/features/management/reports/repositories/report_repository.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sobre o Sistema"),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
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
                  Text("Versão 3.1.1", style: TextStyle(color: Colors.grey)),
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
              "3.1.1 (Atual)",
              "• DASHBOARD: Implementação de Gráficos de Tendência (fl_chart) e Alertas Críticos.\n• METAS: Nova aba de Metas com indicadores de performance (KPIs) e comparativos mensais.\n• ADMIN: Painel de configuração de Metas Estratégicas e Relatório de Performance em PDF.\n• BI: Gráfico de Cobertura de Inventário e análise de Capex por categoria.\n• UI: Melhorias de contraste e legibilidade no modo claro.",
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
            Center(
              child: ElevatedButton.icon(
                onPressed: () => ReportRepository.exportarPropostaComercial(context),
                icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                label: const Text("GERAR APRESENTAÇÃO PARA VENDA"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade800, foregroundColor: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            const Center(
              child: Text(
                "Desenvolvido por Fábio Rabelo",
                style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
              ),
            ),
          ],
        ),
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
