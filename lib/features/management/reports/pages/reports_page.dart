import 'package:flutter/material.dart';
import 'package:smart_ronda_ti/features/management/reports/controllers/report_controller.dart';
import 'package:smart_ronda_ti/features/management/admin/controllers/admin_controller.dart';
import 'package:intl/intl.dart';

class ReportsPage extends StatefulWidget {
  final bool embed;
  const ReportsPage({super.key, this.embed = false});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  final AdminController _adminController = AdminController();
  final ReportController _reportController = ReportController();
  
  // Filtros Inventário
  String? _setorSelecionado;
  String? _formatoSelecionado = 'PDF';
  bool _apenasDefeitos = false;
  bool _apenasObsoletos = false;
  bool _emManutencao = false;
  bool _emDivergencia = false;
  bool _reservados = false;
  bool _apenasHomeOffice = false;
  bool _gerandoInventario = false;

  // Filtros Performance
  DateTimeRange? _periodoPrincipal;
  DateTimeRange? _periodoComparativo;

  Future<void> _handleGerarInventario() async {
    setState(() => _gerandoInventario = true);
    await _reportController.gerarRelatorioInventario(
      context: context,
      setor: _setorSelecionado,
      apenasDefeitos: _apenasDefeitos,
      apenasObsoletos: _apenasObsoletos,
      emManutencao: _emManutencao,
      emDivergencia: _emDivergencia,
      reservados: _reservados,
      apenasHomeOffice: _apenasHomeOffice,
      formato: _formatoSelecionado!,
    );
    if (mounted) setState(() => _gerandoInventario = false);
  }

  @override
  Widget build(BuildContext context) {
    final content = SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SEÇÃO 1: INVENTÁRIO
          _sectionHeader("📦 GESTÃO DE INVENTÁRIO", Icons.inventory_2),
          const SizedBox(height: 20),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _adminController.sectorsStream,
            builder: (context, snapshot) {
              final setores = snapshot.data ?? [];
              return DropdownButtonFormField<String>(
                initialValue: _setorSelecionado,
                decoration: const InputDecoration(labelText: "Filtrar por Setor (Opcional)", border: OutlineInputBorder()),
                items: [
                  const DropdownMenuItem(value: null, child: Text("Todos os Setores")),
                  ...setores.map((s) => DropdownMenuItem(value: s['nome'], child: Text(s['nome']))),
                ],
                onChanged: (v) => setState(() => _setorSelecionado = v),
              );
            }
          ),
          const SizedBox(height: 15),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _filterChip("Obsoletos (+5 anos)", _apenasObsoletos, (v) => setState(() => _apenasObsoletos = v)),
              _filterChip("Com Defeito", _apenasDefeitos, (v) => setState(() => _apenasDefeitos = v)),
              _filterChip("Em Manutenção", _emManutencao, (v) => setState(() => _emManutencao = v)),
              _filterChip("Divergência Setor", _emDivergencia, (v) => setState(() => _emDivergencia = v)),
              _filterChip("Reservados", _reservados, (v) => setState(() => _reservados = v)),
              _filterChip("🏠 HOME OFFICE", _apenasHomeOffice, (v) => setState(() => _apenasHomeOffice = v), color: Colors.blue),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _formatRadio("PDF", 'PDF')),
              Expanded(child: _formatRadio("XML (Excel)", 'XML')),
            ],
          ),
          const SizedBox(height: 20),
          _actionButton(
            onPressed: _gerandoInventario ? null : _handleGerarInventario,
            label: _gerandoInventario ? "GERANDO..." : "GERAR RELATÓRIO DE INVENTÁRIO",
            icon: Icons.assignment,
          ),

          const Padding(padding: EdgeInsets.symmetric(vertical: 30), child: Divider()),

          // SEÇÃO 2: PERFORMANCE
          _sectionHeader("📈 PERFORMANCE E METAS", Icons.stars),
          const SizedBox(height: 20),
          ListTile(
            tileColor: Colors.blue.withValues(alpha: 0.05),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            leading: const Icon(Icons.date_range, color: Colors.blue),
            title: const Text("Período Principal"),
            subtitle: Text(_periodoPrincipal == null ? "Selecione o período" : "${DateFormat('dd/MM').format(_periodoPrincipal!.start)} até ${DateFormat('dd/MM').format(_periodoPrincipal!.end)}"),
            onTap: () async {
              final picked = await showDateRangePicker(context: context, firstDate: DateTime(2023), lastDate: DateTime.now());
              if (picked != null) setState(() => _periodoPrincipal = picked);
            },
          ),
          const SizedBox(height: 8),
          ListTile(
            tileColor: Colors.purple.withValues(alpha: 0.05),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            leading: const Icon(Icons.compare_arrows, color: Colors.purple),
            title: const Text("Período Comparativo (Opcional)"),
            subtitle: Text(_periodoComparativo == null ? "Toque para comparar meses" : "${DateFormat('dd/MM').format(_periodoComparativo!.start)} até ${DateFormat('dd/MM').format(_periodoComparativo!.end)}"),
            onTap: () async {
              final picked = await showDateRangePicker(context: context, firstDate: DateTime(2023), lastDate: DateTime.now());
              if (picked != null) setState(() => _periodoComparativo = picked);
            },
            trailing: _periodoComparativo != null ? IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _periodoComparativo = null)) : null,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _actionButton(
                  onPressed: () => _reportController.gerarRelatorioMetas(context, periodo: _periodoPrincipal, periodoComparativo: _periodoComparativo, formato: 'PDF'),
                  label: "PDF METAS",
                  icon: Icons.picture_as_pdf,
                  color: Colors.red.shade900,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _actionButton(
                  onPressed: () => _reportController.gerarRelatorioMetas(context, periodo: _periodoPrincipal, formato: 'XML'),
                  label: "XML METAS",
                  icon: Icons.code,
                  color: Colors.green.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );

    if (widget.embed) return content;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Central de Relatórios"),
        backgroundColor: Colors.indigo.shade900,
        foregroundColor: Colors.white,
      ),
      body: content,
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.indigo.shade900, size: 20),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
      ],
    );
  }

  Widget _filterChip(String label, bool selected, Function(bool) onSelected, {Color? color}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return FilterChip(
      label: Text(label, style: TextStyle(
        fontSize: 11, 
        color: selected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      )),
      selected: selected,
      onSelected: onSelected,
      selectedColor: color ?? Colors.indigo,
      backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200,
      checkmarkColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: selected ? (color ?? Colors.indigo) : (isDark ? Colors.white24 : Colors.grey.shade400),
        ),
      ),
    );
  }

  Widget _formatRadio(String label, String value) {
    return RadioListTile<String>(
      title: Text(label, style: const TextStyle(fontSize: 14)),
      value: value,
      groupValue: _formatoSelecionado,
      onChanged: (v) => setState(() => _formatoSelecionado = v),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _actionButton({required VoidCallback? onPressed, required String label, required IconData icon, Color? color}) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? Colors.indigo.shade900,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}
