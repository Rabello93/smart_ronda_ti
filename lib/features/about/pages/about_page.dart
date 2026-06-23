import 'package:flutter/material.dart';
import 'package:smart_ronda_ti/features/reports/repositories/pdf_repository.dart';

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
                  Text("Ronda TI", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  Text("Versão 2.1.11", style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 30),
            _sectionTitle("📝 Proposta"),
            const Text(
              "O app Ronda TI foi desenvolvido para otimizar as rondas técnicas em ambiente corporativo, garantindo que todos os ativos de TI estejam operacionais e devidamente inventariados.",
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 20),
            _sectionTitle("🚀 Log de Atualizações"),
            _buildUpdate(
              "2.1.11 (Atual)",
              "• RELATÓRIOS: Inteligência de busca no 'Castelo' para itens obsoletos mesmo sem rondas recentes.\n• UX: Retorno do texto 'INICIAR RONDA' no botão principal e remoção de botões redundantes.\n• ESTABILIDADE: Sincronização oficial de versão 2.1.11 em todo o ecossistema.",
            ),
            _buildUpdate(
              "2.1.10",
              "• FILTROS: Integração de 'Apenas Obsoletos' no menu global de exportação.\n• BRANDING: Fix robusto na conversão de links de logotipo do Google Drive.",
            ),
            _buildUpdate(
              "2.1.9",
              "• LOCAÇÃO: Drill-down avançado no Dashboard (Empresa > Tipo > Ativos).",
            ),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton.icon(
                onPressed: () => PdfRepository.exportarPropostaComercial(context),
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
