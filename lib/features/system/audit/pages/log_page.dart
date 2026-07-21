import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_ronda_ti/features/management/admin/controllers/admin_controller.dart';
import 'package:smart_ronda_ti/features/management/reports/repositories/report_repository.dart';

import 'package:smart_ronda_ti/app/theme.dart';

class LogPage extends StatelessWidget {
  const LogPage({super.key});

  @override
  Widget build(BuildContext context) {
    final AdminController controller = AdminController();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Logs de Auditoria"),
        backgroundColor: Colors.indigo.shade900,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () => ReportRepository.exportarLogsParaPDF(context),
            tooltip: "Exportar logs para PDF",
          )
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: controller.logsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text("Erro: ${snapshot.error}"));
          
          final logs = snapshot.data ?? [];

          if (logs.isEmpty) return const Center(child: Text("Nenhum log registrado ainda."));

          return ListView.builder(
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              final DateTime date = (log['timestamp'] != null) 
                  ? (log['timestamp'] as dynamic).toDate() 
                  : DateTime.now();
              
              final String dataFormatada = DateFormat('dd/MM/yyyy HH:mm').format(date);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.terminal_rounded, size: 20),
                  ),
                  title: Text(
                    log['acao'], 
                    style: AppTheme.monoStyle(fontWeight: FontWeight.w900, fontSize: 13)
                  ),
                  subtitle: Text(
                    "DATA: $dataFormatada\nUSUÁRIO: ${log['tecnico_nome']}\nDETALHES: ${log['detalhes']}", 
                    style: const TextStyle(fontSize: 11)
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
