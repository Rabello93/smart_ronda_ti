import 'package:flutter/material.dart';
import 'package:smart_ronda_ti/features/management/reports/repositories/report_repository.dart';
import 'package:smart_ronda_ti/features/management/admin/controllers/admin_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  final AdminController _adminController = AdminController();
  
  String? _setorSelecionado;
  String? _formatoSelecionado = 'PDF';
  
  bool _apenasDefeitos = false;
  bool _apenasObsoletos = false;
  bool _emManutencao = false;
  bool _emDivergencia = false;
  bool _reservados = false;
  bool _gerando = false;

  Future<void> _gerarRelatorio() async {
    setState(() => _gerando = true);
    try {
      final firestore = FirebaseFirestore.instance;
      Query query = firestore.collection('inventario_mestre');

      if (_setorSelecionado != null) {
        query = query.where('setor', isEqualTo: _setorSelecionado);
      }
      if (_apenasDefeitos) {
        query = query.where('tem_defeito', isEqualTo: true);
      }
      if (_emManutencao) {
        query = query.where('status_operacional', isEqualTo: 'Em manutenção');
      }
      if (_reservados) {
        query = query.where('status_operacional', isEqualTo: 'Reservado');
      }
      if (_emDivergencia) {
        query = query.where('setor_divergente', isEqualTo: true);
      }

      final snapshot = await query.get();
      var itens = snapshot.docs.map((d) => d.data() as Map<String, dynamic>).toList();

      if (_apenasObsoletos) {
        final int currentYear = DateTime.now().year;
        itens = itens.where((i) {
          int? ano = i['ano_fabricacao'];
          return ano != null && (currentYear - ano >= 5);
        }).toList();
      }

      if (itens.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nenhum item encontrado com estes filtros.")));
        return;
      }

      if (mounted) {
        if (_formatoSelecionado == 'PDF') {
          await ReportRepository.exportarLocacaoParaPDF(context, itens, "Relatório de Inventário Filtrado");
        } else {
          await ReportRepository.exportarMapaAtivosSetorXML(setor: _setorSelecionado ?? "GERAL", itens: itens, context: context);
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro ao gerar: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _gerando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Central de Relatórios"),
        backgroundColor: Colors.indigo.shade900,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Filtros de Inventário", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _adminController.sectorsStream,
              builder: (context, snapshot) {
                final setores = snapshot.data ?? [];
                return DropdownButtonFormField<String>(
                  value: _setorSelecionado,
                  decoration: const InputDecoration(labelText: "Filtrar por Setor (Opcional)", border: OutlineInputBorder()),
                  items: [
                    const DropdownMenuItem(value: null, child: Text("Todos os Setores")),
                    ...setores.map((s) => DropdownMenuItem(value: s['nome'], child: Text(s['nome']))),
                  ],
                  onChanged: (v) => setState(() => _setorSelecionado = v),
                );
              }
            ),
            
            const SizedBox(height: 20),
            const Text("Condições Específicas:", style: TextStyle(fontWeight: FontWeight.bold)),
            CheckboxListTile(
              title: const Text("Equipamentos com +5 anos (Obsoletos)"),
              value: _apenasObsoletos,
              onChanged: (v) => setState(() => _apenasObsoletos = v!),
            ),
            CheckboxListTile(
              title: const Text("Equipamentos com Defeito"),
              value: _apenasDefeitos,
              onChanged: (v) => setState(() => _apenasDefeitos = v!),
            ),
            CheckboxListTile(
              title: const Text("Equipamentos em Manutenção"),
              value: _emManutencao,
              onChanged: (v) => setState(() => _emManutencao = v!),
            ),
            CheckboxListTile(
              title: const Text("Equipamentos em Divergência de Setor"),
              value: _emDivergencia,
              onChanged: (v) => setState(() => _emDivergencia = v!),
            ),
            CheckboxListTile(
              title: const Text("Equipamentos Reservados"),
              value: _reservados,
              onChanged: (v) => setState(() => _reservados = v!),
            ),
            
            const Divider(height: 40),
            const Text("Formato de Saída", style: TextStyle(fontWeight: FontWeight.bold)),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text("PDF"),
                    value: 'PDF',
                    groupValue: _formatoSelecionado,
                    onChanged: (v) => setState(() => _formatoSelecionado = v),
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text("XML"),
                    value: 'XML',
                    groupValue: _formatoSelecionado,
                    onChanged: (v) => setState(() => _formatoSelecionado = v),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: _gerando ? null : _gerarRelatorio,
                icon: _gerando ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.description),
                label: Text(_gerando ? "PROCESSANDO..." : "GERAR RELATÓRIO AGORA"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo.shade900,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
