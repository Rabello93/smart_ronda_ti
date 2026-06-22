import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/rendering.dart';
import 'package:smart_ronda_ti/core/services/rounds/ronda_service.dart';

class RondaDetailsPage extends StatelessWidget {
  final Map<String, dynamic> ronda;
  const RondaDetailsPage({super.key, required this.ronda});

  @override
  Widget build(BuildContext context) {
    final String data = ronda['data_inicio'] != null 
        ? ronda['data_inicio'].toString().substring(0, 16).replaceAll('T', ' ')
        : 'Sem data';

    final RondaService rondaService = RondaService();

    return Scaffold(
      appBar: AppBar(title: Text("Detalhes: ${ronda['setor']}")),
      body: Column(
        children: [
          _buildHeader(data),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: rondaService.getEquipamentosDaRonda(ronda['id_documento']),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                final equips = snapshot.data ?? [];
                
                return ListView.builder(
                  itemCount: equips.length,
                  itemBuilder: (context, index) {
                    final e = equips[index];
                    final bool isDefeito = e['status'] == 'Defeito' || e['tem_defeito'] == true;
                    final bool isTroca = e['is_troca'] == true;

                    if (isTroca) {
                      return Card(
                        color: Colors.orange.shade50,
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ListTile(
                          leading: const Icon(Icons.swap_horiz, color: Colors.orange),
                          title: const Text("TROCA DE EQUIPAMENTO", style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("Antigo: ${e['patrimonio_antigo']}\nNovo: ${e['patrimonio_novo']}\nMotivo: ${e['motivo']}"),
                        ),
                      );
                    }

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        leading: Icon(isDefeito ? Icons.error_outline : Icons.check_circle_outline, color: isDefeito ? Colors.red : Colors.green),
                        title: Text("${e['tipo']} - ${e['patrimonio']}"),
                        subtitle: Text("S/N: ${e['serie'] ?? '---'} | CPU: ${e['processador'] ?? '---'}"),
                        trailing: IconButton(
                          icon: const Icon(Icons.qr_code, color: Colors.blue),
                          onPressed: () => _mostrarQRCode(context, e['patrimonio'] ?? "S/P"),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      color: Colors.blue.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Setor: ${ronda['setor']}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text("Técnico: ${ronda['tecnico']}"),
          Text("Data/Hora: $data"),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStat("Itens", ronda['itens_total'].toString()),
              _buildStat("Defeitos", ronda['defeitos_total'].toString()),
              _buildStat("Trocas", ronda['trocas_total'].toString()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
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
                debugPrint("Erro imagem QR: $e");
              }
            },
            child: const Text("COMPARTILHAR / IMPRIMIR"),
          ),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Fechar")),
        ],
      ),
    );
  }
}
