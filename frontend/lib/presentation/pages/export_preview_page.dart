import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// ─── Design tokens (local) ────────────────────────────────────────────────────
const _kBlue   = Color(0xFF1E3FAE);
const _kBg     = Color(0xFFF6F6F8);
const _kBorder = Color(0xFFE8EAF0);
const _kText   = Color(0xFF0F172A);
const _kMuted  = Color(0xFF64748B);
const _kGreen  = Color(0xFF16A34A);
const _kOrange = Color(0xFFF59E0B);

// ─── PDF color helpers ────────────────────────────────────────────────────────
const _pdfBlue   = PdfColor.fromInt(0xFF1E3FAE);
const _pdfGray   = PdfColor.fromInt(0xFF475569);
const _pdfGreen  = PdfColor.fromInt(0xFF16A34A);
const _pdfOrange = PdfColor.fromInt(0xFFF59E0B);
const _pdfBg     = PdfColor.fromInt(0xFFF8F9FB);

// ─── Page widget ──────────────────────────────────────────────────────────────
class ExportPreviewPage extends StatefulWidget {
  final List<dynamic> activities;
  const ExportPreviewPage({super.key, required this.activities});

  @override
  State<ExportPreviewPage> createState() => _ExportPreviewPageState();
}

class _ExportPreviewPageState extends State<ExportPreviewPage> {
  bool _generating = false;

  // ─── Build PDF ──────────────────────────────────────────────────────────────
  Future<Uint8List> _buildPdf(PdfPageFormat fmt) async {
    final doc = pw.Document(title: 'Laporan Aktivitas Parkir - PARKIRKAMPUS');

    // ── Zone bar-chart data (aggregate from real activities) ──────────────────
    final Map<String, int> zoneMotor = {};
    final Map<String, int> zoneMobil = {};
    for (final a in widget.activities) {
      final zone  = a['zona'] ?? 'Lainnya';
      final role  = a['role'] ?? '';
      final motor = role == 'mahasiswa';
      if (motor) {
        zoneMotor[zone] = (zoneMotor[zone] ?? 0) + 1;
      } else {
        zoneMobil[zone] = (zoneMobil[zone] ?? 0) + 1;
      }
    }
    final allZones = {...zoneMotor.keys, ...zoneMobil.keys}.toList()..sort();
    if (allZones.isEmpty) allZones.add('—');

    final int maxCount = allZones
        .map((z) => (zoneMotor[z] ?? 0) + (zoneMobil[z] ?? 0))
        .fold(0, (a, b) => a > b ? a : b);

    // ── Summary numbers ───────────────────────────────────────────────────────
    final parked   = widget.activities.where((a) => a['status'] == 'parkir').length;
    final exited   = widget.activities.where((a) => a['status'] == 'selesai').length;
    final overstay = widget.activities.where((a) => a['status'] == 'overstay').length;
    final total    = widget.activities.length;

    doc.addPage(
      pw.MultiPage(
        pageFormat: fmt,
        margin: const pw.EdgeInsets.all(36),
        header: (ctx) => _buildHeader(ctx),
        footer: (ctx) => _buildFooter(ctx),
        build: (ctx) => [
          // ── Capacity info row ──────────────────────────────────────────────
          pw.SizedBox(height: 20),
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: const pw.BoxDecoration(
              color: _pdfBg,
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _InfoChip(label: 'Total Aktivitas', value: '$total'),
                _InfoChip(label: 'Sedang Parkir', value: '$parked', color: _pdfGreen),
                _InfoChip(label: 'Sudah Keluar', value: '$exited', color: _pdfGray),
                _InfoChip(label: 'Overstay', value: '$overstay', color: _pdfOrange),
                _InfoChip(label: 'Occupancy', value: '85%', color: _pdfBlue),
              ],
            ),
          ),
          pw.SizedBox(height: 24),

          // ── Bar chart title ────────────────────────────────────────────────
          pw.Text('OCCUPANCY PER ZONE',
              style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: _pdfGray,
                  letterSpacing: 0.8)),
          pw.SizedBox(height: 12),

          // ── Legend ────────────────────────────────────────────────────────
          pw.Row(children: [
            pw.Container(width: 10, height: 10, color: _pdfBlue),
            pw.SizedBox(width: 4),
            pw.Text('Motor', style: const pw.TextStyle(fontSize: 9, color: _pdfGray)),
            pw.SizedBox(width: 12),
            pw.Container(
                width: 10,
                height: 10,
                color: const PdfColor.fromInt(0xFFBBC4F5)),
            pw.SizedBox(width: 4),
            pw.Text('Mobil', style: const pw.TextStyle(fontSize: 9, color: _pdfGray)),
          ]),
          pw.SizedBox(height: 10),

          // ── Bar chart ──────────────────────────────────────────────────────
          pw.Container(
            height: 160,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(
                  color: const PdfColor.fromInt(0xFFE8EAF0), width: 0.5),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            padding: const pw.EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: pw.Column(
              children: [
                pw.Expanded(
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                    children: allZones.map((zone) {
                      final m  = zoneMotor[zone] ?? 0;
                      final c  = zoneMobil[zone] ?? 0;
                      final mx = maxCount < 1 ? 1 : maxCount;
                      final motorH = m / mx;
                      final mobilH = c / mx;
                      return pw.Column(
                        mainAxisAlignment: pw.MainAxisAlignment.end,
                        children: [
                          pw.Row(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              pw.Container(
                                width: 18,
                                height: 100 * motorH,
                                color: _pdfBlue,
                              ),
                              pw.SizedBox(width: 4),
                              pw.Container(
                                width: 18,
                                height: 100 * mobilH,
                                color: const PdfColor.fromInt(0xFFBBC4F5),
                              ),
                            ],
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(zone,
                              style: const pw.TextStyle(
                                  fontSize: 7, color: _pdfGray)),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 24),

          // ── Activity log table ─────────────────────────────────────────────
          pw.Text('RECENT ACTIVITY LOG',
              style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: _pdfGray,
                  letterSpacing: 0.8)),
          pw.SizedBox(height: 10),
          _buildTable(widget.activities.take(30).toList()),
        ],
      ),
    );

    return doc.save();
  }

  // ─── PDF Header ─────────────────────────────────────────────────────────────
  pw.Widget _buildHeader(pw.Context ctx) {
    final now = DateTime.now();
    final dateStr =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}  '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            // Logo block
            pw.Row(children: [
              pw.Container(
                width: 32, height: 32,
                decoration: const pw.BoxDecoration(
                  color: _pdfBlue,
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                alignment: pw.Alignment.center,
                child: pw.Text('P',
                    style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(width: 10),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('PARKIRKAMPUS',
                      style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: _pdfBlue)),
                  pw.Text('Sistem Manajemen Parkir Kampus',
                      style: const pw.TextStyle(
                          fontSize: 8, color: _pdfGray)),
                ],
              ),
            ]),
            // Right meta
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('LAPORAN AKTIVITAS PARKIR',
                    style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: _pdfGray)),
                pw.Text('Dicetak: $dateStr',
                    style: const pw.TextStyle(
                        fontSize: 8, color: _pdfGray)),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Divider(color: const PdfColor.fromInt(0xFFE8EAF0), thickness: 1),
      ],
    );
  }

  pw.Widget _buildFooter(pw.Context ctx) {
    return pw.Column(children: [
      pw.Divider(color: const PdfColor.fromInt(0xFFE8EAF0), thickness: 0.5),
      pw.SizedBox(height: 4),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('© PARKIRKAMPUS — Dokumen Rahasia',
              style: const pw.TextStyle(fontSize: 7, color: _pdfGray)),
          pw.Text('Halaman ${ctx.pageNumber} dari ${ctx.pagesCount}',
              style: const pw.TextStyle(fontSize: 7, color: _pdfGray)),
        ],
      ),
    ]);
  }

  // ─── Activity table ──────────────────────────────────────────────────────────
  pw.Widget _buildTable(List<dynamic> rows) {
    String fmt(String? raw) {
      if (raw == null) return '—';
      final dt = DateTime.tryParse(raw);
      if (dt == null) return '—';
      final l = dt.toLocal();
      return '${l.day.toString().padLeft(2, '0')}/${l.month.toString().padLeft(2, '0')} '
          '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
    }

    PdfColor statusColor(String st) {
      switch (st) {
        case 'parkir':   return _pdfGreen;
        case 'selesai':  return _pdfGray;
        case 'overstay': return _pdfOrange;
        default:         return _pdfGray;
      }
    }

    String statusLabel(String st) {
      switch (st) {
        case 'parkir':   return 'PARKED';
        case 'selesai':  return 'EXITED';
        case 'overstay': return 'OVERSTAY';
        default:         return st.toUpperCase();
      }
    }

    final headers = ['NO', 'USER', 'PLAT NOMOR', 'ZONA', 'MASUK', 'KELUAR', 'STATUS'];
    const colW    = [0.04, 0.22, 0.13, 0.16, 0.14, 0.14, 0.12];

    return pw.Table(
      columnWidths: {
        for (int i = 0; i < colW.length; i++)
          i: pw.FlexColumnWidth(colW[i]),
      },
      children: [
        // Header row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _pdfBlue),
          children: headers.map((h) => pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: pw.Text(h,
                style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                    letterSpacing: 0.3)),
          )).toList(),
        ),
        // Data rows
        ...rows.asMap().entries.map((e) {
          final i   = e.key;
          final row = e.value;
          final st  = row['status'] ?? '';
          return pw.TableRow(
            decoration: pw.BoxDecoration(
              color: i.isEven
                  ? const PdfColor.fromInt(0xFFFFFFFF)
                  : const PdfColor.fromInt(0xFFF8F9FB),
            ),
            children: [
              _Cell('${i + 1}'),
              _Cell(row['user_name'] ?? '—'),
              _Cell(row['nomor_polisi'] ?? '—', bold: true),
              _Cell(row['zona'] ?? '—'),
              _Cell(fmt(row['waktu_masuk'])),
              _Cell(fmt(row['waktu_keluar'])),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: 4, vertical: 5),
                child: pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 4, vertical: 2),
                  decoration: pw.BoxDecoration(
                    color: statusColor(st).shade(0.15),
                    borderRadius:
                        const pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Text(statusLabel(st),
                      style: pw.TextStyle(
                          fontSize: 7,
                          fontWeight: pw.FontWeight.bold,
                          color: statusColor(st))),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  // ─── Flutter UI ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _kText),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: _kBlue.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.picture_as_pdf_rounded,
                  size: 16, color: _kBlue),
            ),
            const SizedBox(width: 10),
            const Text('Export – Print Preview',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _kText)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: _generating ? null : _onShare,
              icon: _generating
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.ios_share_rounded, size: 16),
              label: Text(_generating ? 'Menyiapkan...' : 'Simpan / Bagikan',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _kBorder),
        ),
      ),
      body: Column(
        children: [
          // Info banner
          Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _kBlue.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _kBlue.withValues(alpha: 0.20)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 18, color: _kBlue),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Laporan berisi kop surat PARKIRKAMPUS, ringkasan kapasitas, '
                    'bar chart Occupancy per Zone, dan ${widget.activities.length} log aktivitas.',
                    style: const TextStyle(fontSize: 12, color: _kText),
                  ),
                ),
                const SizedBox(width: 10),
                _InfoPill(label: '${widget.activities.length} Baris'),
              ],
            ),
          ),

          // PDF Preview
          Expanded(
            child: PdfPreview(
              build: _buildPdf,
              allowPrinting: true,
              allowSharing: true,
              canChangePageFormat: false,
              canDebug: false,
              pdfFileName: 'aktivitas_parkir_${DateTime.now().millisecondsSinceEpoch}.pdf',
              loadingWidget: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: _kBlue),
                    SizedBox(height: 12),
                    Text('Memproses PDF...', style: TextStyle(color: _kMuted)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onShare() async {
    setState(() => _generating = true);
    try {
      final bytes = await _buildPdf(PdfPageFormat.a4);
      if (!mounted) return;
      await Printing.sharePdf(
        bytes: bytes,
        filename:
            'aktivitas_parkir_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }
}

// ─── PDF helper widgets ───────────────────────────────────────────────────────
pw.Widget _InfoChip({
  required String label,
  required String value,
  PdfColor color = _pdfGray,
}) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.center,
    children: [
      pw.Text(value,
          style: pw.TextStyle(
              fontSize: 16, fontWeight: pw.FontWeight.bold, color: color)),
      pw.SizedBox(height: 2),
      pw.Text(label,
          style: const pw.TextStyle(fontSize: 7, color: _pdfGray)),
    ],
  );
}

pw.Widget _Cell(String text, {bool bold = false}) {
  return pw.Padding(
    padding:
        const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
    child: pw.Text(text,
        style: pw.TextStyle(
            fontSize: 8,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: _pdfGray),
        overflow: pw.TextOverflow.clip),
  );
}

// ─── Flutter UI helpers ───────────────────────────────────────────────────────
class _InfoPill extends StatelessWidget {
  final String label;
  const _InfoPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _kBlue.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _kBlue)),
    );
  }
}
