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
              _buildDrawerItem(4, Icons.business, "Locação", isDark),
              _buildDrawerItem(5, Icons.analytics, "Status", isDark),
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
        NavigationRailDestination(icon: Icon(Icons.business), label: Text("Locação")),
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
      case 4: return _buildLocacaoTab(textColor);
      case 5: return _buildStatusTab(textColor);
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


  Widget _buildFooter(Color textColor) {
    const String version = '3.2.0';
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
    
    final rankingSetoresHoje = _dashboardController.getRankingPorSetor(hojeRondas);
    final trendData = _dashboardController.getRoundsTrend(allRondas);

    return StreamBuilder<List<AssetModel>>(
      stream: _assetController.getAllAssetsStream(),
      builder: (context, assetSnapshot) {
        final allAssets = assetSnapshot.data ?? [];
        final alerts = _dashboardController.getCriticalAlerts(allRondas, allAssets);
        final coverage = _dashboardController.getInventoryCoverage(allAssets, allRondas);
        final categories = _dashboardController.getAssetCategorySummary(allAssets);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (alerts.isNotEmpty) CriticalAlertBanner(alerts: alerts),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SectionTitle(title: "Resumo Operacional"),
                  _buildFiltroData(),
                ],
              ),
              const SizedBox(height: 16),
              
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    SummaryCard(
                      title: "Rondas (Período)", 
                      value: filteredRondas.length.toString(), 
                      icon: Icons.assignment_turned_in, 
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 12),
                    SummaryCard(
                      title: "Itens Vistos", 
                      value: _dashboardController.getTotalItens(filteredRondas).toString(), 
                      icon: Icons.inventory_2, 
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 12),
                    SummaryCard(
                      title: "Defeitos", 
                      value: _dashboardController.getTotalDefeitos(filteredRondas).toString(), 
                      icon: Icons.error, 
                      color: Colors.red,
                    ),
                    const SizedBox(width: 12),
                    SummaryCard(
                      title: "Hoje", 
                      value: hojeRondas.length.toString(), 
                      icon: Icons.today, 
                      color: Colors.green,
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
              const SectionTitle(title: "Atividade por Setor (Hoje)"),
              const SizedBox(height: 16),
              _buildRankingCard(
                rankingSetoresHoje.take(5).toList(), 
                rankingSetoresHoje.isNotEmpty ? rankingSetoresHoje.first.value : 0,
                Colors.indigo,
              ),
              
              if (filteredRondas.length != hojeRondas.length) ...[
                const SizedBox(height: 32),
                const SectionTitle(title: "Top Setores (Período Selecionado)"),
                const SizedBox(height: 16),
                _buildRankingCard(
                  _dashboardController.getRankingPorSetor(filteredRondas).take(5).toList(),
                  _dashboardController.getRankingPorSetor(filteredRondas).isNotEmpty 
                    ? _dashboardController.getRankingPorSetor(filteredRondas).first.value 
                    : 0,
                  Colors.blue,
                ),
              ],
            ],
          ),
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
          .map((snap) => snap.docs.map((doc) => doc.data()).toList()),
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
            stream: _assetController.getDivergenceStream(),
            builder: (context, snapshot) {
              final count = snapshot.data?.length ?? 0;
              return StatusIndicatorCard(
                title: "DIVERGÊNCIAS DE LOCAL", 
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
