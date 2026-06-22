import 'package:flutter/material.dart';
import 'package:smart_ronda_ti/core/services/auth/auth_service.dart';
import 'package:smart_ronda_ti/core/services/rounds/ronda_service.dart';
import 'package:smart_ronda_ti/core/services/admin/admin_service.dart';
import 'package:smart_ronda_ti/core/models/ronda_model.dart';
import 'package:smart_ronda_ti/core/models/usuario_model.dart';
import 'package:smart_ronda_ti/features/history/pages/ronda_details_page.dart';
import 'package:smart_ronda_ti/features/rounds/pages/ronda_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final AuthService _authService = AuthService();
  final RondaService _rondaService = RondaService();
  final AdminService _adminService = AdminService();
  
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
        await _rondaService.excluirRonda(docId);
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

  Future<void> _abrirEdicao(RondaModel ronda) async {
    if (ronda.id == null) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final equipamentos = await _rondaService.getEquipamentosDaRonda(ronda.id!);
      
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
    return StreamBuilder<UsuarioModel?>(
      stream: _authService.getPerfilStream(),
      builder: (context, profileSnapshot) {
        final userData = profileSnapshot.data;
        final String meuUid = _authService.currentUser?.uid ?? "";
        final bool isManager = userData?.isAdmin ?? false;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Histórico de Rondas'),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(110),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Buscar por Técnico...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onChanged: (v) => setState(() => filtroTexto = v.toLowerCase()),
                    ),
                    const SizedBox(height: 8),
                    StreamBuilder<List<Map<String, dynamic>>>(
                      stream: _adminService.getSetores(),
                      builder: (context, snap) {
                        final setores = snap.data ?? [];
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              ChoiceChip(label: const Text("Todas Datas"), selected: dataFiltro == null, onSelected: (s) => setState(() => dataFiltro = null)),
                              const SizedBox(width: 8),
                              ChoiceChip(label: Text(dataFiltro == null ? "Filtrar por Data" : "${dataFiltro!.day}/${dataFiltro!.month}/${dataFiltro!.year}"), selected: dataFiltro != null, onSelected: (s) => _selecionarData(context)),
                              const VerticalDivider(),
                              ChoiceChip(label: const Text("Todos Setores"), selected: setorFiltro == null, onSelected: (s) => setState(() => setorFiltro = null)),
                              ...setores.map((s) => Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: ChoiceChip(label: Text(s['nome']), selected: setorFiltro == s['nome'], onSelected: (val) => setState(() => setorFiltro = val ? s['nome'] : null)),
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
          body: StreamBuilder<List<RondaModel>>(
            stream: _rondaService.getHistoricoRondas(),
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
              if (rondas.isEmpty) return const Center(child: Text('Nenhuma ronda encontrada.'));

              return ListView.builder(
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

                  final dataStr = "${r.dataInicio.day}/${r.dataInicio.month}/${r.dataInicio.year} ${r.dataInicio.hour}:${r.dataInicio.minute}";

                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      leading: CircleAvatar(backgroundColor: Colors.blue.shade100, child: const Icon(Icons.assignment, color: Colors.blue)),
                      title: Text(r.setor, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Técnico: ${r.tecnico}'),
                          Text('Data: $dataStr'),
                        ],
                      ),
                      trailing: podeGerenciar 
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_note, color: Colors.blue),
                                onPressed: () => _abrirEdicao(r),
                                tooltip: 'Editar',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_forever, color: Colors.red),
                                onPressed: () => _excluirRonda(r.id!),
                                tooltip: 'Excluir',
                              ),
                            ],
                          )
                        : const Icon(Icons.chevron_right),
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
}
