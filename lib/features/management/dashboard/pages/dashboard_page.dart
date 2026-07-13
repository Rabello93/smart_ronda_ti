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
import 'package:smart_ronda_ti/features/system/auth/models/user_model.dart';
import 'package:smart_ronda_ti/features/system/about/pages/about_page.dart';

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
  int _selectedIndex = 0;
  bool _isRailExpanded = false;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.grey.shade900 : Colors.grey.shade100;
    final textColor = isDark ? Colors.white : Colors.black87;
    final bool isMobile = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        toolbarHeight: isMobile ? 80 : 125,
        leading: isMobile 
          ? Builder(builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ))
          : IconButton(
              icon: Icon(_isRailExpanded ? Icons.menu_open : Icons.menu),
              onPressed: () => setState(() => _isRailExpanded = !_isRailExpanded),
            ),
        title: _buildCompanyLogo(isMobile),
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
      drawer: isMobile ? Drawer(
        child: Container(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          child: Column(
            children: [
              DrawerHeader(
                decoration: BoxDecoration(color: isDark ? Colors.black : Colors.indigo.shade900),
                child: Center(child: _buildCompanyLogo(true)),
              ),
              _buildDrawerItem(0, Icons.dashboard, "Geral", isDark),
              _buildDrawerItem(1, Icons.stars, "Metas", isDark),
              _buildDrawerItem(2, Icons.person, "Técnicos", isDark),
              _buildDrawerItem(3, Icons.warning_amber, "Defeitos", isDark),
              _buildDrawerItem(4, Icons.business, "Ativos", isDark),
              _buildDrawerItem(5, Icons.location_on, "Departamentos", isDark),
              _buildDrawerItem(6, Icons.analytics, "Status", isDark),
              const Spacer(),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text("Sobre o Sistema"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutPage()));
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ) : null,
      body: StreamBuilder<UserModel?>(
        stream: _authController.profileStream,
        builder: (context, userSnapshot) {
          final user = userSnapshot.data;
          
          return StreamBuilder<List<RoundModel>>(
            stream: _roundController.getHistoryStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              final allRondas = snapshot.data ?? [];
              final rondas = _dashboardController.filterRoundsByDateRange(allRondas, dataFiltro);

              return Row(
                children: [
                  if (!isMobile) ...[
                    _buildSideNavigation(isDark),
                    const VerticalDivider(thickness: 1, width: 1),
                  ],
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          child: _buildCurrentTab(rondas, allRondas, textColor, user),
                        ),
                        _buildFooter(textColor),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        }
      ),
    );
  }

  Widget _buildDrawerItem(int index, IconData icon, String label, bool isDark) {
    final isSelected = _selectedIndex == index;
    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.blue : (isDark ? Colors.white54 : Colors.grey)),
      title: Text(label, style: TextStyle(
        color: isSelected ? Colors.blue : (isDark ? Colors.white : Colors.black87),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      )),
      selected: isSelected,
      onTap: () {
        setState(() => _selectedIndex = index);
        Navigator.pop(context);
      },
    );
  }

  Widget _buildSideNavigation(bool isDark) {
    return NavigationRail(
      extended: _isRailExpanded,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) => setState(() => _selectedIndex = index),
      labelType: _isRailExpanded ? NavigationRailLabelType.none : NavigationRailLabelType.selected,
      unselectedIconTheme: IconThemeData(color: isDark ? Colors.white54 : Colors.grey.shade600),
      selectedIconTheme: const IconThemeData(color: Colors.blue),
      selectedLabelTextStyle: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12),
      unselectedLabelTextStyle: TextStyle(color: isDark ? Colors.white54 : Colors.grey.shade600, fontSize: 11),
      destinations: const [
        NavigationRailDestination(icon: Icon(Icons.dashboard), label: Text("Geral")),
        NavigationRailDestination(icon: Icon(Icons.stars), label: Text("Metas")),
        NavigationRailDestination(icon: Icon(Icons.person), label: Text("Técnicos")),
        NavigationRailDestination(icon: Icon(Icons.warning_amber), label: Text("Defeitos")),
        NavigationRailDestination(icon: Icon(Icons.business), label: Text("Ativos")),
        NavigationRailDestination(icon: Icon(Icons.location_on), label: Text("Departamentos")),
        NavigationRailDestination(icon: Icon(Icons.analytics), label: Text("Status")),
      ],
      trailing: Expanded(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: _isRailExpanded 
              ? TextButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutPage())),
                  icon: const Icon(Icons.info_outline),
                  label: const Text("Sobre o Sistema"),
                  style: TextButton.styleFrom(foregroundColor: isDark ? Colors.white70 : Colors.grey.shade700),
                )
              : IconButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutPage())),
                  icon: const Icon(Icons.info_outline),
                  tooltip: "Sobre o Sistema",
                  color: isDark ? Colors.white70 : Colors.grey.shade700,
                ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentTab(List<RoundModel> rondas, List<RoundModel> allRondas, Color textColor, UserModel? user) {
    switch (_selectedIndex) {
      case 0: return _buildGeralTab(rondas, allRondas, textColor);
      case 1: return _buildMetasTab(allRondas, textColor, user);
      case 2: return _buildTecnicosTab(rondas, textColor);
      case 3: return _buildDefeitosTab(textColor);
      case 4: return _buildAtivosTab(textColor);
      case 5: return _buildDepartamentosTab(textColor);
      case 6: return _buildStatusTab(textColor);
      default: return _buildGeralTab(rondas, allRondas, textColor);
    }
  }

  Widget _buildCompanyLogo(bool isMobile) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _adminController.brandingStream,
      builder: (context, snapshot) {
        String logoUrl = "";
        String companyName = "RONDA TI";
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          logoUrl = data['logo_url'] ?? "";
          companyName = data['nome'] ?? "RONDA TI";
        }

        final displayUrl = UrlHelper.convertDriveUrl(logoUrl);
        final double logoHeight = isMobile ? 40 : 100;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (displayUrl != null && displayUrl.isNotEmpty)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(isMobile ? 6 : 12),
                ),
                padding: EdgeInsets.all(isMobile ? 3 : 6),
                child: Image.network(
                  displayUrl, 
                  height: logoHeight, 
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Image.asset("assets/logo.png", height: logoHeight),
                ),
              )
            else
              Image.asset(
                "assets/logo.png", 
                height: logoHeight, 
                errorBuilder: (_, __, ___) => Icon(Icons.business, size: logoHeight * 0.8),
              ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    companyName.toUpperCase(),
                    style: TextStyle(
                      fontSize: isMobile ? 11 : 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: isMobile ? 0.5 : 1.2,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    softWrap: true,
                  ),
                  Text(
                    isMobile ? "RONDA OPERACIONAL" : "SISTEMA DE GESTÃO E RONDAS",
                    style: TextStyle(
                      fontSize: isMobile ? 7 : 11,
                      color: Colors.white70,
                      letterSpacing: isMobile ? 0.5 : 2.0,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ],
        );
      }
    );
  }


  Widget _buildDepartamentosTab(Color textColor) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _adminController.sectorsStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final departamentos = snapshot.data!;
        
        return StreamBuilder<List<AssetModel>>(
          stream: _assetController.getAllAssetsStream(),
          builder: (context, assetSnapshot) {
            final allAssets = assetSnapshot.data ?? [];
            
            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 300,
                childAspectRatio: 1.5,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: departamentos.length,
              itemBuilder: (context, index) {
                final dep = departamentos[index];
                final itensDoDep = allAssets.where((a) => a.setor == dep['nome']).toList();
                
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _showDepartamentoDetails(context, dep['nome'], itensDoDep),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.location_on, color: Colors.blue, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  dep['nome'].toString().toUpperCase(),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "${itensDoDep.length}",
                                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
                                  ),
                                  const Text("Equipamentos", style: TextStyle(fontSize: 10, color: Colors.grey)),
                                ],
                              ),
                              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }
        );
      }
    );
  }

  void _showDepartamentoDetails(BuildContext context, String nome, List<AssetModel> itens) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.business, color: Colors.blue),
            const SizedBox(width: 10),
            Text(nome, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: itens.isEmpty 
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 30),
                child: Text("Nenhum equipamento alocado neste departamento.", textAlign: TextAlign.center),
              )
            : ListView.builder(
                shrinkWrap: true,
                itemCount: itens.length,
                itemBuilder: (context, index) {
                  final i = itens[index];
                  final bool isInMaintenance = i.statusOperacional == 'Em manutenção';
                  final bool hasDefect = i.temDefeito || isInMaintenance;

                  String statusInfo = "Status: ${i.statusOperacional}";
                  if (isInMaintenance && i.dataEntradaManutencao != null) {
                    final diff = DateTime.now().difference(i.dataEntradaManutencao!);
                    final days = diff.inDays;
                    final hours = diff.inHours % 24;
                    final minutes = diff.inMinutes % 60;
                    statusInfo += "\nTempo: ${days}d ${hours}h ${minutes}m";
                  }
                  
                  return Card(
                    elevation: 0,
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.white.withValues(alpha: 0.05) 
                        : Colors.grey.shade50,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: ListTile(
                      leading: Icon(
                        isInMaintenance ? Icons.build_circle : (i.tipo == 'Notebook' ? Icons.laptop : Icons.desktop_windows),
                        color: isInMaintenance ? Colors.orange : (hasDefect ? Colors.red : Colors.blue),
                      ),
                      title: Text("${i.tipo} - ${i.patrimonio}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: Text("$statusInfo\nMarca: ${i.marca.isNotEmpty ? i.marca : '---'}", style: const TextStyle(fontSize: 11)),
                      trailing: isInMaintenance 
                        ? const Icon(Icons.timer_outlined, color: Colors.orange, size: 18)
                        : (hasDefect ? const Icon(Icons.warning, color: Colors.red, size: 18) : null),
                    ),
                  );
                },
              ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Fechar")),
        ],
      ),
    );
  }

  Widget _buildFooter(Color textColor) {
    const String version = '3.2.5';
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Text(
          'Smart Ronda TI - Versão $version',
          style: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 10),
        ),
      ),
    );
  }

  Widget _buildGeralTab(List<RoundModel> filteredRondas, List<RoundModel> allRondas, Color textColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Filtro para hoje (Atividade do dia vigente)
    final today = DateTime.now();
    final hojeRondas = allRondas.where((r) => 
      r.dataInicio.day == today.day && 
      r.dataInicio.month == today.month && 
      r.dataInicio.year == today.year
    ).toList();
    
    final rankingDepartamentosHoje = _dashboardController.getRankingPorDepartamento(hojeRondas);
    final trendData = _dashboardController.getRoundsTrend(allRondas);

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _adminController.sectorsStream,
      builder: (context, sectorSnapshot) {
        final departamentos = sectorSnapshot.data ?? [];
        
        return StreamBuilder<List<AssetModel>>(
          stream: _assetController.getAllAssetsStream(),
          builder: (context, assetSnapshot) {
            final allAssets = assetSnapshot.data ?? [];
            
            final criticalAlerts = _dashboardController.getCriticalAlerts(allRondas, allAssets);
            final deptAlerts = _dashboardController.getInactiveDepartmentAlerts(allRondas, departamentos);
            
            final coverage = _dashboardController.getInventoryCoverage(allAssets, allRondas);
        final categories = _dashboardController.getAssetCategorySummary(allAssets);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (criticalAlerts.isNotEmpty || deptAlerts.isNotEmpty)
                _buildUnifiedAlertsExpander(criticalAlerts, deptAlerts),

              const SizedBox(height: 20),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    SummaryCard(
                      title: "Inventário Total", 
                      value: allAssets.length.toString(), 
                      icon: Icons.storage, 
                      color: Colors.teal,
                    ),
                    const SizedBox(width: 12),
                    SummaryCard(
                      title: "Auditados no Período", 
                      value: _dashboardController.getTotalItens(filteredRondas).toString(), 
                      icon: Icons.inventory_2, 
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 12),
                    SummaryCard(
                      title: "Defeitos (Total)", 
                      value: allAssets.where((a) => a.temDefeito || a.statusOperacional == 'Em manutenção').length.toString(), 
                      icon: Icons.error, 
                      color: Colors.red,
                    ),
                    const SizedBox(width: 12),
                    SummaryCard(
                      title: "Rondas (Período)", 
                      value: filteredRondas.length.toString(), 
                      icon: Icons.assignment_turned_in, 
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 12),
                    SummaryCard(
                      title: "Hoje", 
                      value: hojeRondas.length.toString(), 
                      icon: Icons.today, 
                      color: Colors.green,
                    ),
                    const SizedBox(width: 12),
                    SummaryCard(
                      title: "Autorizados HO", 
                      value: allAssets.where((a) => a.homeOfficeAutorizado).length.toString(),
                      icon: Icons.home_work, 
                      color: Colors.purple,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              const SectionTitle(title: "Tendência de Rondas (7 dias)"),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
                ),
                child: TrendChart(data: trendData, color: Colors.blue),
              ),

              const SizedBox(height: 32),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionTitle(title: "Saúde do Patrimônio"),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: CoverageChart(
                            auditado: coverage['auditado'] ?? 0, 
                            pendente: coverage['pendente'] ?? 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionTitle(title: "Categorias"),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: categories.take(4).map((e) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(e.key, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                                  Text(e.value.toString(), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                                ],
                              ),
                            )).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),
              const SectionTitle(title: "Atividade por Departamento (Hoje)"),
              const SizedBox(height: 16),
              _buildRankingCard(
                rankingDepartamentosHoje.take(5).toList(), 
                rankingDepartamentosHoje.isNotEmpty ? rankingDepartamentosHoje.first.value : 0,
                Colors.indigo,
              ),
              
              if (filteredRondas.length != hojeRondas.length) ...[
                const SizedBox(height: 32),
                const SectionTitle(title: "Top Departamentos (Período Selecionado)"),
                const SizedBox(height: 16),
                _buildRankingCard(
                  _dashboardController.getRankingPorDepartamento(filteredRondas).take(5).toList(),
                  _dashboardController.getRankingPorDepartamento(filteredRondas).isNotEmpty 
                    ? _dashboardController.getRankingPorDepartamento(filteredRondas).first.value 
                    : 0,
                  Colors.blue,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
);
}

  Widget _buildMetasTab(List<RoundModel> allRondas, Color textColor, UserModel? user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final monthlyData = _dashboardController.getMonthlyComparison(allRondas);
    
    final now = DateTime.now();
    final thisMonthRondas = allRondas.where((r) => r.dataInicio.month == now.month && r.dataInicio.year == now.year).toList();
    final totalItensMes = _dashboardController.getTotalItens(thisMonthRondas);
    final bool canEdit = user?.isAdmin ?? false;

    return StreamBuilder<DocumentSnapshot>(
      stream: _adminController.goalsStream,
      builder: (context, snapshot) {
        Map<String, dynamic> goals = {
          'rondas_mensal': 100,
          'itens_mensal': 500,
          'defeitos_max': 10,
        };

        if (snapshot.hasData && snapshot.data!.exists) {
          goals = snapshot.data!.data() as Map<String, dynamic>;
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle(title: "Progresso das Metas (Mês Atual)", color: Colors.amber),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: [
                  GoalProgressCard(
                    title: "RONDAS REALIZADAS", 
                    current: thisMonthRondas.length.toDouble(), 
                    goal: (goals['rondas_mensal'] ?? 100).toDouble(), 
                    color: Colors.blue,
                    unit: "rondas",
                  ),
                  GoalProgressCard(
                    title: "ITENS AUDITADOS", 
                    current: totalItensMes.toDouble(), 
                    goal: (goals['itens_mensal'] ?? 500).toDouble(), 
                    color: Colors.orange,
                    unit: "itens",
                  ),
                ],
              ),
              const SizedBox(height: 32),
              const SectionTitle(title: "Comparativo Mensal (Últimos 6 Meses)", color: Colors.purple),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Text("Volume de Rondas", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    ComparisonChart(data: monthlyData, metric: 'rondas', color: Colors.purple),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Text("Itens Auditados", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    ComparisonChart(data: monthlyData, metric: 'itens', color: Colors.orange),
                  ],
                ),
              ),
              if (canEdit) ...[
                const SizedBox(height: 32),
                const Divider(),
                Center(
                  child: TextButton.icon(
                    onPressed: () => _showEditGoalsDialog(goals),
                    icon: const Icon(Icons.edit_note),
                    label: const Text("Ajustar Metas Estratégicas"),
                  ),
                ),
              ],
            ],
          ),
        );
      }
    );
  }

  void _showEditGoalsDialog(Map<String, dynamic> currentGoals) {
    // Implementação rápida para o Admin editar metas
    final rondasController = TextEditingController(text: currentGoals['rondas_mensal']?.toString());
    final itensController = TextEditingController(text: currentGoals['itens_mensal']?.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Configurar Metas"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: rondasController,
              decoration: const InputDecoration(labelText: "Meta de Rondas/Mês"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: itensController,
              decoration: const InputDecoration(labelText: "Meta de Itens Auditados/Mês"),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              try {
                final int r = int.tryParse(rondasController.text.trim()) ?? 100;
                final int i = int.tryParse(itensController.text.trim()) ?? 500;
                
                await _adminController.updateGoals({
                  'rondas_mensal': r,
                  'itens_mensal': i,
                  'ultima_atualizacao': FieldValue.serverTimestamp(),
                });
                
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("✅ Metas atualizadas com sucesso!"), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("❌ Erro ao salvar: $e"), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text("Salvar"),
          ),
        ],
      ),
    );
  }

  Widget _buildTecnicosTab(List<RoundModel> rondas, Color textColor) {
    final rankingTecnicos = _dashboardController.getRankingPorTecnico(rondas);
    final ultimasAtividades = rondas.toList()..sort((a, b) => b.dataInicio.compareTo(a.dataInicio));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          const SizedBox(height: 32),
          const SectionTitle(title: "Histórico de Atividades Recentes", color: Colors.orange),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: ultimasAtividades.take(10).length,
            itemBuilder: (context, index) {
              final r = ultimasAtividades[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  dense: true,
                  leading: const CircleAvatar(child: Icon(Icons.person_outline, size: 16)),
                  title: Text("${r.tecnico} no setor ${r.setor}", style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${DateFormat('dd/MM HH:mm').format(r.dataInicio)} | ${r.itensTotal} itens | ${r.defeitosTotal} defeitos"),
                ),
              );
            },
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
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
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
            final displayPat = item.patrimonio.startsWith("SP_") ? "SEM PLACA" : item.patrimonio;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.redAccent,
                  child: Icon(Icons.warning_amber_rounded, color: Colors.white),
                ),
                title: Text("${item.tipo} - Pat: $displayPat", style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Departamento: ${item.setor}\nDefeito: ${item.descricaoDefeito ?? 'Não informado'}"),
                isThreeLine: true,
              ),
            );
          },
        );
      }
    );
  }

  Widget _buildAtivosTab(Color textColor) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('inventario_mestre')
          .snapshots()
          .map((snap) => snap.docs.map((doc) {
                final data = doc.data();
                return {...data, 'patrimonio': data['patrimonio'] ?? doc.id};
              }).toList()),
      builder: (context, snapshot) {
        final itens = snapshot.data ?? [];
        if (itens.isEmpty) return const Center(child: Text("Nenhum item encontrado no Castelo."));

        Map<String, List<Map<String, dynamic>>> porOrigem = {};
        for (var i in itens) {
          String origem = (i['is_locado'] == true && i['locadora'] != null) 
              ? i['locadora'].toString().toUpperCase() 
              : "PATRIMÔNIO PRÓPRIO";
          porOrigem.putIfAbsent(origem, () => []).add(i);
        }

        // Ordena para que Patrimônio Próprio apareça primeiro
        final listaOrdenada = porOrigem.entries.toList()
          ..sort((a, b) {
            if (a.key == "PATRIMÔNIO PRÓPRIO") return -1;
            if (b.key == "PATRIMÔNIO PRÓPRIO") return 1;
            return a.key.compareTo(b.key);
          });

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SectionTitle(title: "Gestão Geral de Ativos (Próprios e Locados)"),
            const SizedBox(height: 16),
            ...listaOrdenada.map((entry) {
              final isProprio = entry.key == "PATRIMÔNIO PRÓPRIO";
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: isProprio ? Colors.blue.shade100 : Colors.orange.shade100,
                    child: Icon(isProprio ? Icons.inventory : Icons.business_center, color: isProprio ? Colors.blue.shade900 : Colors.orange.shade900),
                  ),
                  title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${entry.value.length} equipamentos cadastrados"),
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
              subtitle: Text("Departamento: ${item['setor'] ?? '---'} | Status: ${item['status_operacional'] ?? 'Em uso'}"),
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
          const SectionTitle(title: "Análise de Saúde do Parque"),
          const SizedBox(height: 20),
          
          StreamBuilder<List<AssetModel>>(
            stream: _assetController.getMaintenanceStream(),
            builder: (context, snapshot) {
              final itens = snapshot.data ?? [];
              final count = itens.length;
              
              // Pequeno resumo por tipo
              Map<String, int> porTipo = {};
              for (var i in itens) {
                porTipo[i.tipo] = (porTipo[i.tipo] ?? 0) + 1;
              }
              String resumo = porTipo.entries.map((e) => "${e.value} ${e.key}(s)").join(", ");
              if (resumo.isEmpty) resumo = "Tudo operando normalmente";

              return Column(
                children: [
                  StatusIndicatorCard(
                    title: "EM MANUTENÇÃO", 
                    count: count.toString(), 
                    icon: Icons.build_circle_outlined, 
                    color: Colors.orange, 
                    onTap: () => _showItensList(context, "Itens em Manutenção", itens),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                    child: Text(
                      resumo, 
                      style: const TextStyle(fontSize: 11, color: Colors.blueGrey, fontStyle: FontStyle.italic),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              );
            }
          ),
          
          const SizedBox(height: 12),
          StreamBuilder<List<AssetModel>>(
            stream: _assetController.getAllAssetsStream().map((list) => list.where((a) => a.homeOfficeAutorizado).toList()),
            builder: (context, snapshot) {
              final count = snapshot.data?.length ?? 0;
              return StatusIndicatorCard(
                title: "AUTORIZADOS HOME OFFICE", 
                count: count.toString(), 
                icon: Icons.home_work_outlined, 
                color: Colors.blue, 
                onTap: () => _showItensList(context, "Ativos Autorizados Home Office", snapshot.data ?? []),
              );
            }
          ),
          
          const SizedBox(height: 12),
          StreamBuilder<List<AssetModel>>(
            stream: _assetController.getDivergenceStream(),
            builder: (context, snapshot) {
              final count = snapshot.data?.length ?? 0;
              return StatusIndicatorCard(
                title: "DIVERGÊNCIAS DE LOCAL", 
                count: count.toString(), 
                icon: Icons.wrong_location_outlined, 
                color: Colors.purple, 
                onTap: () => _showItensList(context, "Ativos em Departamento Divergente", snapshot.data ?? []),
              );
            }
          ),
          
          const SizedBox(height: 12),
          StreamBuilder<List<AssetModel>>(
            stream: _assetController.getObsoleteStream(),
            builder: (context, snapshot) {
              final count = snapshot.data?.length ?? 0;
              return StatusIndicatorCard(
                title: "EQUIPAMENTOS ANTIGOS (+5 ANOS)", 
                count: count.toString(), 
                icon: Icons.timer_outlined, 
                color: Colors.deepPurple, 
                onTap: () => _showItensList(context, "Ativos Obsoletos", snapshot.data ?? []),
              );
            }
          ),
          
          const SizedBox(height: 30),
          const Divider(),
          const SizedBox(height: 10),
          const Text(
            "ℹ️ Itens em manutenção são vinculados automaticamente ao TI.",
            style: TextStyle(fontSize: 11, color: Colors.grey),
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

  Widget _buildUnifiedAlertsExpander(List<String> critical, List<String> inactive) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalCount = critical.length + inactive.length;
    
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      color: Colors.orange.withValues(alpha: 0.05),
      child: ExpansionTile(
        leading: Icon(
          critical.isNotEmpty ? Icons.report_problem : Icons.warning_amber_rounded, 
          color: critical.isNotEmpty ? Colors.red : Colors.orange,
        ),
        title: Text(
          "⚠️ CENTRAL DE ALERTAS ($totalCount)",
          style: TextStyle(
            color: critical.isNotEmpty ? Colors.red : Colors.orange.shade900, 
            fontWeight: FontWeight.bold, 
            fontSize: 13,
          ),
        ),
        subtitle: Text(
          "${critical.length} críticos | ${inactive.length} pendentes",
          style: const TextStyle(fontSize: 10, color: Colors.blueGrey),
        ),
        children: [
          if (critical.isNotEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: critical.map((a) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, size: 16, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(child: Text(a, style: const TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.bold))),
                    ],
                  ),
                )).toList(),
              ),
            ),
          ],
          if (inactive.isNotEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: inactive.map((a) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.history_toggle_off, size: 16, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(child: Text(a, style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87))),
                    ],
                  ),
                )).toList(),
              ),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
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
                  String subtitulo = "Departamento: ${item.setor}";
                  if (item.setorDivergente) {
                    subtitulo += "\nOrigem: ${item.motivoDivergencia ?? 'Não inf.'}";
                  }
                  if (item.statusOperacional == 'Em manutenção') {
                    subtitulo += "\nDefeito: ${item.descricaoDefeito ?? 'Não inf.'}";
                    if (item.dataEntradaManutencao != null) {
                      final diff = DateTime.now().difference(item.dataEntradaManutencao!);
                      subtitulo += "\nTempo: ${diff.inDays}d ${diff.inHours % 24}h ${diff.inMinutes % 60}m";
                    }
                  }
                  if (item.isHomeOffice) {
                    subtitulo += "\nResponsável: ${item.responsavelExterno ?? 'Não inf.'}";
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
