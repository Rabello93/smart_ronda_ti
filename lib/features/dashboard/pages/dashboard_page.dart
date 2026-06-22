import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_ronda_ti/core/services/auth/auth_service.dart';
import 'package:smart_ronda_ti/core/services/admin/admin_service.dart';
import 'package:smart_ronda_ti/core/services/rounds/ronda_service.dart';
import 'package:smart_ronda_ti/core/services/inventory/inventory_service.dart';
import 'package:smart_ronda_ti/core/models/ronda_model.dart';
import 'package:smart_ronda_ti/core/models/ativo_model.dart';

class DashboardPage extends StatefulWidget {
  final ThemeMode themeMode;
  final Function(ThemeMode) onChangeTheme;

  const DashboardPage({super.key, required this.themeMode, required this.onChangeTheme});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final AdminService _adminService = AdminService();
  final RondaService _rondaService = RondaService();
  final InventoryService _inventoryService = InventoryService();
  final AuthService _authService = AuthService();

  String? setorFiltro;
  String? locadoraFiltro;
  String tipoAtivoFiltro = "Todos";
  DateTimeRange? dataFiltro;

  @override
  Widget build(BuildContext context) {
    final bool isDark = widget.themeMode == ThemeMode.dark;
    final bgColor = isDark ? Colors.grey.shade900 : Colors.grey.shade100;
    final cardColor = isDark ? Colors.black87 : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: StreamBuilder<DocumentSnapshot>(
          stream: _adminService.getConfigEmpresa(),
          builder: (context, snapshot) {
            String nomeEmpresa = "RONDA TI CORPORATIVA";
            String logoUrl = "";
            if (snapshot.hasData && snapshot.data!.exists) {
              final data = snapshot.data!.data() as Map<String, dynamic>;
              nomeEmpresa = data['nome'] ?? nomeEmpresa;
              logoUrl = data['logo_url'] ?? "";
            }

            if (logoUrl.contains("drive.google.com")) {
              final fileId = RegExp(r"d/(.+)/").firstMatch(logoUrl)?.group(1) ?? RegExp(r"id=(.+)").firstMatch(logoUrl)?.group(1);
              if (fileId != null) logoUrl = "https://docs.google.com/uc?export=download&id=$fileId";
            }

            return Row(
              children: [
                if (logoUrl.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Image.network(logoUrl, height: 30, errorBuilder: (_, __, ___) => Image.asset("assets/logo.png", height: 30)),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Image.asset("assets/logo.png", height: 30, errorBuilder: (_, __, ___) => const Icon(Icons.business, size: 20)),
                  ),
                Expanded(child: Text(nomeEmpresa, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
              ],
            );
          }
        ),
        backgroundColor: isDark ? Colors.black : Colors.indigo.shade900,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            tooltip: isDark ? "Tema Claro" : "Tema Escuro",
            onPressed: () => widget.onChangeTheme(isDark ? ThemeMode.light : ThemeMode.dark),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _authService.logout(),
          ),
        ],
      ),
      body: StreamBuilder<List<RondaModel>>(
        stream: _rondaService.getHistoricoRondas(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          
          List<RondaModel> rondas = snapshot.data ?? [];
          
          if (dataFiltro != null) {
            rondas = rondas.where((r) {
              return r.dataInicio.isAfter(dataFiltro!.start) && r.dataInicio.isBefore(dataFiltro!.end.add(const Duration(days: 1)));
            }).toList();
          }

          return DefaultTabController(
            length: 4,
            child: Column(
              children: [
                Container(
                  color: isDark ? Colors.black87 : Colors.white,
                  child: const TabBar(
                    labelColor: Colors.blue,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Colors.blue,
                    tabs: [
                      Tab(icon: Icon(Icons.dashboard), text: "Geral"),
                      Tab(icon: Icon(Icons.warning_amber), text: "Defeitos"),
                      Tab(icon: Icon(Icons.business), text: "Locação"),
                      Tab(icon: Icon(Icons.analytics), text: "Status"),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildGeralTab(rondas, cardColor, textColor),
                      _buildDefeitosTab(context, rondas, cardColor, textColor),
                      _buildLocacaoTab(cardColor, textColor),
                      _buildStatusTab(cardColor, textColor),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Center(child: Text('Smart Ronda TI - Versão 3.0.0', style: TextStyle(color: textColor.withAlpha(120), fontSize: 10))),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGeralTab(List<RondaModel> rondas, Color cardColor, Color textColor) {
    int totalItens = rondas.fold(0, (accumulator, r) => accumulator + r.itensTotal);
    int totalDefeitos = rondas.fold(0, (accumulator, r) => accumulator + r.defeitosTotal);
    
    Map<String, int> rondasPorSetor = {};
    for (var r in rondas) {
      String s = r.setor;
      rondasPorSetor[s] = (rondasPorSetor[s] ?? 0) + 1;
    }

    var sortedSetores = rondasPorSetor.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final topSetores = sortedSetores.take(5).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildFiltroData(),
          const SizedBox(height: 20),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: [
              _buildSummaryCard("RONDAS", rondas.length.toString(), Icons.assignment_turned_in, Colors.blue, cardColor, textColor),
              _buildSummaryCard("TOTAL ITENS", totalItens.toString(), Icons.inventory_2, Colors.orange, cardColor, textColor),
              _buildSummaryCard("DEFEITOS", totalDefeitos.toString(), Icons.error, Colors.red, cardColor, textColor),
              StreamBuilder<List<AtivoModel>>(
                stream: _inventoryService.getItensObsoletos(),
                builder: (context, snapshot) {
                  final count = snapshot.data?.length ?? 0;
                  return Tooltip(message: "Equipamentos com mais de 5 anos", child: _buildSummaryCard("OBSOLETOS", count.toString(), Icons.history, Colors.deepPurple, cardColor, textColor));
                }
              ),
            ],
          ),
          const SizedBox(height: 30),
          _buildSectionTitle("Ranking de Atividade por Setor", textColor),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 10)]),
            child: Column(
              children: topSetores.map((e) {
                double pct = sortedSetores.isNotEmpty && sortedSetores.first.value > 0 ? e.value / sortedSetores.first.value : 0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(e.key, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                          Text("${e.value} rondas", style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 5),
                      LinearProgressIndicator(
                        value: pct,
                        backgroundColor: Colors.grey.withAlpha(30),
                        color: Colors.blue.shade400,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color, Color cardColor, Color textColor) {
    if (title == "VALOR TOTAL") return const SizedBox.shrink();
    return Container(
      width: 160,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withAlpha(50), width: 2),
        boxShadow: [BoxShadow(color: color.withAlpha(10), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
          Text(title, style: TextStyle(fontSize: 10, color: textColor.withAlpha(150), fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildFiltroData() {
    return ActionChip(
      avatar: const Icon(Icons.calendar_today, size: 16),
      label: Text(dataFiltro == null ? "Filtrar por Período" : "${DateFormat('dd/MM').format(dataFiltro!.start)} - ${DateFormat('dd/MM').format(dataFiltro!.end)}"),
      onPressed: () async {
        final picked = await showDateRangePicker(context: context, firstDate: DateTime(2024), lastDate: DateTime.now().add(const Duration(days: 365)));
        if (picked != null) setState(() => dataFiltro = picked);
      },
    );
  }

  Widget _buildSectionTitle(String title, Color textColor) {
    return Row(
      children: [
        Container(width: 4, height: 20, color: Colors.blue, margin: const EdgeInsets.only(right: 10)),
        Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
      ],
    );
  }

  Widget _buildDefeitosTab(BuildContext context, List<RondaModel> rondas, Color cardColor, Color textColor) {
    return StreamBuilder<List<AtivoModel>>(
      stream: _inventoryService.getItensComDefeito(),
      builder: (context, snapshot) {
        final itens = snapshot.data ?? [];
        if (itens.isEmpty) return const Center(child: Text("Nenhum item com defeito no momento."));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: itens.length,
          itemBuilder: (context, index) {
            final item = itens[index];
            return Card(
              color: cardColor,
              child: ListTile(
                leading: const Icon(Icons.error_outline, color: Colors.red),
                title: Text("${item.tipo} - Pat: ${item.patrimonio}"),
                subtitle: Text("Setor: ${item.setor}\nDefeito: ${item.descricaoDefeito ?? 'Não informado'}"),
                trailing: const Icon(Icons.chevron_right),
              ),
            );
          },
        );
      }
    );
  }

  Widget _buildLocacaoTab(Color cardColor, Color textColor) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('inventario_mestre').where('is_locado', isEqualTo: true).snapshots().map((snap) => snap.docs.map((doc) => doc.data()).toList()),
      builder: (context, snapshot) {
        final itens = snapshot.data ?? [];
        if (itens.isEmpty) return const Center(child: Text("Nenhum item locado encontrado."));

        // Agrupar por locadora
        Map<String, List<Map<String, dynamic>>> porLocadora = {};
        for (var i in itens) {
          String loc = i['locadora'] ?? "Não inf.";
          if (!porLocadora.containsKey(loc)) porLocadora[loc] = [];
          porLocadora[loc]!.add(i);
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionTitle("Gestão de Locados", textColor),
            const SizedBox(height: 15),
            ...porLocadora.entries.map((entry) {
              return Card(
                color: cardColor,
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ExpansionTile(
                  leading: const CircleAvatar(child: Icon(Icons.business)),
                  title: Text(entry.key.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${entry.value.length} equipamentos"),
                  children: _buildLocacaoTipos(entry.value, cardColor, textColor),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  List<Widget> _buildLocacaoTipos(List<Map<String, dynamic>> itens, Color cardColor, Color textColor) {
    // Agrupar itens daquela locadora por tipo
    Map<String, List<Map<String, dynamic>>> porTipo = {};
    for (var i in itens) {
      String tipo = i['tipo'] ?? "Outros";
      if (!porTipo.containsKey(tipo)) porTipo[tipo] = [];
      porTipo[tipo]!.add(i);
    }

    return porTipo.entries.map((e) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ExpansionTile(
          title: Text(e.key, style: const TextStyle(fontSize: 14)),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.blue.shade100, borderRadius: BorderRadius.circular(10)),
            child: Text("${e.value.length}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 12)),
          ),
          children: e.value.map((item) => ListTile(
            dense: true,
            title: Text("Pat: ${item['patrimonio'] ?? 'S/P'}", style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("Setor: ${item['setor'] ?? '---'} | Status: ${item['status_operacional'] ?? 'Em uso'}"),
          )).toList(),
        ),
      );
    }).toList();
  }

  Widget _buildStatusTab(Color cardColor, Color textColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSectionTitle("Indicadores de Saúde do Parque", textColor),
          const SizedBox(height: 20),
          StreamBuilder<List<AtivoModel>>(
            stream: _inventoryService.getItensEmManutencao(),
            builder: (context, snapshot) {
              final itens = snapshot.data ?? [];
              return _buildStatusCard("EM MANUTENÇÃO", itens.length.toString(), Icons.build, Colors.orange, cardColor, textColor, () => _showItensList(context, "Itens em Manutenção", itens));
            }
          ),
          const SizedBox(height: 10),
          StreamBuilder<List<AtivoModel>>(
            stream: _inventoryService.getItensDivergentes(),
            builder: (context, snapshot) {
              final itens = snapshot.data ?? [];
              return _buildStatusCard("DIVERGÊNCIAS DE SETOR", itens.length.toString(), Icons.location_off, Colors.purple, cardColor, textColor, () => _showItensList(context, "Ativos em Setor Divergente", itens));
            }
          ),
          const SizedBox(height: 10),
          StreamBuilder<List<AtivoModel>>(
            stream: _inventoryService.getItensObsoletos(),
            builder: (context, snapshot) {
              final itens = snapshot.data ?? [];
              return _buildStatusCard("CICLO DE VIDA CRÍTICO", itens.length.toString(), Icons.timer_3, Colors.deepPurple, cardColor, textColor, () => _showItensList(context, "Ativos Obsoletos (+5 anos)", itens));
            }
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(String title, String count, IconData icon, Color color, Color cardColor, Color textColor, VoidCallback onTap) {
    return Card(
      color: cardColor,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: color, size: 30),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
          child: Text(count, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  void _showItensList(BuildContext context, String title, List<AtivoModel> itens) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 500,
          child: itens.isEmpty ? const Text("Nenhum item encontrado.") : ListView.builder(
            shrinkWrap: true,
            itemCount: itens.length,
            itemBuilder: (context, index) {
              final item = itens[index];
              
              String subtitulo = "Setor Atual: ${item.setor}";
              if (item.setorDivergente) {
                subtitulo += "\nMotivo/Origem: ${item.motivoDivergencia ?? 'Não inf.'}";
              }
              if (item.statusOperacional == 'Em manutenção') {
                subtitulo += "\nDefeito: ${item.descricaoDefeito ?? 'Não inf.'}";
              }

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  title: Text("${item.tipo} - Pat: ${item.patrimonio}", style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(subtitulo, style: const TextStyle(fontSize: 12)),
                ),
              );
            },
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Fechar"))],
      ),
    );
  }
}
