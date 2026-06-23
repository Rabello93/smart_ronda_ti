import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_ronda_ti/shared/helpers/url_helper.dart';
import 'package:smart_ronda_ti/features/system/auth/controllers/auth_controller.dart';
import 'package:smart_ronda_ti/features/management/admin/controllers/admin_controller.dart';
import 'package:smart_ronda_ti/features/operation/rounds/controllers/round_controller.dart';
import 'package:smart_ronda_ti/features/operation/assets/controllers/asset_controller.dart';
import 'package:smart_ronda_ti/features/management/dashboard/controllers/dashboard_controller.dart';
import 'package:smart_ronda_ti/shared/widgets/dashboard_widgets.dart';
import 'package:smart_ronda_ti/features/operation/rounds/models/round_model.dart';
import 'package:smart_ronda_ti/features/operation/assets/models/asset_model.dart';

class DashboardPage extends StatefulWidget {
  final ThemeMode themeMode;
  final Function(ThemeMode) onChangeTheme;

  const DashboardPage({super.key, required this.themeMode, required this.onChangeTheme});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final AdminController _adminController = AdminController();
  final RoundController _roundController = RoundController();
  final AssetController _assetController = AssetController();
  final AuthController _authController = AuthController();
  final DashboardController _dashboardController = DashboardController();

  DateTimeRange? dataFiltro;

  @override
  Widget build(BuildContext context) {
    final bool isDark = widget.themeMode == ThemeMode.dark;
    final bgColor = isDark ? Colors.grey.shade900 : Colors.grey.shade100;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: _buildCompanyLogo(),
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
            onPressed: () => _authController.logout(),
          ),
        ],
      ),
      body: StreamBuilder<List<RoundModel>>(
        stream: _roundController.getHistoryStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final allRondas = snapshot.data ?? [];
          final rondas = _dashboardController.filterRoundsByDateRange(allRondas, dataFiltro);

          return DefaultTabController(
            length: 5,
            child: Column(
              children: [
                _buildTabBar(isDark),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildGeralTab(rondas, textColor),
                      _buildTecnicosTab(rondas, textColor),
                      _buildDefeitosTab(textColor),
                      _buildLocacaoTab(textColor),
                      _buildStatusTab(textColor),
                    ],
                  ),
                ),
                _buildFooter(textColor),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCompanyLogo() {
    return StreamBuilder<DocumentSnapshot>(
      stream: _adminController.brandingStream,
      builder: (context, snapshot) {
        String logoUrl = "";
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          logoUrl = data['logo_url'] ?? "";
        }

        final displayUrl = UrlHelper.convertDriveUrl(logoUrl);

        if (displayUrl != null && displayUrl.isNotEmpty) {
          return Image.network(
            displayUrl, 
            height: 40, 
            errorBuilder: (_, __, ___) => Image.asset("assets/logo.png", height: 40),
          );
        } else {
          return Image.asset(
            "assets/logo.png", 
            height: 40, 
            errorBuilder: (_, __, ___) => const Icon(Icons.business, size: 30),
          );
        }
      }
    );
  }

  Widget _buildTabBar(bool isDark) {
    return Container(
      color: isDark ? Colors.black87 : Colors.white,
      child: const TabBar(
        labelColor: Colors.blue,
        unselectedLabelColor: Colors.grey,
        indicatorColor: Colors.blue,
        isScrollable: true,
        tabs: [
          Tab(icon: Icon(Icons.dashboard), text: "Geral"),
          Tab(icon: Icon(Icons.person), text: "Técnicos"),
          Tab(icon: Icon(Icons.warning_amber), text: "Defeitos"),
          Tab(icon: Icon(Icons.business), text: "Locação"),
          Tab(icon: Icon(Icons.analytics), text: "Status"),
        ],
      ),
    );
  }

  Widget _buildFooter(Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Text(
          'Smart Ronda TI - Versão 3.0.0', 
          style: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 10),
        ),
      ),
    );
  }

  Widget _buildGeralTab(List<RoundModel> rondas, Color textColor) {
    final rankingSetores = _dashboardController.getRankingPorSetor(rondas);
    final topSetores = rankingSetores.take(5).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildFiltroData(),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: [
              SummaryCard(
                title: "Rondas", 
                value: rondas.length.toString(), 
                icon: Icons.assignment_turned_in, 
                color: Colors.blue,
              ),
              SummaryCard(
                title: "Itens", 
                value: _dashboardController.getTotalItens(rondas).toString(), 
                icon: Icons.inventory_2, 
                color: Colors.orange,
              ),
              SummaryCard(
                title: "Defeitos", 
                value: _dashboardController.getTotalDefeitos(rondas).toString(), 
                icon: Icons.error, 
                color: Colors.red,
              ),
              StreamBuilder<List<AssetModel>>(
                stream: _assetController.getObsoleteStream(),
                builder: (context, snapshot) {
                  final count = snapshot.data?.length ?? 0;
                  return SummaryCard(
                    title: "Obsoletos", 
                    value: count.toString(), 
                    icon: Icons.history, 
                    color: Colors.deepPurple,
                  );
                }
              ),
            ],
          ),
          const SizedBox(height: 32),
          const SectionTitle(title: "Atividade por Setor"),
          const SizedBox(height: 16),
          _buildRankingCard(
            topSetores, 
            rankingSetores.isNotEmpty ? rankingSetores.first.value : 0,
            Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildTecnicosTab(List<RoundModel> rondas, Color textColor) {
    final rankingTecnicos = _dashboardController.getRankingPorTecnico(rondas);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildFiltroData(),
          const SizedBox(height: 24),
          const SectionTitle(title: "Rondas por Técnico", color: Colors.green),
          const SizedBox(height: 16),
          _buildRankingCard(
            rankingTecnicos, 
            rankingTecnicos.isNotEmpty ? rankingTecnicos.first.value : 0,
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildRankingCard(List<MapEntry<String, int>> data, int maxValue, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.black54 : Colors.white, 
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
        ],
      ),
      child: data.isEmpty 
        ? const Center(child: Text("Nenhum dado disponível para o período."))
        : Column(
            children: data.map((e) {
              return RankingItem(
                label: e.key, 
                count: e.value, 
                progress: maxValue > 0 ? e.value / maxValue : 0, 
                color: color,
              );
            }).toList(),
          ),
    );
  }

  Widget _buildDefeitosTab(Color textColor) {
    return StreamBuilder<List<AssetModel>>(
      stream: _assetController.getDefectsStream(),
      builder: (context, snapshot) {
        final itens = snapshot.data ?? [];
        if (itens.isEmpty) {
          return const Center(child: Text("Nenhum item com defeito no momento."));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: itens.length,
          itemBuilder: (context, index) {
            final item = itens[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.redAccent,
                  child: Icon(Icons.warning_amber_rounded, color: Colors.white),
                ),
                title: Text("${item.tipo} - Pat: ${item.patrimonio}", style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Setor: ${item.setor}\nDefeito: ${item.descricaoDefeito ?? 'Não informado'}"),
                isThreeLine: true,
              ),
            );
          },
        );
      }
    );
  }

  Widget _buildLocacaoTab(Color textColor) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('inventario_mestre')
          .where('is_locado', isEqualTo: true)
          .snapshots()
          .map((snap) => snap.docs.map((doc) => doc.data() as Map<String, dynamic>).toList()),
      builder: (context, snapshot) {
        final itens = snapshot.data ?? [];
        if (itens.isEmpty) return const Center(child: Text("Nenhum item locado encontrado."));

        Map<String, List<Map<String, dynamic>>> porLocadora = {};
        for (var i in itens) {
          String loc = i['locadora'] ?? "Não inf.";
          porLocadora.putIfAbsent(loc, () => []).add(i);
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SectionTitle(title: "Gestão de Ativos Locados"),
            const SizedBox(height: 16),
            ...porLocadora.entries.map((entry) {
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ExpansionTile(
                  leading: const CircleAvatar(child: Icon(Icons.business_center)),
                  title: Text(entry.key.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${entry.value.length} equipamentos"),
                  children: _buildLocacaoTipos(entry.value),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  List<Widget> _buildLocacaoTipos(List<Map<String, dynamic>> itens) {
    Map<String, List<Map<String, dynamic>>> porTipo = {};
    for (var i in itens) {
      String tipo = i['tipo'] ?? "Outros";
      porTipo.putIfAbsent(tipo, () => []).add(i);
    }

    return porTipo.entries.map((e) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ExpansionTile(
          title: Text(e.key, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          trailing: Chip(
            label: Text("${e.value.length}", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue)),
            backgroundColor: Colors.blue.withValues(alpha: 0.1),
            padding: EdgeInsets.zero,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          children: e.value.map((item) {
            final String pat = item['patrimonio'] ?? item['id'] ?? 'S/P';
            return ListTile(
              dense: true,
              title: Text("Pat: $pat", style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("Setor: ${item['setor'] ?? '---'} | Status: ${item['status_operacional'] ?? 'Em uso'}"),
            );
          }).toList(),
        ),
      );
    }).toList();
  }

  Widget _buildStatusTab(Color textColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SectionTitle(title: "Saúde do Parque Tecnológico"),
          const SizedBox(height: 20),
          StreamBuilder<List<AssetModel>>(
            stream: _assetController.getMaintenanceStream(),
            builder: (context, snapshot) {
              final count = snapshot.data?.length ?? 0;
              return StatusIndicatorCard(
                title: "EM MANUTENÇÃO", 
                count: count.toString(), 
                icon: Icons.build_circle_outlined, 
                color: Colors.orange, 
                onTap: () => _showItensList(context, "Itens em Manutenção", snapshot.data ?? []),
              );
            }
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<AssetModel>>(
            stream: _assetController.getDivergenceStream(),
            builder: (context, snapshot) {
              final count = snapshot.data?.length ?? 0;
              return StatusIndicatorCard(
                title: "DIVERGÊNCIAS DE SETOR", 
                count: count.toString(), 
                icon: Icons.wrong_location_outlined, 
                color: Colors.purple, 
                onTap: () => _showItensList(context, "Ativos em Setor Divergente", snapshot.data ?? []),
              );
            }
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<AssetModel>>(
            stream: _assetController.getObsoleteStream(),
            builder: (context, snapshot) {
              final count = snapshot.data?.length ?? 0;
              return StatusIndicatorCard(
                title: "CICLO DE VIDA CRÍTICO", 
                count: count.toString(), 
                icon: Icons.timer_outlined, 
                color: Colors.deepPurple, 
                onTap: () => _showItensList(context, "Ativos Obsoletos (+5 anos)", snapshot.data ?? []),
              );
            }
          ),
        ],
      ),
    );
  }

  Widget _buildFiltroData() {
    return ActionChip(
      avatar: const Icon(Icons.calendar_today_rounded, size: 16),
      label: Text(dataFiltro == null 
        ? "Filtrar por Período" 
        : "${DateFormat('dd/MM/yy').format(dataFiltro!.start)} - ${DateFormat('dd/MM/yy').format(dataFiltro!.end)}"),
      onPressed: () async {
        final picked = await showDateRangePicker(
          context: context, 
          firstDate: DateTime(2024), 
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) setState(() => dataFiltro = picked);
      },
    );
  }

  void _showItensList(BuildContext context, String title, List<AssetModel> itens) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 500,
          child: itens.isEmpty 
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text("Nenhum item encontrado.", textAlign: TextAlign.center),
              ) 
            : ListView.builder(
                shrinkWrap: true,
                itemCount: itens.length,
                itemBuilder: (context, index) {
                  final item = itens[index];
                  String subtitulo = "Setor: ${item.setor}";
                  if (item.setorDivergente) {
                    subtitulo += "\nOrigem: ${item.motivoDivergencia ?? 'Não inf.'}";
                  }
                  if (item.statusOperacional == 'Em manutenção') {
                    subtitulo += "\nDefeito: ${item.descricaoDefeito ?? 'Não inf.'}";
                  }

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      title: Text("${item.tipo} - Pat: ${item.patrimonio}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: Text(subtitulo, style: const TextStyle(fontSize: 11)),
                    ),
                  );
                },
              ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text("Fechar"),
          )
        ],
      ),
    );
  }
}
