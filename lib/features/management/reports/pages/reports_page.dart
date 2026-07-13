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
  String? _locadoraSelecionada;
  String? _tipoEquipamentoSelecionado;
  String? _formatoSelecionado = 'PDF';
  bool _apenasDefeitos = false;
  bool _apenasObsoletos = false;
  bool _emManutencao = false;
  bool _emDivergencia = false;
  bool _reservados = false;
  bool _apenasHomeOffice = false;
  bool _apenasLocados = false;
  bool _apenasSemPatrimonio = false;
  bool _gerandoInventario = false;

  // Filtros Performance
  DateTimeRange? _periodoPrincipal;
  DateTimeRange? _periodoComparativo;

  Future<void> _handleGerarInventario() async {
    setState(() => _gerandoInventario = true);
    await _reportController.gerarRelatorioInventario(
      context: context,
      setor: _setorSelecionado,
      locadora: _locadoraSelecionada,
      tipo: _tipoEquipamentoSelecionado,
      apenasDefeitos: _apenasDefeitos,
      apenasObsoletos: _apenasObsoletos,
      emManutencao: _emManutencao,
      emDivergencia: _emDivergencia,
      reservados: _reservados,
      apenasHomeOffice: _apenasHomeOffice,
      apenasLocados: _apenasLocados,
      apenasSemPatrimonio: _apenasSemPatrimonio,
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
                decoration: const InputDecoration(labelText: "Filtrar por Departamento (Opcional)", border: OutlineInputBorder()),
                items: [
                  const DropdownMenuItem(value: null, child: Text("Todos os Departamentos")),
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
              _filterChip("Divergência Departamento", _emDivergencia, (v) => setState(() => _emDivergencia = v)),
              _filterChip("Reservados", _reservados, (v) => setState(() => _reservados = v)),
              _filterChip("🏠 HOME OFFICE", _apenasHomeOffice, (v) => setState(() => _apenasHomeOffice = v), color: Colors.blue),
              _filterChip("🤝 LOCADOS", _apenasLocados, (v) => setState(() => _apenasLocados = v), color: Colors.orange.shade800),
              _filterChip("🚫 SEM PATRIMÔNIO", _apenasSemPatrimonio, (v) => setState(() => _apenasSemPatrimonio = v), color: Colors.red.shade800),
            ],
          ),
          const SizedBox(height: 20),
          
          if (_apenasLocados) ...[
            StreamBuilder<List<String>>(
              stream: _adminController.leasingCompaniesStream,
              builder: (context, snapshot) {
                final locadoras = snapshot.data ?? [];
                return DropdownButtonFormField<String>(
                  initialValue: _locadoraSelecionada,
                  decoration: const InputDecoration(labelText: "Selecionar Locadora", border: OutlineInputBorder()),
                  items: [
                    const DropdownMenuItem(value: null, child: Text("Todas as Locadoras")),
                    ...locadoras.map((l) => DropdownMenuItem(value: l, child: Text(l))),
                  ],
                  onChanged: (v) => setState(() => _locadoraSelecionada = v),
                );
              }
            ),
            const SizedBox(height: 15),
          ],

          DropdownButtonFormField<String>(
            initialValue: _tipoEquipamentoSelecionado,
            decoration: const InputDecoration(labelText: "Filtrar por Tipo (Opcional)", border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: null, child: Text("Todos os Tipos")),
              DropdownMenuItem(value: 'Notebook', child: Text("Notebook")),
              DropdownMenuItem(value: 'Desktop', child: Text("Desktop")),
              DropdownMenuItem(value: 'Telefone', child: Text("Telefone")),
              DropdownMenuItem(value: 'Smartphone', child: Text("Smartphone")),
              DropdownMenuItem(value: 'Impressora', child: Text("Impressora")),
              DropdownMenuItem(value: 'TV', child: Text("TV")),
              DropdownMenuItem(value: 'No-Break', child: Text("No-Break")),
            ],
            onChanged: (v) => setState(() => _tipoEquipamentoSelecionado = v),
          ),

          const SizedBox(height: 25),
          const Text("Formato de Saída:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _formatChip("PDF", Icons.picture_as_pdf, Colors.red.shade900),
                const SizedBox(width: 8),
                _formatChip("XLSX", Icons.table_chart, Colors.green.shade900),
                const SizedBox(width: 8),
                _formatChip("CSV", Icons.grid_on, Colors.teal.shade900),
                const SizedBox(width: 8),
                _formatChip("XML", Icons.code, Colors.orange.shade900),
              ],
            ),
          ),
          const SizedBox(height: 30),
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
          const SizedBox(height: 20),
          _actionButton(
            onPressed: _periodoPrincipal == null ? null : () => _reportController.gerarRelatorioIncidencias(context, periodo: _periodoPrincipal!),
            label: "MAPA DE INCIDÊNCIAS CRÍTICAS",
            icon: Icons.analytics_outlined,
            color: Colors.deepOrange.shade900,
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
      backgroundColor: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade200,
      checkmarkColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: selected ? (color ?? Colors.indigo) : (isDark ? Colors.white38 : Colors.grey.shade400),
          width: 1,
        ),
      ),
    );
  }

  Widget _formatChip(String label, IconData icon, Color activeColor) {
    final isSelected = _formatoSelecionado == label;
    return ChoiceChip(
      label: Text(label),
      avatar: Icon(icon, size: 16, color: isSelected ? Colors.white : activeColor),
      selected: isSelected,
      onSelected: (v) => setState(() => _formatoSelecionado = label),
      selectedColor: activeColor,
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
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
