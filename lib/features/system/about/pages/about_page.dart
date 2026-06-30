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
                  Text("Versão 3.2.0", style: TextStyle(color: Colors.grey)),
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
              "3.2.0 (Atual)",
              "• SEGURANÇA: Implementação de login por biometria (Impressão Digital).\n• RELATÓRIOS: Padronização de nomes de arquivos exportados para 'relatorio_sequencia'.\n• UI/UX: Refatoração de títulos para um tom mais profissional e executivo.\n• PERFORMANCE: Otimização de widgets com 'const' e correção de warnings do analisador.",
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
