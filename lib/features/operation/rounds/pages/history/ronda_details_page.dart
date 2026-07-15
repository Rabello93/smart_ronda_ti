import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:flutter/rendering.dart';
import 'package:smart_ronda_ti/features/operation/rounds/controllers/round_controller.dart';
import 'package:smart_ronda_ti/features/operation/assets/models/asset_model.dart';

class RondaDetailsPage extends StatelessWidget {
  final Map<String, dynamic> ronda;
  const RondaDetailsPage({super.key, required this.ronda});

  @override
  Widget build(BuildContext context) {
    final String data = ronda['data_inicio'] != null 
        ? ronda['data_inicio'].toString().substring(0, 16).replaceAll('T', ' ')
        : 'Sem data';

    final RoundController roundController = RoundController();

    return Scaffold(
      appBar: AppBar(title: Text("Detalhes: ${ronda['setor']}")),
      body: Column(
        children: [
          _buildHeader(data),
          Expanded(
            child: FutureBuilder<List<AssetModel>>(
              future: roundController.getRoundAssets(ronda['id_documento']),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                final equips = snapshot.data ?? [];
                
                return ListView.builder(
                  itemCount: equips.length,
                  itemBuilder: (context, index) {
                    final e = equips[index];
                    final bool isDefeito = e.status == 'Defeito' || e.temDefeito == true;
                    // Note: 'is_troca' doesn't exist in AtivoModel, but RondaService filters them out in getEquipamentosDaRonda.
                    // If special handling for 'is_troca' is needed, getEquipamentosDaRonda would need to be changed back or AtivoModel updated.
                    // Based on my previous change to RondaService, 'is_troca' items are FILTERED OUT.

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        leading: Icon(isDefeito ? Icons.error_outline : Icons.check_circle_outline, color: isDefeito ? Colors.red : Colors.green),
                        title: Text("${e.tipo} - ${e.patrimonio}"),
                        subtitle: Text("S/N: ${e.serie} | CPU: ${e.processador ?? '---'}"),
                        trailing: IconButton(
                          icon: const Icon(Icons.qr_code, color: Colors.blue),
                          onPressed: () => _mostrarQRCode(context, e.patrimonio),
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

                final pdf = pw.Document();
                pdf.addPage(
                  pw.Page(
                    pageFormat: PdfPageFormat.a6,
                    build: (pw.Context context) {
                      return pw.Center(
                        child: pw.Column(
                          mainAxisAlignment: pw.MainAxisAlignment.center,
                          children: [
                            pw.Image(pw.MemoryImage(pngBytes), height: 300),
                            pw.SizedBox(height: 20),
                            pw.Text(patrimonio, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                          ],
                        ),
                      );
                    },
                  ),
                );

                final tempDir = await getTemporaryDirectory();
                final file = await File('${tempDir.path}/qr_$patrimonio.pdf').create();
                await file.writeAsBytes(await pdf.save());

                await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], text: 'QR Code Patrimônio $patrimonio (PDF)'));
              } catch (e) {
                debugPrint("Erro ao gerar PDF do QR: $e");
              }
            },
            child: const Text("COMPARTILHAR (PDF)"),
          ),
          TextButton(
            onPressed: () async {
              try {
                RenderRepaintBoundary boundary = globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
                ui.Image image = await boundary.toImage(pixelRatio: 3.0);
                var byteData = await image.toByteData(format: ui.ImageByteFormat.png);
                var pngBytes = byteData!.buffer.asUint8List();

                img.Image? decodedImage = img.decodePng(pngBytes);
                if (decodedImage != null) {
                  var jpgImage = img.Image(width: decodedImage.width, height: decodedImage.height)
                    ..clear(img.ColorRgb8(255, 255, 255));
                  img.compositeImage(jpgImage, decodedImage);
                  var jpgBytes = img.encodeJpg(jpgImage, quality: 100);

                  final result = await ImageGallerySaverPlus.saveImage(
                    Uint8List.fromList(jpgBytes),
                    quality: 100,
                    name: "qr_$patrimonio",
                  );

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(result['isSuccess'] ? "Salvo na galeria!" : "Erro ao salvar"),
                        backgroundColor: result['isSuccess'] ? Colors.green : Colors.red,
                      ),
                    );
                  }
                }
              } catch (e) {
                debugPrint("Erro ao salvar QR: $e");
              }
            },
            child: const Text("SALVAR NA GALERIA"),
          ),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Fechar")),
        ],
      ),
    );
  }
}
