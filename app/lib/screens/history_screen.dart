import 'package:flutter/material.dart';
import '../services/database_service.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  Color _tierColor(String tier) {
    switch (tier) { 
      case 'High': return const Color(0xFFD32F2F); 
      case 'Moderate': return const Color(0xFFF57C00); 
      default: return const Color(0xFF388E3C); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Scan History', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: DatabaseService.getAllResults(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snap.data ?? [];
          if (data.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_toggle_off, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('No scans yet.', style: TextStyle(color: Colors.grey.shade600, fontSize: 18)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: data.length,
            itemBuilder: (_, i) {
              final row = data[i];
              final tier = row['risk_tier'] as String;
              final date = DateTime.tryParse(row['timestamp'] as String)?.toLocal();
              final color = _tierColor(tier);

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: color.withOpacity(0.3), width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          tier == 'High' ? Icons.warning_rounded 
                          : tier == 'Moderate' ? Icons.info_outline_rounded 
                          : Icons.check_circle_outline_rounded,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Analysis Result', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text(
                                  date != null ? '${date.day.toString().padLeft(2,'0')}/${date.month.toString().padLeft(2,'0')}/${date.year}' : 'Unknown',
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$tier Risk',
                                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
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
}
