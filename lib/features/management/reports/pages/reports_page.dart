import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_ronda_ti/app/theme.dart';
import 'package:smart_ronda_ti/features/system/auth/controllers/auth_controller.dart';
import 'package:smart_ronda_ti/features/management/reports/controllers/report_controller.dart';
import 'package:smart_ronda_ti/features/management/admin/controllers/admin_controller.dart';
import 'package:intl/intl.dart';
import 'package:smart_ronda_ti/features/system/auth/models/user_model.dart';

class ReportsPage extends StatefulWidget {
  final bool embed;
  const ReportsPage({super.key, this.embed = false});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  final AdminController _adminController = AdminController();
  final ReportController _reportController = ReportController();
  final AuthController _authController = AuthController();
  

  @override
  void initState() {
    super.initState();
  }


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
  bool _apenasSubstituicoes = false;
  bool _apenasBaixas = false;
  bool _gerandoInventario = false;

  // Filtros Performance
  DateTimeRange? _periodoPrincipal;
  DateTimeRange? _periodoComparativo;

  Future<void> _handleGerarInventario() async {
    setState(() => _gerandoInventario = true);
    
    final UserModel? profile = await _authController.profileStream.first;
    final String currentUserName = profile?.nome ?? 
                                   _authController.currentUser?.displayName ?? 
                                   _authController.currentUser?.email?.split('@')[0] ?? "Admin";

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
      apenasSubstituicoes: _apenasSubstituicoes,
      apenasBaixas: _apenasBaixas,
      periodo: _periodoPrincipal,
      userName: currentUserName,
      formato: _formatoSelecionado!,
    );
    if (mounted) setState(() => _gerandoInventario = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final content = SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SEÇÃO 0: PERÍODO (MESTRE)
          _sectionHeader("📅 DEFINIÇÃO DE PERÍODO", Icons.calendar_month_rounded),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.charcoal : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.electricBlue.withValues(alpha: 0.1)),
            ),
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppTheme.electricBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.date_range_rounded, color: AppTheme.electricBlue),
                  ),
                  title: const Text("Período de Análise", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: Text(
                    _periodoPrincipal == null ? "Obrigatório para Performance e Trocas" : "${DateFormat('dd/MM').format(_periodoPrincipal!.start)} até ${DateFormat('dd/MM').format(_periodoPrincipal!.end)}",
                    style: TextStyle(color: _periodoPrincipal == null ? AppTheme.ruby : Colors.grey, fontSize: 11),
                  ),
                  onTap: () async {
                    final picked = await showDateRangePicker(context: context, firstDate: DateTime(2023), lastDate: DateTime.now());
                    if (picked != null) setState(() => _periodoPrincipal = picked);
                  },
                  trailing: _periodoPrincipal != null ? IconButton(icon: const Icon(Icons.clear_rounded, size: 20), onPressed: () => setState(() => _periodoPrincipal = null)) : const Icon(Icons.chevron_right_rounded),
                ),
                if (_periodoPrincipal != null) ...[
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.purple.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.compare_arrows_rounded, color: Colors.purple),
                    ),
                    title: const Text("Comparativo (Opcional)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: Text(
                      _periodoComparativo == null ? "Toque para comparar meses" : "${DateFormat('dd/MM').format(_periodoComparativo!.start)} até ${DateFormat('dd/MM').format(_periodoComparativo!.end)}",
                      style: const TextStyle(fontSize: 11),
                    ),
                    onTap: () async {
                      final picked = await showDateRangePicker(context: context, firstDate: DateTime(2023), lastDate: DateTime.now());
                      if (picked != null) setState(() => _periodoComparativo = picked);
                    },
                    trailing: _periodoComparativo != null ? IconButton(icon: const Icon(Icons.clear_rounded, size: 20), onPressed: () => setState(() => _periodoComparativo = null)) : const Icon(Icons.chevron_right_rounded),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 32),

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
              _filterChip("📉 BAIXAS", _apenasBaixas, (v) => setState(() => _apenasBaixas = v), color: Colors.blueGrey.shade800),
              _filterChip("🔄 SUBSTITUIÇÕES", _apenasSubstituicoes, (v) => setState(() {
                _apenasSubstituicoes = v;
                if (v) {
                  _apenasDefeitos = false;
                  _apenasObsoletos = false;
                  _emManutencao = false;
                  _emDivergencia = false;
                  _reservados = false;
                  _apenasHomeOffice = false;
                  _apenasSemPatrimonio = false;
                  _apenasBaixas = false;
                }
              }), color: Colors.teal.shade800),
            ],
          ),
          const SizedBox(height: 20),
          
          if (_apenasLocados) ...[
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _adminController.leasingCompaniesStream,
              builder: (context, snapshot) {
                final locadoras = snapshot.data ?? [];
                return DropdownButtonFormField<String>(
                  initialValue: _locadoraSelecionada,
                  decoration: const InputDecoration(labelText: "Selecionar Locadora", border: OutlineInputBorder()),
                  items: [
                    const DropdownMenuItem(value: null, child: Text("Todas as Locadoras")),
                    ...locadoras.map((l) => DropdownMenuItem(value: l['nome'], child: Text(l['nome']))),
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
            onPressed: (_gerandoInventario || _periodoPrincipal == null) ? null : _handleGerarInventario,
            label: _gerandoInventario ? "GERANDO..." : "GERAR RELATÓRIO DE INVENTÁRIO",
            icon: Icons.assignment,
          ),

          const Padding(padding: EdgeInsets.symmetric(vertical: 30), child: Divider()),

          // SEÇÃO 2: PERFORMANCE
          _sectionHeader("📈 PERFORMANCE E METAS", Icons.stars),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _actionButton(
                  onPressed: _periodoPrincipal == null ? null : () async {
                    final UserModel? profile = await _authController.profileStream.first;
                    final String currentUserName = profile?.nome ?? 
                                                   _authController.currentUser?.displayName ?? 
                                                   _authController.currentUser?.email?.split('@')[0] ?? "Admin";
                    _reportController.gerarRelatorioMetas(
                      context, 
                      periodo: _periodoPrincipal, 
                      periodoComparativo: _periodoComparativo, 
                      userName: currentUserName,
                      formato: 'PDF'
                    );
                  },
                  label: "PDF METAS",
                  icon: Icons.picture_as_pdf,
                  color: Colors.red.shade900,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _actionButton(
                  onPressed: _periodoPrincipal == null ? null : () => _reportController.gerarRelatorioMetas(context, periodo: _periodoPrincipal, formato: 'XLSX'),
                  label: "XLSX METAS",
                  icon: Icons.table_chart,
                  color: Colors.green.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _actionButton(
            onPressed: _periodoPrincipal == null ? null : () => _reportController.gerarRelatorioMetas(context, periodo: _periodoPrincipal, formato: 'XML'),
            label: "XML METAS ESTRATÉGICAS",
            icon: Icons.code,
            color: Colors.blueGrey.shade800,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _actionButton(
                  onPressed: _periodoPrincipal == null ? null : () async {
                    final UserModel? profile = await _authController.profileStream.first;
                    final String currentUserName = profile?.nome ?? 
                                                   _authController.currentUser?.displayName ?? 
                                                   _authController.currentUser?.email?.split('@')[0] ?? "Admin";
                    _reportController.gerarRelatorioIncidencias(
                      context, 
                      periodo: _periodoPrincipal!, 
                      setor: _setorSelecionado,
                      locadora: _locadoraSelecionada,
                      userName: currentUserName,
                      formato: 'PDF',
                    );
                  },
                  label: "PDF INCIDÊNCIAS",
                  icon: Icons.picture_as_pdf,
                  color: Colors.red.shade900,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _actionButton(
                  onPressed: _periodoPrincipal == null ? null : () => _reportController.gerarRelatorioIncidencias(
                    context, 
                    periodo: _periodoPrincipal!, 
                    setor: _setorSelecionado,
                    locadora: _locadoraSelecionada,
                    formato: 'XLSX',
                  ),
                  label: "XLSX INCIDÊNCIAS",
                  icon: Icons.table_chart,
                  color: Colors.green.shade900,
                ),
              ),
            ],
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider()),
          _sectionHeader("🤝 AUDITORIA CONTRATUAL", Icons.handshake_rounded),
          const SizedBox(height: 20),
          _actionButton(
            onPressed: () async {
              final UserModel? profile = await _authController.profileStream.first;
              final String currentUserName = profile?.nome ?? 
                                             _authController.currentUser?.displayName ?? 
                                             _authController.currentUser?.email?.split('@')[0] ?? "Admin";
              _reportController.gerarRelatorioContratos(context, userName: currentUserName);
            },
            label: "PDF ANÁLISE DE CONTRATOS (OPEX)",
            icon: Icons.picture_as_pdf,
            color: Colors.blueGrey.shade900,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.electricBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.electricBlue, size: 18),
        ),
        const SizedBox(width: 12),
        Text(
          title, 
          style: GoogleFonts.inter(
            fontSize: 14, 
            fontWeight: FontWeight.w900, 
            letterSpacing: 1,
            color: isDark ? Colors.white : AppTheme.deepNavy,
          )
        ),
      ],
    );
  }

  Widget _filterChip(String label, bool selected, Function(bool) onSelected, {Color? color}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = color ?? AppTheme.electricBlue;
    return FilterChip(
      label: Text(label.toUpperCase(), style: TextStyle(
        fontSize: 10, 
        color: selected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      )),
      selected: selected,
      onSelected: onSelected,
      selectedColor: primaryColor,
      backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
      checkmarkColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: selected ? primaryColor : (isDark ? Colors.white12 : Colors.grey.shade300),
          width: 1,
        ),
      ),
    );
  }

  Widget _formatChip(String label, IconData icon, Color activeColor) {
    final isSelected = _formatoSelecionado == label;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ChoiceChip(
      label: Text(label),
      avatar: Icon(icon, size: 16, color: isSelected ? Colors.white : activeColor),
      selected: isSelected,
      onSelected: (v) => setState(() => _formatoSelecionado = label),
      selectedColor: activeColor,
      backgroundColor: isDark ? AppTheme.charcoal : Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87), 
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _actionButton({required VoidCallback? onPressed, required String label, required IconData icon, Color? color}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: onPressed == null ? null : LinearGradient(
          colors: [color ?? AppTheme.electricBlue, (color ?? AppTheme.electricBlue).withValues(alpha: 0.7)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (onPressed != null)
            BoxShadow(color: (color ?? AppTheme.electricBlue).withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w900, letterSpacing: 0.5)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 55),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}
