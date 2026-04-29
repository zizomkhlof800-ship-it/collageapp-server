import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/data_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/api.dart';
import 'pdf_viewer_screen.dart';
import 'subject_forum_screen.dart';
import '../services/api_service.dart';

class StudentMaterialsScreen extends StatefulWidget {
  final String department;
  final String level;
  final String? studentName;
  final String? studentCode;

  const StudentMaterialsScreen({
    super.key,
    required this.department,
    required this.level,
    this.studentName,
    this.studentCode,
  });

  @override
  State<StudentMaterialsScreen> createState() => _StudentMaterialsScreenState();
}

class _StudentMaterialsScreenState extends State<StudentMaterialsScreen> {
  final DataService _dataService = DataService();

  @override
  void initState() {
    super.initState();
    _dataService.addListener(_onDataChanged);
    _dataService.fetchMaterials(
      department: widget.department,
      level: widget.level,
    );
  }

  @override
  void dispose() {
    _dataService.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _openUrl(String url, String title) async {
    final full = url.startsWith('http') ? url : '$baseUrl$url';
    if (full.startsWith('data:application/pdf;base64,')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PDFViewerScreen(title: title, url: full),
        ),
      );
      return;
    }
    final uri = Uri.tryParse(full);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _showTeacherSelectionForForum(
    String levelId,
    String levelName,
    String userName,
  ) async {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'اختر المعلم للمحادثة',
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: ApiService.getTeachers(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Text(
                        'لا يوجد معلمون متاحون',
                        style: GoogleFonts.cairo(),
                      ),
                    );
                  }

                  // Filter teachers who teach this level
                  final teachers = snapshot.data!.where((t) {
                    final courses = List<Map<String, dynamic>>.from(
                      t['courses'] ?? [],
                    );
                    return courses.any(
                      (c) =>
                          c['department'] == widget.department &&
                          c['level'] == widget.level,
                    );
                  }).toList();

                  if (teachers.isEmpty) {
                    return Center(
                      child: Text(
                        'لا يوجد معلمون لهذه الفرقة',
                        style: GoogleFonts.cairo(),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: teachers.length,
                    itemBuilder: (context, index) {
                      final t = teachers[index];
                      final tId = t['id'].toString();
                      final tName = t['username'].toString();

                      return FutureBuilder<int>(
                        future: ApiService.getUnreadCount(
                          levelId,
                          tId,
                          'student',
                        ),
                        builder: (context, countSnapshot) {
                          final unread = countSnapshot.data ?? 0;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: theme.colorScheme.primary
                                    .withOpacity(0.1),
                                child: Icon(
                                  LucideIcons.user,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              title: Text(
                                tName,
                                style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                'معلم الفرقة',
                                style: GoogleFonts.cairo(fontSize: 12),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (unread > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        unread.toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  const SizedBox(width: 8),
                                  const Icon(LucideIcons.chevronLeft),
                                ],
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => LevelForumScreen(
                                      levelId: levelId,
                                      levelName: levelName,
                                      userName: userName,
                                      userRole: 'student',
                                      teacherId: tId,
                                      teacherName: tName,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final materials = _dataService.materials;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        title: Text(
          'مواد المقرر',
          style: GoogleFonts.cairo(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            LucideIcons.arrowRight,
            color: theme.colorScheme.onSurface,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: materials.isEmpty ? 1 : materials.length,
        itemBuilder: (context, index) {
          if (materials.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: theme.dividerColor),
              ),
              child: Center(
                child: Text(
                  'لا توجد مواد حالياً',
                  style: GoogleFonts.cairo(
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
              ),
            );
          }
          final m = materials[index];
          final levelId = '${m.department}__${m.level}';
          final levelName = '${m.department} - ${m.level}';
          final userName =
              (widget.studentName != null &&
                  widget.studentName!.trim().isNotEmpty)
              ? widget.studentName!.trim()
              : ((widget.studentCode ?? '').trim().isNotEmpty
                    ? widget.studentCode!.trim()
                    : 'طالب');
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: theme.dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      LucideIcons.fileText,
                      size: 16,
                      color: theme.colorScheme.onSurface,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m.originalName,
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.bold,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'الأستاذ: ${m.teacherName}',
                            style: GoogleFonts.cairo(
                              color: theme.textTheme.bodySmall?.color,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => _openUrl(m.url, m.originalName),
                      child: Text('فتح', style: GoogleFonts.cairo()),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed:
                            m.level.trim().isEmpty ||
                                m.department.trim().isEmpty
                            ? null
                            : () {
                                _showTeacherSelectionForForum(
                                  levelId,
                                  levelName,
                                  userName,
                                );
                              },
                        icon: const Icon(LucideIcons.messagesSquare, size: 18),
                        label: Text(
                          'دخول منتدى الفرقة',
                          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.primary,
                          side: BorderSide(color: theme.colorScheme.primary),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
