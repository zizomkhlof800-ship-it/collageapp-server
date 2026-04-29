import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../constants/theme.dart';
import '../constants/api.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'image_viewer_screen.dart';

class AnnouncementDetailScreen extends StatefulWidget {
  final String announcementId;
  const AnnouncementDetailScreen({super.key, required this.announcementId});

  @override
  State<AnnouncementDetailScreen> createState() =>
      _AnnouncementDetailScreenState();
}

class _AnnouncementDetailScreenState extends State<AnnouncementDetailScreen> {
  Map<String, dynamic>? _announcement;
  bool _loading = true;
  bool _liking = false;
  final TextEditingController _commentController = TextEditingController();
  String _userId = '';
  String _userName = '';
  String _userType = 'student';
  bool get _isPrivileged => _userType == 'admin' || _userType == 'teacher';

  @override
  void initState() {
    super.initState();
    _initIdentity().then((_) => _load());
  }

  Future<void> _initIdentity() async {
    final prefs = await SharedPreferences.getInstance();
    final student = prefs.getBool('student_logged_in') ?? false;
    if (student) {
      _userId = prefs.getString('student_code') ?? '';
      _userName = prefs.getString('student_name') ?? 'طالب';
      _userType = 'student';
      return;
    }
    final t = prefs.getString('teacher_username') ?? '';
    if (t.isNotEmpty) {
      _userId = t;
      _userName = t;
      _userType = 'teacher';
      return;
    }
    final a = prefs.getString('admin_username') ?? '';
    if (a.isNotEmpty) {
      _userId = a;
      _userName = a;
      _userType = 'admin';
      return;
    }
    _userId = 'guest';
    _userName = 'زائر';
    _userType = 'guest';
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final it = await ApiService.getAnnouncementById(widget.announcementId);
      setState(() {
        _announcement = it;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  bool _canModify(Map<String, dynamic> c) {
    final uid = (c['userId'] ?? '').toString();
    return _isPrivileged || (uid.isNotEmpty && uid == _userId);
  }

  Future<void> _editComment(Map<String, dynamic> c) async {
    final ctrl = TextEditingController(text: (c['text'] ?? '').toString());
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text('تعديل التعليق', style: GoogleFonts.cairo()),
          content: TextField(
            controller: ctrl,
            maxLines: 3,
            textAlign: TextAlign.right,
            style: GoogleFonts.cairo(),
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: 'اكتب التعليق',
              hintStyle: GoogleFonts.cairo(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('إلغاء', style: GoogleFonts.cairo()),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('حفظ', style: GoogleFonts.cairo()),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    try {
      await ApiService.editAnnouncementComment(
        id: widget.announcementId,
        commentId: (c['id'] ?? '').toString(),
        userId: _userId,
        userType: _userType,
        text: ctrl.text.trim(),
      );
      await _load();
    } catch (_) {}
  }

  Future<void> _deleteComment(Map<String, dynamic> c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text('حذف التعليق', style: GoogleFonts.cairo()),
          content: Text(
            'هل أنت متأكد من حذف هذا التعليق؟',
            style: GoogleFonts.cairo(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('إلغاء', style: GoogleFonts.cairo()),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('حذف', style: GoogleFonts.cairo(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    try {
      await ApiService.deleteAnnouncementComment(
        id: widget.announcementId,
        commentId: (c['id'] ?? '').toString(),
        userId: _userId,
        userType: _userType,
      );
      await _load();
    } catch (_) {}
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Widget _buildAnnouncementImage(String imageUrl) {
    if (imageUrl.startsWith('data:image/')) {
      return Image.memory(
        base64Decode(imageUrl.split(',').last),
        fit: BoxFit.contain,
      );
    }
    return Image.network(
      imageUrl.startsWith('http') ? imageUrl : '$baseUrl$imageUrl',
      fit: BoxFit.contain,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowRight, color: AppColors.text),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'تفاصيل الإعلان',
            style: GoogleFonts.cairo(
              color: AppColors.text,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _announcement == null
            ? Center(
                child: Text(
                  'تعذر تحميل الإعلان',
                  style: GoogleFonts.cairo(color: AppColors.textLight),
                ),
              )
            : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final a = _announcement!;
    final comments = List<Map<String, dynamic>>.from(a['comments'] ?? const []);
    final likes = List<String>.from(a['likes'] ?? const []);
    final liked = _userId.isNotEmpty && likes.contains(_userId);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a['title'] ?? '',
                  textAlign: TextAlign.right,
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  a['content'] ?? '',
                  textAlign: TextAlign.right,
                  style: GoogleFonts.cairo(fontSize: 14, color: AppColors.text),
                ),
                if ((a['imageUrl'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ImageViewerScreen(
                            imageUrl: a['imageUrl'],
                            title: 'صورة الإعلان',
                          ),
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _buildAnnouncementImage(
                        (a['imageUrl'] ?? '').toString(),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: _liking || _userId.isEmpty
                              ? null
                              : () async {
                                  setState(() => _liking = true);
                                  try {
                                    await ApiService.likeAnnouncement(
                                      a['id'],
                                      _userId,
                                    );
                                    await _load();
                                  } catch (_) {}
                                  setState(() => _liking = false);
                                },
                          icon: Icon(
                            LucideIcons.heart,
                            color: liked ? Colors.red : Colors.grey,
                          ),
                        ),
                        Text(
                          '${likes.length}',
                          style: GoogleFonts.cairo(color: AppColors.text),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          (a['date'] ?? '').toString(),
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          LucideIcons.clock,
                          size: 14,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'التعليقات',
                  textAlign: TextAlign.right,
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (comments.isEmpty)
                  Text(
                    'لا توجد تعليقات بعد',
                    textAlign: TextAlign.right,
                    style: GoogleFonts.cairo(color: AppColors.textLight),
                  )
                else
                  ...comments.map((c) {
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_canModify(Map<String, dynamic>.from(c))) ...[
                            PopupMenuButton<String>(
                              icon: const Icon(LucideIcons.moreVertical),
                              onSelected: (v) {
                                if (v == 'edit') {
                                  _editComment(Map<String, dynamic>.from(c));
                                } else if (v == 'delete') {
                                  _deleteComment(Map<String, dynamic>.from(c));
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Text('تعديل'),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text('حذف'),
                                ),
                              ],
                            ),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${c['name'] ?? c['userId'] ?? ''}',
                                  textAlign: TextAlign.right,
                                  style: GoogleFonts.cairo(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${c['text'] ?? ''}',
                                  textAlign: TextAlign.right,
                                  style: GoogleFonts.cairo(),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${c['createdAt'] ?? ''}',
                                  textAlign: TextAlign.right,
                                  style: GoogleFonts.cairo(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              LucideIcons.user,
                              color: AppColors.primary,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        textAlign: TextAlign.right,
                        decoration: InputDecoration(
                          hintText: 'اكتب تعليقاً...',
                          hintStyle: GoogleFonts.cairo(),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'إرسال',
                      onPressed: () async {
                        final text = _commentController.text.trim();
                        if (text.isEmpty) return;
                        try {
                          await ApiService.commentOnAnnouncement(
                            id: a['id'],
                            userId: _userId.isEmpty ? 'guest' : _userId,
                            userType: _userType,
                            name: _userName,
                            text: text,
                          );
                          _commentController.clear();
                          await _load();
                        } catch (_) {}
                      },
                      icon: const Icon(
                        LucideIcons.send,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
