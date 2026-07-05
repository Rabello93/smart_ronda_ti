import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notificações do Sistema"),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
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
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("Nenhuma notificação recente.", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final logs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index].data() as Map<String, dynamic>;
              final DateTime timestamp = (log['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
              final String action = log['acao'] ?? "SISTEMA";
              final String details = log['detalhes'] ?? "---";
              final String user = log['tecnico_nome'] ?? "Admin";

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getLogColor(action).withValues(alpha: 0.1),
                    child: Icon(_getLogIcon(action), color: _getLogColor(action)),
                  ),
                  title: Text(action, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(details),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(user, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.blueGrey)),
                          Text(
                            DateFormat('dd/MM/yy HH:mm').format(timestamp),
                            style: const TextStyle(fontSize: 10, color: Colors.grey),
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
