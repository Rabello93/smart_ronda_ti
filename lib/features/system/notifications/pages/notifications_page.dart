import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_ronda_ti/app/theme.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.deepNavy : AppTheme.coolGrey,
      appBar: AppBar(
        title: Text("ALERTAS DO SISTEMA", style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1)),
        backgroundColor: isDark ? AppTheme.deepNavy : Colors.white,
        foregroundColor: isDark ? Colors.white : AppTheme.deepNavy,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('logs')
            .orderBy('timestamp', descending: true)
            .limit(50)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_rounded, size: 80, color: isDark ? Colors.white10 : Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text("NENHUMA ATIVIDADE RECENTE", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
                ],
              ),
            );
          }

          final logs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index].data() as Map<String, dynamic>;
              final DateTime timestamp = (log['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
              final String action = log['acao'] ?? "SISTEMA";
              final String details = log['detalhes'] ?? "---";
              final String user = log['tecnico_nome'] ?? "Admin";

              final Color color = _getLogColor(action);

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.charcoal : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withValues(alpha: 0.1)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(_getLogIcon(action), color: color, size: 22),
                  ),
                  title: Text(
                    action, 
                    style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5)
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      Text(
                        details, 
                        style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87)
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              user.toUpperCase(), 
                              style: AppTheme.monoStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.blueGrey)
                            ),
                          ),
                          Text(
                            DateFormat('dd/MM HH:mm').format(timestamp),
                            style: AppTheme.monoStyle(fontSize: 9, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getLogColor(String action) {
    if (action.contains("ERRO")) return Colors.red;
    if (action.contains("ADD") || action.contains("CRIOU")) return Colors.green;
    if (action.contains("DEL") || action.contains("EXCLUIU")) return Colors.orange;
    if (action.contains("RONDA")) return Colors.blue;
    return Colors.indigo;
  }

  IconData _getLogIcon(String action) {
    if (action.contains("ERRO")) return Icons.error_outline;
    if (action.contains("ADD")) return Icons.add_circle_outline;
    if (action.contains("DEL")) return Icons.delete_outline;
    if (action.contains("RONDA")) return Icons.assignment_outlined;
    return Icons.info_outline;
  }
}
