import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_ronda_ti/core/services/auth/auth_service.dart';
import 'package:smart_ronda_ti/core/services/admin/admin_service.dart';
import 'package:smart_ronda_ti/core/services/inventory/inventory_service.dart';
import 'package:smart_ronda_ti/core/models/usuario_model.dart';
import 'package:smart_ronda_ti/core/models/ativo_model.dart';
import 'package:smart_ronda_ti/features/logs/pages/log_page.dart';
import 'package:smart_ronda_ti/features/reports/services/pdf_service.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final InventoryService _inventoryService = InventoryService();
  final AuthService _authService = AuthService();

  void _confirmarResetInventario(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("⚠️ RESET TOTAL DO CASTELO"),
        content: const Text("Isso apagará TODOS os itens do Inventário Mestre. Confirma?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCELAR")),
          ElevatedButton(
            onPressed: () async {
              await _inventoryService.resetarInventarioMestre();
              if (context.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Castelo limpo!")));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade900, foregroundColor: Colors.white),
            child: const Text("CONFIRMAR RESET"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UsuarioModel?>(
      stream: _authService.getPerfilStream(),
      builder: (context, profileSnapshot) {
        if (!profileSnapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        final userData = profileSnapshot.data!;
        final bool isMaster = userData.nivelAcesso == 'master';

        return DefaultTabController(
          length: 5,
          child: Scaffold(
            appBar: AppBar(
              title: const Text("Administração Corporativa"),
              backgroundColor: Colors.indigo.shade900,
              foregroundColor: Colors.white,
              bottom: const TabBar(
                isScrollable: true,
                tabs: [
                  Tab(icon: Icon(Icons.people), text: "Equipe"),
                  Tab(icon: Icon(Icons.castle), text: "O Castelo"),
                  Tab(icon: Icon(Icons.location_on), text: "Setores"),
                  Tab(icon: Icon(Icons.business), text: "Empresa"),
                  Tab(icon: Icon(Icons.swap_horiz), text: "Locadoras"),
                ],
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
              ),
              actions: [
                if (isMaster)
                  IconButton(
                    icon: const Icon(Icons.cleaning_services, color: Colors.orange),
                    onPressed: () => _confirmarResetInventario(context),
                    tooltip: "Resetar Inventário Mestre",
                  ),
                IconButton(
                  icon: const Icon(Icons.receipt_long),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LogPage())),
                  tooltip: "Ver Logs",
                )
              ],
            ),
            body: const TabBarView(
              children: [
                _EquipeTab(),
                _CasteloTab(),
                _SetoresTab(),
                _EmpresaTab(),
                _LocadorasTab(),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EquipeTab extends StatelessWidget {
  const _EquipeTab();

  void _alterarUsuario(BuildContext context, UsuarioModel user) {
    final TextEditingController matriculaController = TextEditingController(text: user.matricula);
    String nivelSelecionado = user.nivelAcesso;
    bool ativo = user.ativo;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: Text("Editar: ${user.nome}"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: matriculaController,
                  decoration: const InputDecoration(labelText: "Nº Matrícula", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  initialValue: nivelSelecionado,
                  decoration: const InputDecoration(labelText: "Nível de Acesso", border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'normal', child: Text("Normal")),
                    DropdownMenuItem(value: 'gerente', child: Text("Gerente")),
                    DropdownMenuItem(value: 'master', child: Text("Master")),
                    DropdownMenuItem(value: 'espectador', child: Text("Espectador")),
                    DropdownMenuItem(value: 'teste', child: Text("Teste")),
                  ],
                  onChanged: (v) => setModalState(() => nivelSelecionado = v!),
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  title: const Text("Conta Ativa?"),
                  value: ativo,
                  onChanged: (v) => setModalState(() => ativo = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCELAR")),
            ElevatedButton(
              onPressed: () async {
                final AuthService authService = AuthService();
                final AdminService adminService = AdminService();
                
                await authService.atualizarPerfil(UsuarioModel(
                  uid: user.uid,
                  nome: user.nome,
                  email: user.email,
                  dataNascimento: user.dataNascimento,
                  funcao: user.funcao,
                  localTrabalho: user.localTrabalho,
                  matricula: matriculaController.text.trim(),
                  nivelAcesso: nivelSelecionado,
                  ativo: ativo,
                ));
                
                await adminService.registrarLog(acao: "GESTÃO PERFIL", detalhes: "Alterou perfil de ${user.nome}. Nível: $nivelSelecionado, Ativo: $ativo");
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text("SALVAR ALTERAÇÕES"),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarExclusao(BuildContext context, UsuarioModel user, bool isMaster) {
    final motivoController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Gerenciar Acesso: ${user.nome}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Desativar ou remover permanentemente?"),
            const SizedBox(height: 20),
            TextField(
              controller: motivoController,
              decoration: const InputDecoration(labelText: "Motivo (para desativação)", border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCELAR")),
          ElevatedButton(
            onPressed: () async {
              if (motivoController.text.trim().isEmpty) return;
              final AdminService service = AdminService();
              await service.excluirUsuarioComMotivo(uid: user.uid, motivo: motivoController.text.trim());
              if (context.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Usuário desativado!")));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
            child: const Text("DESATIVAR"),
          ),
          if (isMaster)
            ElevatedButton(
              onPressed: () async {
                final AdminService service = AdminService();
                await service.excluirUsuarioDefinitivo(user.uid);
                if (context.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Perfil removido do banco!")));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: const Text("EXCLUIR DEFINITIVO"),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AdminService service = AdminService();
    final AuthService authService = AuthService();
    
    return StreamBuilder<List<UsuarioModel>>(
      stream: service.getAllTecnicos(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final users = snapshot.data!;
        
        return StreamBuilder<UsuarioModel?>(
          stream: authService.getPerfilStream(),
          builder: (context, mySnap) {
            final meuNivel = mySnap.data?.nivelAcesso ?? 'normal';
            return ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final t = users[index];
                final bool isAtivo = t.ativo;
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isAtivo ? Colors.green.shade100 : Colors.red.shade100,
                      child: Icon(isAtivo ? Icons.person : Icons.person_off, color: isAtivo ? Colors.green : Colors.red),
                    ),
                    title: Text(t.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("Nível: ${t.nivelAcesso}\n${t.email}"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _alterarUsuario(context, t),
                          tooltip: "Alterar Nível",
                        ),
                        IconButton(icon: const Icon(Icons.person_off, color: Colors.red), onPressed: () => _mostrarExclusao(context, t, meuNivel == 'master'), tooltip: "Gerenciar Acesso"),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        );
      },
    );
  }
}

class _SetoresTab extends StatelessWidget {
  const _SetoresTab();

  void _abrirHistoricoSetor(BuildContext context, String setor) {
    final InventoryService service = InventoryService();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Mapa de Ativos - $setor"),
        content: SizedBox(
          width: 600,
          child: StreamBuilder<List<AtivoModel>>(
            stream: service.getItensPorSetor(setor),
            builder: (context, snapshot) {
              final itens = snapshot.data ?? [];
              if (itens.isEmpty) return const Text("Nenhum item alocado neste setor atualmente.");
              return ListView.builder(
                shrinkWrap: true,
                itemCount: itens.length,
                itemBuilder: (context, index) {
                  final i = itens[index];
                  return ListTile(
                    title: Text("${i.tipo} - Pat: ${i.patrimonio}"),
                    subtitle: Text("Status: ${i.statusOperacional} | S/N: ${i.serie}"),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("FECHAR")),
          ElevatedButton.icon(
            onPressed: () async {
              final itensSnapshot = await service.getItensPorSetor(setor).first;
              // Converte AtivoModel de volta para Map para o serviço de PDF legacy
              final itensMap = itensSnapshot.map((e) => e.toMap()..['patrimonio'] = e.patrimonio).toList();
              if (context.mounted) PdfService.exportarMapaAtivosSetor(setor: setor, itens: itensMap, context: context);
            },
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text("GERAR PDF"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AdminService service = AdminService();
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: service.getSetores(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final setores = snapshot.data!;
        return ListView.builder(
          itemCount: setores.length,
          itemBuilder: (context, index) {
            final s = setores[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListTile(
                leading: const Icon(Icons.location_on, color: Colors.blue),
                title: Text(s['nome'], style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.history, color: Colors.blue), onPressed: () => _abrirHistoricoSetor(context, s['nome']), tooltip: "Mapa do Setor"),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red), 
                      onPressed: () async {
                        final confirmar = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text("Excluir Setor"),
                            content: Text("Confirma a exclusão do setor '${s['nome']}'?"),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("CANCELAR")),
                              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("EXCLUIR", style: const TextStyle(color: Colors.red))),
                            ],
                          )
                        );
                        if (confirmar == true) await service.excluirSetor(s['id']);
                      }, 
                      tooltip: "Excluir Setor"
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _CasteloTab extends StatefulWidget {
  const _CasteloTab();
  @override
  State<_CasteloTab> createState() => _CasteloTabState();
}

class _CasteloTabState extends State<_CasteloTab> {
  final InventoryService _service = InventoryService();
  String _filtro = "";

  void _confirmarExclusao(BuildContext context, String pat) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Excluir do Castelo"),
        content: Text("Tem certeza que deseja remover o item $pat permanentemente?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCELAR")),
          ElevatedButton(onPressed: () async {
            await _service.excluirItemMestre(pat);
            if (context.mounted) Navigator.pop(ctx);
          }, style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), child: const Text("EXCLUIR")),
        ],
      ),
    );
  }

  void _editarCastelo(BuildContext context, AtivoModel item) {
    final processadorController = TextEditingController(text: item.processador);
    final macController = TextEditingController(text: item.macAddress);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Editar Ativo: ${item.patrimonio}"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: processadorController, decoration: const InputDecoration(labelText: "Processador", border: OutlineInputBorder())),
              const SizedBox(height: 15),
              TextField(controller: macController, decoration: const InputDecoration(labelText: "Endereço MAC", border: OutlineInputBorder())),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCELAR")),
          ElevatedButton(
            onPressed: () async {
              await _service.atualizarDadosCastelo(
                patrimonio: item.patrimonio,
                processador: processadorController.text.trim(),
                macAddress: macController.text.trim(),
              );
              if (context.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ativo atualizado!")));
              }
            },
            child: const Text("SALVAR"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            onChanged: (v) => setState(() => _filtro = v.toLowerCase()),
            decoration: const InputDecoration(hintText: "Buscar no Castelo...", prefixIcon: Icon(Icons.search), border: OutlineInputBorder()),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('inventario_mestre').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              var docs = snapshot.data!.docs;
              final itens = docs.map((d) => AtivoModel.fromMap(d.data() as Map<String, dynamic>, d.id)).toList();
              
              var filteredItens = itens;
              if (_filtro.isNotEmpty) {
                filteredItens = itens.where((i) => 
                  i.patrimonio.toLowerCase().contains(_filtro) || 
                  i.tipo.toLowerCase().contains(_filtro) || 
                  i.setor.toLowerCase().contains(_filtro)
                ).toList();
              }
              
              return ListView.builder(
                itemCount: filteredItens.length,
                itemBuilder: (context, index) {
                  final i = filteredItens[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: ListTile(
                      leading: const Icon(Icons.computer, color: Colors.blue),
                      title: Text("${i.tipo} - ${i.patrimonio}"),
                      subtitle: Text("Setor: ${i.setor}\nCPU: ${i.processador ?? '---'}"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.edit_note, color: Colors.indigo), onPressed: () => _editarCastelo(context, i), tooltip: "Editar"),
                          IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _confirmarExclusao(context, i.patrimonio), tooltip: "Excluir"),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _EmpresaTab extends StatefulWidget {
  const _EmpresaTab();
  @override
  State<_EmpresaTab> createState() => _EmpresaTabState();
}

class _EmpresaTabState extends State<_EmpresaTab> {
  final AdminService _service = AdminService();
  final TextEditingController nomeController = TextEditingController();
  final TextEditingController cnpjController = TextEditingController();
  final TextEditingController logoController = TextEditingController();
  final TextEditingController contatoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _carregarConfig();
  }

  void _carregarConfig() {
    _service.getConfigEmpresa().listen((doc) {
      if (doc.exists && mounted) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          nomeController.text = data['nome'] ?? '';
          cnpjController.text = data['cnpj'] ?? '';
          logoController.text = data['logo_url'] ?? '';
          contatoController.text = data['contato'] ?? '';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    String logoVisual = logoController.text;
    if (logoVisual.contains("drive.google.com")) {
      final fileId = RegExp(r"d/(.+)/").firstMatch(logoVisual)?.group(1) ?? RegExp(r"id=(.+)").firstMatch(logoVisual)?.group(1);
      if (fileId != null) logoVisual = "https://docs.google.com/uc?export=download&id=$fileId";
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text("Dados da Empresa para Relatórios", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          TextField(controller: nomeController, decoration: const InputDecoration(labelText: "Nome da Empresa", border: OutlineInputBorder())),
          const SizedBox(height: 15),
          TextField(controller: cnpjController, decoration: const InputDecoration(labelText: "CNPJ", border: OutlineInputBorder())),
          const SizedBox(height: 15),
          TextField(controller: logoController, decoration: const InputDecoration(labelText: "URL da Logo (PNG ou Google Drive)", border: OutlineInputBorder())),
          const SizedBox(height: 15),
          TextField(controller: contatoController, decoration: const InputDecoration(labelText: "Contato/Endereço", border: OutlineInputBorder())),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () async {
                await _service.salvarConfigEmpresa({
                  'nome': nomeController.text,
                  'cnpj': cnpjController.text,
                  'logo_url': logoController.text,
                  'contato': contatoController.text,
                });
                await _service.registrarLog(acao: "CONFIG EMPRESA", detalhes: "Alterou dados da empresa");
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Salvo com sucesso!")));
              },
              child: const Text("SALVAR BRANDING"),
            ),
          ),
          const SizedBox(height: 40),
          if (logoVisual.isNotEmpty)
            Column(
              children: [
                const Text("Prévia da Logo:", style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 10),
                Image.network(logoVisual, height: 100, errorBuilder: (context, error, stack) => const Icon(Icons.broken_image, size: 50, color: Colors.red)),
              ],
            ),
        ],
      ),
    );
  }
}

class _LocadorasTab extends StatelessWidget {
  const _LocadorasTab();
  @override
  Widget build(BuildContext context) {
    final AdminService service = AdminService();
    final TextEditingController controller = TextEditingController();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(child: TextField(controller: controller, decoration: const InputDecoration(labelText: "Nova Locadora", border: OutlineInputBorder()))),
              const SizedBox(width: 10),
              ElevatedButton(onPressed: () async {
                if (controller.text.isEmpty) return;
                await service.adicionarLocadora(controller.text.trim());
                await service.registrarLog(acao: "ADD LOCADORA", detalhes: "Adicionou locadora: ${controller.text}");
                controller.clear();
              }, child: const Icon(Icons.add)),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<String>>(
            stream: service.getLocadoras(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final list = snapshot.data!;
              return ListView.builder(
                itemCount: list.length,
                itemBuilder: (context, index) => ListTile(
                  title: Text(list[index]),
                  trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () async {
                    await service.excluirLocadora(list[index]);
                    await service.registrarLog(acao: "DEL LOCADORA", detalhes: "Excluiu locadora: ${list[index]}");
                  }),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
