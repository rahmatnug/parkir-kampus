import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../../core/config/app_config.dart';

class UserHistoryPage extends StatefulWidget {
  const UserHistoryPage({super.key});

  @override
  State<UserHistoryPage> createState() => _UserHistoryPageState();
}

class _UserHistoryPageState extends State<UserHistoryPage> {
  bool _isLoading = true;
  List<dynamic> _history = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    try {
      final auth = context.read<AuthProvider>();
      final token = await auth.getToken();
      if (token == null) throw Exception("Tidak ada token");

      final res = await http.get(
        Uri.parse('${AppConfig.baseUrl}/api/v1/parking/history'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body)['data'] as List;
        setState(() {
          _history = data;
          _isLoading = false;
        });
      } else {
        throw Exception("Gagal memuat histori");
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Riwayat Parkir', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 18)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)), onPressed: () => Navigator.pop(context)),
        elevation: 0,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
        : _error != null
          ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
          : _history.isEmpty
            ? const Center(child: Text('Belum ada riwayat parkir', style: TextStyle(color: Color(0xFF64748B))))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _history.length,
                itemBuilder: (ctx, i) {
                  final tx = _history[i];
                  final isDone = tx['status'] != 'parkir';
                  final tMasuk = DateTime.parse(tx['waktu_masuk']).toLocal();
                  final tKeluar = tx['waktu_keluar'] != null ? DateTime.parse(tx['waktu_keluar']).toLocal() : null;
                  final fmt = DateFormat('dd MMM yyyy, HH:mm');

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(tx['slot']['zona']['nama_zona'] ?? 'Zona ?', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDone ? const Color(0xFFDCFCE7) : const Color(0xFFDBEAFE),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                tx['status'].toString().toUpperCase(),
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDone ? const Color(0xFF16A34A) : const Color(0xFF2563EB)),
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Plat: ${tx['kendaraan']?['nomor_polisi'] ?? '-'}', style: const TextStyle(fontSize: 13, color: Color(0xFF475569))),
                        const SizedBox(height: 4),
                        Text('Masuk: ${fmt.format(tMasuk)}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        if (tKeluar != null)
                          Text('Keluar: ${fmt.format(tKeluar)}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      ],
                    ),
                  );
                },
              )
    );
  }
}
