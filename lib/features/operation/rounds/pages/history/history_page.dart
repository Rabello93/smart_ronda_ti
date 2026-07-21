import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_ronda_ti/app/theme.dart';
import 'package:smart_ronda_ti/features/system/auth/controllers/auth_controller.dart';
import 'package:smart_ronda_ti/features/operation/rounds/controllers/round_controller.dart';
import 'package:smart_ronda_ti/features/management/admin/controllers/admin_controller.dart';
import 'package:smart_ronda_ti/features/operation/rounds/models/round_model.dart';
import 'package:smart_ronda_ti/features/system/auth/models/user_model.dart';
import 'package:smart_ronda_ti/features/operation/rounds/pages/history/ronda_details_page.dart';
import 'package:smart_ronda_ti/features/operation/rounds/pages/ronda_page.dart';

import 'package:smart_ronda_ti/features/management/reports/repositories/report_repository.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final AuthController _authController = AuthController();
  final RoundController _roundController = RoundController();
  final AdminController _adminController = AdminController();
  
  String filtroTexto = "";
  String? setorFiltro;
  DateTime? dataFiltro;

  Future<void> _selecionarData(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: dataFiltro ?? DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => dataFiltro = picked);
  }

  Future<void> _excluirRonda(String docId) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Registro'),
        content: const Text('Tem certeza que deseja excluir esta ronda?\nEsta ação não pode ser desfeita.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Excluir', style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await _roundController.removeRound(docId);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ronda excluída com sucesso'), duration: Duration(seconds: 1))
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _abrirEdicao(RoundModel ronda) async {
    if (ronda.id == null) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final equipamentos = await _roundController.getRoundAssets(ronda.id!);
      
      if (!mounted) return;
      Navigator.pop(context); 

      Navigator.push(context, MaterialPageRoute(
        builder: (_) => RondaPage(
          setor: ronda.setor,
          tecnico: ronda.tecnico,
          tecnicoId: ronda.tecnicoId,
          rondaId: ronda.id, 
          equipamentosIniciais: equipamentos,
        ),
      ));
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro ao carregar dados: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<UserModel?>(
      stream: _authController.profileStream,
      builder: (context, profileSnapshot) {
        final userData = profileSnapshot.data;
        final String meuUid = _authController.currentUser?.uid ?? "";
        final bool isManager = userData?.nivelAcesso == 'master' || userData?.nivelAcesso == 'gerente';

        return Scaffold(
          backgroundColor: isDark ? AppTheme.deepNavy : AppTheme.coolGrey,
          appBar: AppBar(
            title: Text('HISTÓRICO DE RONDAS', style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1)),
            backgroundColor: isDark ? AppTheme.deepNavy : Colors.white,
            elevation: 0,
            actions: [
              if (isManager) ...[
                IconButton(
                  icon: const Icon(Icons.picture_as_pdf_rounded, size: 20),
                  onPressed: () => ReportRepository.exportarRondasParaPDF(
                    setor: setorFiltro,
                    context: context,
                  ),
                  tooltip: "Exportar PDF",
                ),
                IconButton(
                  icon: const Icon(Icons.code_rounded, size: 20),
                  onPressed: () => ReportRepository.exportarRondasParaXML(
                    setor: setorFiltro,
                    context: context,
                  ),
                  tooltip: "Exportar XML",
                ),
                const SizedBox(width: 8),
              ]
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(130),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'BUSCAR POR TÉCNICO...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        filled: true,
                        fillColor: isDark ? AppTheme.charcoal : Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (v) => setState(() => filtroTexto = v.toLowerCase()),
                    ),
                    const SizedBox(height: 12),
                    StreamBuilder<List<Map<String, dynamic>>>(
                      stream: _adminController.sectorsStream,
                      builder: (context, snap) {
                        final setores = snap.data ?? [];
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              ChoiceChip(
                                label: const Text("HOJE"), 
                                selected: dataFiltro != null && dataFiltro!.day == DateTime.now().day, 
                                onSelected: (s) => setState(() => dataFiltro = s ? DateTime.now() : null)
                              ),
                              const SizedBox(width: 8),
                              ChoiceChip(
                                label: Text(dataFiltro == null ? "CALENDÁRIO" : DateFormat('dd/MM/yy').format(dataFiltro!)), 
                                selected: dataFiltro != null, 
                                onSelected: (s) => _selecionarData(context)
                              ),
                              const VerticalDivider(),
                              ChoiceChip(
                                label: const Text("TODOS SETORES"), 
                                selected: setorFiltro == null, 
                                onSelected: (s) => setState(() => setorFiltro = null)
                              ),
                              ...setores.map((s) => Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: ChoiceChip(
                                  label: Text(s['nome'].toString().toUpperCase()), 
                                  selected: setorFiltro == s['nome'], 
                                  onSelected: (val) => setState(() => setorFiltro = val ? s['nome'] : null)
                                ),
                              )),
                            ],
                          ),
                        );
                      }
                    ),
                  ],
                ),
              ),
            ),
          ),
          body: StreamBuilder<List<RoundModel>>(
            stream: _roundController.getHistoryStream(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return Center(child: Text('Erro: ${snapshot.error}'));
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              var rondas = snapshot.data!;
              if (filtroTexto.isNotEmpty) rondas = rondas.where((r) => r.tecnico.toLowerCase().contains(filtroTexto)).toList();
              if (setorFiltro != null) rondas = rondas.where((r) => r.setor == setorFiltro).toList();
              if (dataFiltro != null) {
                rondas = rondas.where((r) {
                  return r.dataInicio.year == dataFiltro!.year && r.dataInicio.month == dataFiltro!.month && r.dataInicio.day == dataFiltro!.day;
                }).toList();
              }
              if (rondas.isEmpty) return const Center(child: Text('Nenhuma atividade encontrada no período.'));

              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: rondas.length,
                itemBuilder: (context, index) {
                  final r = rondas[index];
                  
                  bool podeGerenciar = false;
                  if (isManager) {
                    podeGerenciar = true;
                  } else if (meuUid == r.tecnicoId) {
                    final agora = DateTime.now();
                    if (r.dataInicio.year == agora.year && 
                        r.dataInicio.month == agora.month && 
                        r.dataInicio.day == agora.day) {
                      podeGerenciar = true;
                    }
                  }

                  final dataStr = DateFormat('dd/MM HH:mm').format(r.dataInicio);

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.charcoal : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.electricBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.assignment_rounded, color: AppTheme.electricBlue),
                      ),
                      title: Text(
                        r.setor.toUpperCase(), 
                        style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 14)
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            'OPERAÇÃO: ${r.tecnico.toUpperCase()}',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.schedule_rounded, size: 12, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                dataStr,
                                style: AppTheme.monoStyle(fontSize: 10, color: Colors.grey),
                              ),
                              const Spacer(),
                              _badge("${r.itensTotal} ITENS", Colors.blue),
                              if (r.defeitosTotal > 0) ...[
                                const SizedBox(width: 4),
                                _badge("${r.defeitosTotal} ERROS", AppTheme.ruby),
                              ],
                            ],
                          ),
                        ],
                      ),
                      trailing: podeGerenciar 
                        ? IconButton(
                            icon: const Icon(Icons.more_vert_rounded),
                            onPressed: () => _showRondaMenu(context, r),
                          )
                        : const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RondaDetailsPage(ronda: {
                        'id_documento': r.id,
                        'setor': r.setor,
                        'tecnico': r.tecnico,
                        'data_inicio': r.dataInicio.toIso8601String(),
                        'itens_total': r.itensTotal,
                        'defeitos_total': r.defeitosTotal,
                        'trocas_total': r.trocasTotal,
                      }))),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900),
      ),
    );
  }

  void _showRondaMenu(BuildContext context, RoundModel r) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit_note_rounded, color: Colors.blue),
            title: const Text("Editar Registro"),
            onTap: () {
              Navigator.pop(ctx);
              _abrirEdicao(r);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever_rounded, color: AppTheme.ruby),
            title: const Text("Excluir Permanentemente"),
            onTap: () {
              Navigator.pop(ctx);
              _excluirRonda(r.id!);
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
