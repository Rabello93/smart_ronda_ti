import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_ronda_ti/features/system/auth/controllers/auth_controller.dart';
import 'package:smart_ronda_ti/features/management/admin/controllers/admin_controller.dart';
import 'package:smart_ronda_ti/features/management/reports/repositories/export_repository.dart';
import 'package:smart_ronda_ti/features/operation/rounds/history/history_page.dart';
import 'package:smart_ronda_ti/features/operation/rounds/pages/ronda_page.dart';
import 'package:smart_ronda_ti/core/utils/utils.dart';
import 'package:smart_ronda_ti/app/app.dart';
import 'package:smart_ronda_ti/features/management/admin/pages/admin_page.dart';
import 'package:smart_ronda_ti/features/system/about/pages/about_page.dart';
import 'package:smart_ronda_ti/features/management/reports/repositories/pdf_repository.dart';
import 'package:smart_ronda_ti/features/management/dashboard/pages/dashboard_page.dart';
import 'package:smart_ronda_ti/features/system/auth/models/user_model.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController setorController = TextEditingController();
  final AuthController _authController = AuthController();
  final AdminController _adminController = AdminController();
  
  final _nomeController = TextEditingController();
  final _nascimentoController = TextEditingController();
  final _funcaoController = TextEditingController();
  final _localController = TextEditingController();
  
  String? setorSelecionado;
  bool salvandoReparo = false;

  @override
  void dispose() {
    setorController.dispose();
    _nomeController.dispose();
    _nascimentoController.dispose();
    _funcaoController.dispose();
    _localController.dispose();
    super.dispose();
  }

  Future<void> adicionarSetor() async {
    String nome = setorController.text.trim();
    if (nome.isEmpty) return;
    try {
      await _adminController.createSector(nome);
      await _adminController.registerLog(
        action: "ADD SETOR",
        details: "Adicionou setor: $nome"
      );
      setorController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Setor adicionado com sucesso!"),
            duration: Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro ao adicionar setor: $e"), 
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _repararPerfil() async {
    if (_nomeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("O nome é obrigatório"), behavior: SnackBarBehavior.floating)
      );
      return;
    }
    setState(() => salvandoReparo = true);
    try {
      final user = _authController.currentUser;
      if (user != null) {
        await _authController.updateProfile(UserModel(
          uid: user.uid,
          nome: _nomeController.text.trim(),
          email: user.email ?? "",
          dataNascimento: _nascimentoController.text.trim(),
          funcao: _funcaoController.text.trim(),
          localTrabalho: _localController.text.trim(),
          ativo: true,
        ));
      }

      await NotificationService.showLocalNotification(
        title: "Perfil Atualizado",
        body: "Seus dados foram salvos com sucesso."
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao salvar: $e"), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating)
        );
      }
    } finally {
      if (mounted) setState(() => salvandoReparo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserModel?>(
      stream: _authController.profileStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final userData = snapshot.data;
        
        if (userData == null || userData.nome.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text("Completar Perfil"), actions: [
              IconButton(icon: const Icon(Icons.logout), onPressed: () => _authController.logout())
            ]),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(Icons.contact_emergency_outlined, size: 60, color: Colors.orange),
                  const SizedBox(height: 10),
                  const Text("Quase pronto!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const Text("Sua conta foi criada, mas precisamos desses dados para as rondas:", textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  TextField(controller: _nomeController, decoration: const InputDecoration(labelText: 'Nome Completo', border: OutlineInputBorder())),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _nascimentoController, 
                    decoration: InputDecoration(
                      labelText: 'Data de Nascimento', 
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [DataInputFormatter()],
                  ),
                  const SizedBox(height: 10),
                  TextField(controller: _funcaoController, decoration: const InputDecoration(labelText: 'Função na TI', border: OutlineInputBorder())),
                  const SizedBox(height: 10),
                  TextField(controller: _localController, decoration: const InputDecoration(labelText: 'Local de Trabalho', border: OutlineInputBorder())),
                  const SizedBox(height: 20),
                  salvandoReparo 
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _repararPerfil, 
                        style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 55), backgroundColor: Colors.orange.shade800, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                        child: const Text("SALVAR E ACESSAR O APP", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                ],
              ),
            ),
          );
        }

        final bool isMaster = userData.nivelAcesso == 'master';
        final bool isGerente = userData.nivelAcesso == 'gerente';

        return Scaffold(
          drawer: Drawer(
            child: Column(
              children: [
                UserAccountsDrawerHeader(
                  accountName: Text(userData.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                  accountEmail: Text(userData.email),
                  currentAccountPicture: const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.person, size: 40, color: Colors.blue)),
                  decoration: BoxDecoration(color: Colors.blue.shade900),
                ),
                ListTile(
                  leading: const Icon(Icons.history),
                  title: const Text("Histórico de Rondas"),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryPage())),
                ),
                if (isMaster || isGerente)
                  ListTile(
                    leading: const Icon(Icons.admin_panel_settings, color: Colors.indigo),
                    title: const Text("Gestão Corporativa"),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPage())),
                  ),
                if (isMaster || isGerente || userData.nivelAcesso == 'espectador')
                  ListTile(
                    leading: const Icon(Icons.analytics, color: Colors.green),
                    title: const Text("Dashboard BI"),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DashboardPage(themeMode: RondaTIApp.of(context).themeMode, onChangeTheme: RondaTIApp.of(context).changeTheme))),
                  ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text("Sobre o Sistema"),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutPage())),
                ),
                const Spacer(),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text("Sair da Conta"),
                  onTap: () => _authController.logout(),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          appBar: AppBar(
            title: StreamBuilder<DocumentSnapshot>(
              stream: _adminController.brandingStream,
              builder: (context, snapshot) {
                String nomeEmpresa = "RONDA TI CORPORATIVA";
                String logoUrl = "";
                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  nomeEmpresa = data['nome'] ?? nomeEmpresa;
                  logoUrl = data['logo_url'] ?? "";
                  if (logoUrl.contains("drive.google.com")) {
                    final fileId = RegExp(r"d/(.+)/").firstMatch(logoUrl)?.group(1) ?? RegExp(r"id=(.+)").firstMatch(logoUrl)?.group(1);
                    if (fileId != null) logoUrl = "https://docs.google.com/uc?export=download&id=$fileId";
                  }
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
            backgroundColor: Colors.blue.shade900,
            foregroundColor: Colors.white,
            actions: [
              IconButton(icon: const Icon(Icons.history), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryPage()))),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.blue.shade100)
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(radius: 30, child: Icon(Icons.person, size: 35)),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Bem-vindo(a),", style: TextStyle(color: Colors.blue.shade700, fontSize: 14)),
                            Text(userData.nome, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                const Text("Iniciar Nova Ronda", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _adminController.sectorsStream,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    final setores = snapshot.data!;
                    return DropdownButtonFormField<String>(
                      initialValue: setorSelecionado,
                      decoration: const InputDecoration(labelText: "Selecione o Setor", border: OutlineInputBorder(), prefixIcon: Icon(Icons.location_on)),
                      items: setores.map((s) => DropdownMenuItem(value: s['nome'] as String, child: Text(s['nome']))).toList(),
                      onChanged: (v) => setState(() => setorSelecionado = v),
                    );
                  }
                ),
                const SizedBox(height: 10),
                if (isMaster || isGerente)
                  Row(
                    children: [
                      Expanded(child: TextField(controller: setorController, decoration: const InputDecoration(labelText: "Novo Setor", border: OutlineInputBorder(), hintText: "Digite para adicionar"))),
                      const SizedBox(width: 10),
                      ElevatedButton(onPressed: adicionarSetor, style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade900, foregroundColor: Colors.white, minimumSize: const Size(60, 55)), child: const Icon(Icons.add)),
                    ],
                  ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton.icon(
                    onPressed: setorSelecionado == null ? null : () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => RondaPage(setor: setorSelecionado!, tecnico: userData.nome, tecnicoId: userData.uid)));
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text("INICIAR RONDA", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  ),
                ),
                const SizedBox(height: 40),
                const Divider(),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _quickAction(context, "HISTÓRICO", Icons.history, Colors.blue, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryPage()))),
                    _quickAction(context, "RELATÓRIO", Icons.picture_as_pdf, Colors.red, () => _abrirFiltroExportacao(context, 'pdf', isMaster, userData.nivelAcesso)),
                    _quickAction(context, "PLANILHA", Icons.table_chart, Colors.green, () => _abrirFiltroExportacao(context, 'csv', isMaster, userData.nivelAcesso)),
                  ],
                ),
                const SizedBox(height: 30),
                if (isMaster || isGerente || userData.nivelAcesso == 'espectador')
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DashboardPage(themeMode: RondaTIApp.of(context).themeMode, onChangeTheme: RondaTIApp.of(context).changeTheme))),
                      icon: const Icon(Icons.analytics),
                      label: const Text("VER PAINEL DE INDICADORES (BI)"),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: Colors.indigo.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                const Center(child: Text('Smart Ronda TI - Versão 3.0.0', style: TextStyle(color: Colors.blueGrey, fontSize: 12))),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _quickAction(BuildContext context, String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Column(
        children: [
          Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(15)), child: Icon(icon, color: color, size: 30)),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade800)),
        ],
      ),
    );
  }

  void _abrirFiltroExportacao(BuildContext context, String tipo, bool isMaster, String meuNivel) {
    String? filtroSetor;
    String? filtroLocadora;
    String? filtroTipoEquip;
    bool filtroApenasDefeitos = false;
    bool filtroApenasObsoletos = false;
    bool? filtroSemPatrimonio; 
    String? filtroTecnico;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Configurar Relatório ${tipo.toUpperCase()}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                
                StreamBuilder<List<UserModel>>(
                  stream: _adminController.usersStream,
                  builder: (context, snapshot) {
                    List<UserModel> tecnicos = snapshot.data ?? [];
                    if (meuNivel == 'gerente') {
                      tecnicos = tecnicos.where((t) => t.nivelAcesso == 'normal' || t.nivelAcesso == 'teste' || t.uid == _authController.currentUser?.uid).toList();
                    } else if (meuNivel == 'normal' || meuNivel == 'teste') {
                      tecnicos = tecnicos.where((t) => t.uid == _authController.currentUser?.uid).toList();
                    }
                    return DropdownButtonFormField<String>(
                      initialValue: filtroTecnico,
                      decoration: const InputDecoration(labelText: "Filtrar por Técnico", border: OutlineInputBorder()),
                      items: [
                        if (isMaster || meuNivel == 'gerente') const DropdownMenuItem(value: null, child: Text("TODOS OS TÉCNICOS VISÍVEIS")),
                        ...tecnicos.map((t) => DropdownMenuItem(value: t.uid, child: Text(t.nome))),
                      ],
                      onChanged: (v) => setModalState(() => filtroTecnico = v),
                    );
                  }
                ),
                const SizedBox(height: 10),

                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _adminController.sectorsStream,
                  builder: (context, snapshot) {
                    final setores = snapshot.data ?? [];
                    return DropdownButtonFormField<String>(
                      initialValue: filtroSetor,
                      decoration: const InputDecoration(labelText: "Filtrar por Setor", border: OutlineInputBorder()),
                      items: [
                        const DropdownMenuItem(value: null, child: Text("TODOS OS SETORES")),
                        ...setores.map((s) => DropdownMenuItem(value: s['nome'], child: Text(s['nome']))),
                      ],
                      onChanged: (v) => setModalState(() => filtroSetor = v),
                    );
                  }
                ),
                const SizedBox(height: 10),

                StreamBuilder<List<String>>(
                  stream: _adminController.leasingCompaniesStream,
                  builder: (context, snapshot) {
                    final locadoras = snapshot.data ?? [];
                    return DropdownButtonFormField<String>(
                      initialValue: filtroLocadora,
                      decoration: const InputDecoration(labelText: "Filtrar por Locadora", border: OutlineInputBorder()),
                      items: [
                        const DropdownMenuItem(value: null, child: Text("TODAS AS LOCADORAS")),
                        ...locadoras.map((l) => DropdownMenuItem(value: l, child: Text(l))),
                      ],
                      onChanged: (v) => setModalState(() => filtroLocadora = v),
                    );
                  }
                ),
                const SizedBox(height: 10),

                DropdownButtonFormField<String>(
                  initialValue: filtroTipoEquip,
                  decoration: const InputDecoration(labelText: "Filtrar por Tipo de Ativo", border: OutlineInputBorder()),
                  items: [
                    const DropdownMenuItem(value: null, child: Text("TODOS OS TIPOS")),
                    ...['Notebook', 'Desktop', 'Telefone', 'Smartphone', 'Impressora', 'TV', 'No-Break', 'Switch', 'Tablet', 'Leitor', 'Roteador', 'Access Point', 'Outro']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s))),
                  ],
                  onChanged: (v) => setModalState(() => filtroTipoEquip = v),
                ),
                const SizedBox(height: 10),

                CheckboxListTile(
                  title: const Text("Apenas itens com DEFEITO"),
                  value: filtroApenasDefeitos,
                  onChanged: (v) => setModalState(() => filtroApenasDefeitos = v!),
                ),
                
                CheckboxListTile(
                  title: const Text("Apenas itens OBSOLETOS (+5 anos)"),
                  value: filtroApenasObsoletos,
                  onChanged: (v) => setModalState(() => filtroApenasObsoletos = v!),
                ),

                DropdownButtonFormField<bool?>(
                  initialValue: filtroSemPatrimonio,
                  decoration: const InputDecoration(labelText: "Filtro de Patrimônio", border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: null, child: Text("TODOS OS ITENS")),
                    DropdownMenuItem(value: true, child: Text("APENAS SEM PLACA")),
                    DropdownMenuItem(value: false, child: Text("APENAS COM PLACA")),
                  ],
                  onChanged: (v) => setModalState(() => filtroSemPatrimonio = v),
                ),

                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    if (tipo == 'csv') {
                      ExportRepository.exportarRondasParaCSV(
                        tecnicoId: filtroTecnico,
                        setor: filtroSetor,
                        locadora: filtroLocadora,
                        tipoEquipamento: filtroTipoEquip,
                        apenasDefeitos: filtroApenasDefeitos,
                        apenasObsoletos: filtroApenasObsoletos,
                        apenasSemPatrimonio: filtroSemPatrimonio,
                        context: context
                      );
                    } else {
                      PdfRepository.exportarRondasParaPDF(
                        tecnicoId: filtroTecnico,
                        setor: filtroSetor,
                        locadora: filtroLocadora,
                        tipoEquipamento: filtroTipoEquip,
                        apenasDefeitos: filtroApenasDefeitos,
                        apenasObsoletos: filtroApenasObsoletos,
                        apenasSemPatrimonio: filtroSemPatrimonio,
                        context: context
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: tipo == 'csv' ? Colors.blue : Colors.red, foregroundColor: Colors.white),
                  child: Text("GERAR RELATÓRIO ${tipo.toUpperCase()}"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
