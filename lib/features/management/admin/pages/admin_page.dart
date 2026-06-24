import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_ronda_ti/features/system/auth/controllers/auth_controller.dart';
import 'package:smart_ronda_ti/features/management/admin/controllers/admin_controller.dart';
import 'package:smart_ronda_ti/features/operation/assets/controllers/asset_controller.dart';
import 'package:smart_ronda_ti/features/system/auth/models/user_model.dart';
import 'package:smart_ronda_ti/features/operation/assets/models/asset_model.dart';
import 'package:smart_ronda_ti/features/management/admin/pages/log_page.dart';
import 'package:smart_ronda_ti/features/management/reports/repositories/pdf_repository.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final AuthController _authController = AuthController();

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
              // Note: resetarInventarioMestre was removed or moved. 
              // Assuming for now it's not available or we need to implement it.
              // For now, I'll comment it out or leave as is if I find where it went.
              // Actually, AssetRepository doesn't have it yet.
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Função de reset em manutenção.")));
              Navigator.pop(ctx);
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
    return StreamBuilder<UserModel?>(
      stream: _authController.profileStream,
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

  void _alterarUsuario(BuildContext context, UserModel user) {
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
                final AuthController authController = AuthController();
                final AdminController adminController = AdminController();
                
                await authController.updateProfile(UserModel(
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
                
                await adminController.registerLog(action: "GESTÃO PERFIL", details: "Alterou perfil de ${user.nome}. Nível: $nivelSelecionado, Ativo: $ativo");
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text("SALVAR ALTERAÇÕES"),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarExclusao(BuildContext context, UserModel user, bool isMaster) {
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
              final AdminController controller = AdminController();
              await controller.suspendUser(user.uid, motivoController.text.trim());
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
                final AdminController controller = AdminController();
                await controller.removeUser(user.uid);
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
    final AdminController controller = AdminController();
    final AuthController authController = AuthController();
    
    return StreamBuilder<List<UserModel>>(
      stream: controller.usersStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final users = snapshot.data!;
        
        return StreamBuilder<UserModel?>(
          stream: authController.profileStream,
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
    final AssetController controller = AssetController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Mapa de Ativos - $setor"),
        content: SizedBox(
          width: 600,
          child: StreamBuilder<List<AssetModel>>(
            stream: controller.getSectorStream(setor),
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
              final itensSnapshot = await controller.getSectorStream(setor).first;
              // Converte AssetModel de volta para Map para o serviço de PDF legacy
              final itensMap = itensSnapshot.map((e) => e.toMap()..['patrimonio'] = e.patrimonio).toList();
              if (context.mounted) PdfRepository.exportarMapaAtivosSetor(setor: setor, itens: itensMap, context: context);
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
    final AdminController controller = AdminController();
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: controller.sectorsStream,
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
                              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("EXCLUIR", style: TextStyle(color: Colors.red))),
                            ],
                          )
                        );
                        if (confirmar == true) await controller.removeSector(s['id']);
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
  final AssetController _controller = AssetController();
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
            await _controller.removeAsset(pat);
            if (context.mounted) Navigator.pop(ctx);
          }, style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), child: const Text("EXCLUIR")),
        ],
      ),
    );
  }

  void _editarCastelo(BuildContext context, AssetModel item) {
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
              await _controller.updateAssetTechnicalData(
                patrimony: item.patrimonio,
                processor: processadorController.text.trim(),
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
              final itens = docs.map((d) => AssetModel.fromMap(d.data() as Map<String, dynamic>, d.id)).toList();
              
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
  final AdminController _controller = AdminController();
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
    _controller.brandingStream.listen((doc) {
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
                await _controller.updateCompanyBranding({
                  'nome': nomeController.text,
                  'cnpj': cnpjController.text,
                  'logo_url': logoController.text,
                  'contato': contatoController.text,
                });
                await _controller.registerLog(action: "CONFIG EMPRESA", details: "Alterou dados da empresa");
                if (!context.mounted) return;
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
    final AdminController controller = AdminController();
    final TextEditingController fieldController = TextEditingController();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(child: TextField(controller: fieldController, decoration: const InputDecoration(labelText: "Nova Locadora", border: OutlineInputBorder()))),
              const SizedBox(width: 10),
              ElevatedButton(onPressed: () async {
                if (fieldController.text.isEmpty) return;
                await controller.createLeasingCompany(fieldController.text.trim());
                await controller.registerLog(action: "ADD LOCADORA", details: "Adicionou locadora: ${fieldController.text}");
                fieldController.clear();
              }, child: const Icon(Icons.add)),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<String>>(
            stream: controller.leasingCompaniesStream,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final list = snapshot.data!;
              return ListView.builder(
                itemCount: list.length,
                itemBuilder: (context, index) => ListTile(
                  title: Text(list[index]),
                  trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () async {
                    await controller.removeLeasingCompany(list[index].toLowerCase());
                    await controller.registerLog(action: "DEL LOCADORA", details: "Excluiu locadora: ${list[index]}");
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
