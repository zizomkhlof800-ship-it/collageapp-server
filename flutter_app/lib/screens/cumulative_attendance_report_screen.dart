import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/api_service.dart';

class CumulativeAttendanceReportScreen extends StatefulWidget {
  final String levelId;
  final String teacherId;

  const CumulativeAttendanceReportScreen({
    super.key,
    required this.levelId,
    required this.teacherId,
  });

  @override
  State<CumulativeAttendanceReportScreen> createState() =>
      _CumulativeAttendanceReportScreenState();
}

class _CumulativeAttendanceReportScreenState
    extends State<CumulativeAttendanceReportScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _reportData = [];

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getCumulativeAttendance(widget.levelId);
      if (mounted) {
        setState(() {
          _reportData = data;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.colorScheme.surface,
          elevation: 0,
          title: Text(
            'تقرير حصاد السنة - ${widget.levelId.replaceAll('__', ' - ')}',
            style: GoogleFonts.cairo(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          leading: IconButton(
            icon: Icon(
              LucideIcons.arrowRight,
              color: theme.colorScheme.onSurface,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(LucideIcons.refreshCw),
              onPressed: _loadReport,
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _reportData.isEmpty
            ? Center(
                child: Text(
                  'لا توجد بيانات حضور مسجلة لهذه الفرقة',
                  style: GoogleFonts.cairo(),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Summary Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.2,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildSummaryItem(
                            'عدد الطلاب',
                            _reportData.length.toString(),
                            LucideIcons.users,
                          ),
                          _buildSummaryItem(
                            'إجمالي المحاضرات',
                            (_reportData.isNotEmpty
                                    ? _reportData[0]['totalLectures']
                                    : 0)
                                .toString(),
                            LucideIcons.bookOpen,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Table
                    Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.2 : 0.05,
                            ),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(
                              theme.colorScheme.primary.withValues(alpha: 0.05),
                            ),
                            columns: [
                              DataColumn(
                                label: Text(
                                  'اسم الطالب',
                                  style: GoogleFonts.cairo(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'المحاضرات',
                                  style: GoogleFonts.cairo(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'الحضور',
                                  style: GoogleFonts.cairo(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'النسبة',
                                  style: GoogleFonts.cairo(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                            rows: _reportData.map((s) {
                              final double percentage = (s['percentage'] as num)
                                  .toDouble();
                              Color statusColor = Colors.green;
                              if (percentage < 50) {
                                statusColor = Colors.red;
                              } else if (percentage < 75)
                                statusColor = Colors.orange;

                              return DataRow(
                                cells: [
                                  DataCell(
                                    Text(
                                      s['studentName'] ?? '',
                                      style: GoogleFonts.cairo(fontSize: 13),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      s['totalLectures'].toString(),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      s['presentCount'].toString(),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${percentage.toStringAsFixed(1)}%',
                                        style: GoogleFonts.cairo(
                                          color: statusColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.cairo(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 12,
            color: theme.textTheme.bodySmall?.color,
          ),
        ),
      ],
    );
  }
}
