import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/rendering.dart';
import 'package:smart_ronda_ti/core/services/rounds/ronda_service.dart';
import 'package:smart_ronda_ti/core/services/inventory/inventory_service.dart';
import 'package:smart_ronda_ti/core/services/admin/admin_service.dart';
import 'package:smart_ronda_ti/core/models/ronda_model.dart';
import 'package:smart_ronda_ti/core/models/ativo_model.dart';

class RondaPage extends StatefulWidget {
  final String setor;
  final String tecnico;
  final String tecnicoId;
  final String? rondaId;
  final List<Map<String, dynamic>>? equipamentosIniciais;

  const RondaPage({
    super.key,
    required this.setor,
    required this.tecnico,
    required this.tecnicoId,
    this.rondaId,
    this.equipamentosIniciais,
  });

  @override
  State<RondaPage> createState() => _RondaPageState();
}

class _RondaPageState extends State<RondaPage> {
  final TextEditingController patrimonioController = TextEditingController();
  final TextEditingController marcaController = TextEditingController();
  final TextEditingController modeloController = TextEditingController();
  final TextEditingController serieController = TextEditingController();
  final TextEditingController processadorController = TextEditingController();
  final TextEditingController macController = TextEditingController();
  final TextEditingController observacaoController = TextEditingController();
  final TextEditingController descricaoDefeitoController = TextEditingController();
  final TextEditingController motivoDivergenciaController = TextEditingController();

  final TextEditingController patrimonioAntigoController = TextEditingController();
  final TextEditingController patrimonioNovoController = TextEditingController();
  final TextEditingController motivoTrocaController = TextEditingController();

  final RondaService _rondaService = RondaService();
  final InventoryService _inventoryService = InventoryService();
  final AdminService _adminService = AdminService();

  String tipoEquipamento = 'Notebook';
  String statusOperacional = 'Em uso';
  bool possuiPatrimonio = true;
  bool carregador = false;
  bool mouse = false;
  bool teclado = false;
  bool monitor = false;
  bool defeito = false;
  bool isLocado = false;
  bool setorDivergente = false;
  String? locadoraSelecionada;
  bool houveTroca = false;
  bool buscandoInventario = false;

  List<AtivoModel> equipamentos = [];
  List<String> locadoras = [];
  DateTime horaRetirada = DateTime.now();
  DateTime horaInstalacao = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.equipamentosIniciais != null) {
      equipamentos = widget.equipamentosIniciais!.map((e) => AtivoModel.fromMap(e, e['patrimonio'] ?? '')).toList();
    }
    _carregarLocadoras();
  }

  Future<void> _carregarLocadoras() async {
    _adminService.getLocadoras().listen((lista) {
      if (mounted) setState(() => locadoras = lista);
    });
  }

  @override
  void dispose() {
    patrimonioController.dispose();
    marcaController.dispose();
    modeloController.dispose();
    serieController.dispose();
    processadorController.dispose();
    macController.dispose();
    observacaoController.dispose();
    descricaoDefeitoController.dispose();
    motivoDivergenciaController.dispose();
    patrimonioAntigoController.dispose();
    patrimonioNovoController.dispose();
    motivoTrocaController.dispose();
    super.dispose();
  }

  Future<void> _verificarInventario(String valor) async {
    if (valor.length < 3) return;

    setState(() => buscandoInventario = true);
    final AtivoModel? dados = await _inventoryService.buscarNoInventario(valor);
    setState(() => buscandoInventario = false);

    if (dados != null) {
      if (dados.semPatrimonio && possuiPatrimonio) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("✨ VINCULANDO PLACA: Este item não tinha patrimônio e será atualizado agora."),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }

      if (dados.statusOperacional == 'Em manutenção') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("⚠️ ITEM EM MANUTENÇÃO! Ao adicionar, o status voltará para 'Em uso'."),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        setState(() => statusOperacional = 'Em uso');
      }

      if (dados.setor != widget.setor) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Atenção: Item pertence ao setor ${dados.setor}. Ao salvar, ele será transferido para ${widget.setor}."),
              backgroundColor: Colors.orange.shade900,
              duration: const Duration(seconds: 5),
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(label: 'X', textColor: Colors.white, onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar()),
            ),
          );
        }
      }

      setState(() {
        tipoEquipamento = dados.tipo;
        marcaController.text = dados.marca;
        modeloController.text = dados.modelo;
        serieController.text = dados.serie;
        processadorController.text = dados.processador ?? "";
        macController.text = dados.macAddress ?? "";
        isLocado = dados.isLocado;
        locadoraSelecionada = dados.locadora;
      });
    }
  }

  void _mostrarQRCode(BuildContext context, String patrimonio) {
    final GlobalKey globalKey = GlobalKey();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("QR Code - $patrimonio"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RepaintBoundary(
              key: globalKey,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(15),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    QrImageView(
                      data: patrimonio,
                      version: QrVersions.auto,
                      size: 180.0,
                    ),
                    const SizedBox(height: 5),
                    Text(patrimonio, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black)),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              try {
                RenderRepaintBoundary boundary = globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
                ui.Image image = await boundary.toImage(pixelRatio: 3.0);
                var byteData = await image.toByteData(format: ui.ImageByteFormat.png);
                var pngBytes = byteData!.buffer.asUint8List();

                final tempDir = await getTemporaryDirectory();
                final file = await File('${tempDir.path}/qr_$patrimonio.png').create();
                await file.writeAsBytes(pngBytes);

                await Share.shareXFiles([XFile(file.path)], text: 'QR Code Patrimônio $patrimonio');
              } catch (e) {
                debugPrint("Erro ao gerar imagem QR: $e");
              }
            },
            child: const Text("COMPARTILHAR / IMPRIMIR"),
          ),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Fechar")),
        ],
      ),
    );
  }

  Future<void> _abrirLeitorQR() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(10))),
            const Padding(
              padding: EdgeInsets.all(15.0),
              child: Text("Aponte para o QR Code do Patrimônio", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: MobileScanner(
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    if (barcodes.isNotEmpty) {
                      final String code = barcodes.first.rawValue ?? "";
                      if (mounted) {
                        Navigator.of(context).pop();
                        setState(() {
                          patrimonioController.text = code;
                        });
                        _verificarInventario(code);
                      }
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _abrirBuscaInventario() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(width: 40, height: 5, decoration: const BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.all(Radius.circular(10)))),
            const Padding(
              padding: EdgeInsets.all(15.0),
              child: Text("Busca Rápida no Inventário", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Digite patrimônio, série ou modelo...",
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('inventario_mestre').limit(50).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final docs = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final item = docs[index].data() as Map<String, dynamic>;
                      final pat = docs[index].id;
                      return ListTile(
                        leading: const Icon(Icons.computer, color: Colors.blue),
                        title: Text("Pat: $pat - ${item['tipo']}"),
                        subtitle: Text("${item['marca'] ?? ''} ${item['modelo'] ?? ''} (S/N: ${item['serie'] ?? ''})"),
                        onTap: () {
                          Navigator.pop(context);
                          setState(() {
                            patrimonioController.text = pat;
                            possuiPatrimonio = !pat.toLowerCase().contains("sem patrimônio");
                          });
                          _verificarInventario(pat);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selecionarHora(BuildContext context, bool isRetirada) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(isRetirada ? horaRetirada : horaInstalacao),
    );

    if (pickedTime != null) {
      if (!context.mounted) return;
      final DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: isRetirada ? horaRetirada : horaInstalacao,
        firstDate: DateTime(2000),
        lastDate: DateTime(2101),
      );

      if (pickedDate != null && mounted) {
        setState(() {
          final novaData = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute);
          if (isRetirada) {
            horaRetirada = novaData;
          } else {
            horaInstalacao = novaData;
          }
        });
      }
    }
  }

  void adicionarEquipamento() {
    if (patrimonioController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro: O Patrimônio é obrigatório'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
      );
      return;
    }

    if (defeito && descricaoDefeitoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro: Descreva o defeito'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
      );
      return;
    }

    setState(() {
      equipamentos.insert(0, AtivoModel(
        tipo: tipoEquipamento,
        patrimonio: possuiPatrimonio ? patrimonioController.text.trim() : "SEM PATRIMÔNIO",
        marca: marcaController.text.trim(),
        modelo: modeloController.text.trim(),
        serie: serieController.text.trim(),
        processador: processadorController.text.trim(),
        macAddress: macController.text.trim(),
        isLocado: isLocado,
        locadora: isLocado ? locadoraSelecionada : null,
        statusOperacional: statusOperacional,
        setorDivergente: setorDivergente,
        motivoDivergencia: setorDivergente ? motivoDivergenciaController.text.trim() : null,
        temDefeito: defeito,
        descricaoDefeito: defeito ? descricaoDefeitoController.text.trim() : null,
        setor: widget.setor,
        status: 'Ativo'
      ));

      patrimonioController.clear();
      marcaController.clear();
      modeloController.clear();
      serieController.clear();
      processadorController.clear();
      macController.clear();
      observacaoController.clear();
      descricaoDefeitoController.clear();
      carregador = false;
      mouse = false;
      teclado = false;
      monitor = false;
      defeito = false;
      isLocado = false;
      possuiPatrimonio = true;
      setorDivergente = false;
      locadoraSelecionada = null;
      statusOperacional = 'Em uso';
      motivoDivergenciaController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Adicionado à lista!'), duration: Duration(seconds: 1), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> finalizarRonda() async {
    if (equipamentos.isEmpty && !houveTroca) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adicione pelo menos um item ou registre uma troca'), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      int defeitos = equipamentos.where((e) => e.temDefeito).length;
      int alugados = equipamentos.where((e) => e.isLocado).length;

      Map<String, dynamic>? dadosTroca;
      if (houveTroca) {
        dadosTroca = {
          'tipo': 'TROCA DE EQUIPAMENTO',
          'patrimonio_antigo': patrimonioAntigoController.text.trim(),
          'patrimonio_novo': patrimonioNovoController.text.trim(),
          'hora_retirada': horaRetirada.toIso8601String(),
          'hora_instalacao': horaInstalacao.toIso8601String(),
          'motivo': motivoTrocaController.text.trim(),
        };
      }

      await _rondaService.salvarRondaCompleta(
        rondaExistenteId: widget.rondaId,
        ronda: RondaModel(
          dataInicio: DateTime.now(),
          setor: widget.setor,
          tecnico: widget.tecnico,
          tecnicoId: widget.tecnicoId,
          itensTotal: equipamentos.length,
          trocasTotal: houveTroca ? 1 : 0,
          defeitosTotal: defeitos,
          alugadosTotal: alugados,
        ),
        equipamentos: equipamentos,
        dadosTroca: dadosTroca,
      );

      await _adminService.registrarLog(acao: widget.rondaId != null ? "ATUALIZAR RONDA" : "FINALIZAR RONDA", detalhes: "Salvou ronda no setor ${widget.setor}. Itens: ${equipamentos.length}, Defeitos: $defeitos");

      if (!mounted) return;
      Navigator.pop(context);
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ronda processada!'), duration: Duration(seconds: 1), behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao salvar: $e'), behavior: SnackBarBehavior.floating));
    }
  }

  void _editarItem(int index) {
    final item = equipamentos[index];
    setState(() {
      tipoEquipamento = item.tipo;
      patrimonioController.text = item.patrimonio == "SEM PATRIMÔNIO" ? "" : item.patrimonio;
      possuiPatrimonio = item.patrimonio != "SEM PATRIMÔNIO";
      marcaController.text = item.marca;
      modeloController.text = item.modelo;
      serieController.text = item.serie;
      processadorController.text = item.processador ?? "";
      macController.text = item.macAddress ?? "";
      descricaoDefeitoController.text = item.descricaoDefeito ?? "";
      defeito = item.temDefeito;
      isLocado = item.isLocado;
      locadoraSelecionada = item.locadora;
      setorDivergente = item.setorDivergente;
      motivoDivergenciaController.text = item.motivoDivergencia ?? "";
      equipamentos.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Item carregado para edição"), duration: Duration(seconds: 1), behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.rondaId != null ? 'Editando Ronda - ${widget.setor}' : 'Ronda - ${widget.setor}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dados do Equipamento', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: tipoEquipamento,
                    decoration: const InputDecoration(labelText: 'Tipo', border: OutlineInputBorder()),
                    items: const ['Notebook', 'Desktop', 'Telefone', 'Smartphone', 'Impressora', 'TV', 'No-Break', 'Switch', 'Tablet', 'Leitor', 'Roteador', 'Access Point', 'Outro'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) => setState(() => tipoEquipamento = v!),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: statusOperacional,
                    decoration: const InputDecoration(labelText: 'Status Op.', border: OutlineInputBorder()),
                    items: const ['Em uso', 'Reservado', 'Em manutenção', 'Descartado'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) => setState(() => statusOperacional = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text("Possui Patrimônio?", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 10),
                Switch(
                  value: possuiPatrimonio,
                  onChanged: (v) => setState(() {
                    possuiPatrimonio = v;
                    if (!v) {
                      patrimonioController.text = "SEM PATRIMÔNIO";
                    } else {
                      patrimonioController.clear();
                    }
                  }),
                )
              ],
            ),
            const SizedBox(height: 10),
            Autocomplete<String>(
              optionsBuilder: (textValue) async {
                if (textValue.text.isEmpty || !possuiPatrimonio) return const Iterable<String>.empty();
                final snap = await FirebaseFirestore.instance.collection('inventario_mestre').where(FieldPath.documentId, isGreaterThanOrEqualTo: textValue.text).where(FieldPath.documentId, isLessThanOrEqualTo: '${textValue.text}\uf8ff').limit(5).get();
                return snap.docs.map((doc) => doc.id);
              },
              onSelected: (sel) {
                patrimonioController.text = sel;
                _verificarInventario(sel);
              },
              fieldViewBuilder: (ctx, ctrl, fNode, onSub) {
                if (patrimonioController.text.isNotEmpty && ctrl.text.isEmpty) ctrl.text = patrimonioController.text;
                return TextField(
                  controller: ctrl,
                  focusNode: fNode,
                  enabled: possuiPatrimonio,
                  decoration: InputDecoration(
                    labelText: possuiPatrimonio ? 'Nº Patrimônio *' : 'ITEM SEM PLACA',
                    border: const OutlineInputBorder(),
                    prefixIcon: IconButton(icon: const Icon(Icons.qr_code_scanner, color: Colors.blue), onPressed: possuiPatrimonio ? _abrirLeitorQR : null),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: Icon(buscandoInventario ? Icons.hourglass_empty : Icons.search), onPressed: _abrirBuscaInventario),
                        IconButton(
                          icon: const Icon(Icons.check),
                          onPressed: () {
                            patrimonioController.text = ctrl.text;
                            _verificarInventario(ctrl.text);
                          },
                        ),
                      ],
                    ),
                  ),
                  onChanged: (v) {
                    patrimonioController.text = v;
                    if (possuiPatrimonio && v.length >= 3) _verificarInventario(v);
                  },
                );
              },
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: TextField(controller: marcaController, decoration: const InputDecoration(labelText: 'Marca (Opcional)', border: OutlineInputBorder()))),
                const SizedBox(width: 10),
                Expanded(child: TextField(controller: modeloController, decoration: const InputDecoration(labelText: 'Modelo (Opcional)', border: OutlineInputBorder()))),
              ],
            ),
            const SizedBox(height: 10),
            TextField(controller: serieController, decoration: const InputDecoration(labelText: 'Nº Série (Opcional)', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: macController, decoration: const InputDecoration(labelText: 'Endereço MAC (Opcional)', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            if (tipoEquipamento == 'Notebook' || tipoEquipamento == 'Desktop') ...[
              TextField(controller: processadorController, decoration: const InputDecoration(labelText: 'Processador (i5, i7, Ryzen...)', border: OutlineInputBorder())),
              const SizedBox(height: 10),
            ],
            Wrap(
              spacing: 10,
              children: [
                FilterChip(label: const Text('Carregador'), selected: carregador, onSelected: (v) => setState(() => carregador = v)),
                FilterChip(label: const Text('Mouse'), selected: mouse, onSelected: (v) => setState(() => mouse = v)),
                FilterChip(label: const Text('Teclado'), selected: teclado, onSelected: (v) => setState(() => teclado = v)),
                FilterChip(label: const Text('Monitor'), selected: monitor, onSelected: (v) => setState(() => monitor = v)),
                FilterChip(label: const Text('Defeito'), selected: defeito, selectedColor: Colors.red.withAlpha(80), onSelected: (v) => setState(() => defeito = v)),
                FilterChip(label: const Text('Locado?'), selected: isLocado, selectedColor: Colors.orange.withAlpha(80), onSelected: (v) => setState(() => isLocado = v)),
                FilterChip(label: const Text('Em outro setor?'), selected: setorDivergente, selectedColor: Colors.purple.withAlpha(80), onSelected: (v) => setState(() => setorDivergente = v)),
              ],
            ),
            if (setorDivergente) ...[const SizedBox(height: 10), TextField(controller: motivoDivergenciaController, decoration: const InputDecoration(labelText: 'Motivo/Setor Atual *', border: OutlineInputBorder(), hintText: 'Ex: Emprestado para a Recepção...'))],
            if (defeito) ...[const SizedBox(height: 10), TextField(controller: descricaoDefeitoController, decoration: const InputDecoration(labelText: 'Descrição do Defeito *', border: OutlineInputBorder(), hintText: 'Ex: Tela quebrada, não liga...'))],
            if (isLocado) ...[
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: locadoraSelecionada,
                decoration: const InputDecoration(labelText: 'Empresa Locadora', border: OutlineInputBorder()),
                items: locadoras.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) => setState(() => locadoraSelecionada = v),
              )
            ],
            TextField(controller: observacaoController, decoration: const InputDecoration(labelText: 'Observações')),
            const SizedBox(height: 15),
            Center(child: ElevatedButton.icon(onPressed: adicionarEquipamento, style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700, foregroundColor: Colors.white, minimumSize: const Size(200, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), icon: const Icon(Icons.add_circle_outline), label: const Text('ADICIONAR ITEM', style: TextStyle(fontWeight: FontWeight.bold)))),
            const Divider(height: 40),
            if (equipamentos.isNotEmpty) ...[
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Itens na Ronda (${equipamentos.length}):', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), TextButton(onPressed: () => setState(() => equipamentos.clear()), child: const Text('Limpar Tudo', style: TextStyle(color: Colors.red)))]),
              ...equipamentos.asMap().entries.map((e) {
                String descExtra = "";
                if (e.value.marca.isNotEmpty == true) descExtra += "Marca: ${e.value.marca} ";
                if (e.value.modelo.isNotEmpty == true) descExtra += "Mod: ${e.value.modelo} ";
                if (e.value.serie.isNotEmpty == true) descExtra += "S/N: ${e.value.serie}";
                return Card(elevation: 2, margin: const EdgeInsets.symmetric(vertical: 4), child: ListTile(leading: CircleAvatar(backgroundColor: e.value.temDefeito ? Colors.red.shade100 : Colors.green.shade100, child: Icon(e.value.temDefeito ? Icons.error_outline : Icons.check_circle_outline, color: e.value.temDefeito ? Colors.red : Colors.green)), title: Text('${e.value.tipo} - ${e.value.patrimonio}', style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [if (descExtra.isNotEmpty) Text(descExtra, style: const TextStyle(fontSize: 12, color: Colors.blueGrey))]), trailing: Row(mainAxisSize: MainAxisSize.min, children: [IconButton(icon: const Icon(Icons.edit, color: Colors.orange, size: 22), onPressed: () => _editarItem(e.key), tooltip: 'Editar Item'), IconButton(icon: const Icon(Icons.qr_code, color: Colors.blue, size: 22), onPressed: () => _mostrarQRCode(context, e.value.patrimonio), tooltip: 'Gerar QR Code'), IconButton(icon: const Icon(Icons.delete_forever, color: Colors.grey), onPressed: () => setState(() => equipamentos.removeAt(e.key)))])));
              }),
            ],
            const Divider(height: 40),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.orange.withAlpha(15), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange.withAlpha(50))),
              child: Column(
                children: [
                  CheckboxListTile(title: const Text('Houve Troca de Equipamento?', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)), value: houveTroca, activeColor: Colors.orange, onChanged: (v) => setState(() => houveTroca = v!)),
                  if (houveTroca) ...[
                    const SizedBox(height: 10),
                    TextField(controller: patrimonioAntigoController, decoration: const InputDecoration(labelText: 'Patrimônio Antigo', border: OutlineInputBorder())),
                    const SizedBox(height: 10),
                    TextField(controller: patrimonioNovoController, decoration: const InputDecoration(labelText: 'Patrimônio Novo', border: OutlineInputBorder())),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: OutlinedButton.icon(onPressed: () => _selecionarHora(context, true), icon: const Icon(Icons.calendar_today), label: Text('Retirada: ${horaRetirada.toString().substring(11, 16)}'))),
                        const SizedBox(width: 8),
                        Expanded(child: OutlinedButton.icon(onPressed: () => _selecionarHora(context, false), icon: const Icon(Icons.calendar_today), label: Text('Instal.: ${horaInstalacao.toString().substring(11, 16)}'))),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(controller: motivoTrocaController, decoration: const InputDecoration(labelText: 'Motivo da Troca', border: OutlineInputBorder())),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: finalizarRonda,
              style: ElevatedButton.styleFrom(backgroundColor: widget.rondaId != null ? Colors.orange : Colors.green, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 60)),
              child: Text(widget.rondaId != null ? 'ATUALIZAR RONDA' : 'FINALIZAR RONDA', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
