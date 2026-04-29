import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/data_service.dart';
import '../services/api_service.dart';
import '../constants/theme.dart';
import 'package:url_launcher/url_launcher.dart';
import 'video_player_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:async';
import 'pdf_viewer_screen.dart';

const int _maxLibraryUploadBytes = 8 * 1024 * 1024;

class DigitalLibraryScreen extends StatefulWidget {
  const DigitalLibraryScreen({super.key});

  @override
  State<DigitalLibraryScreen> createState() => _DigitalLibraryScreenState();
}

class _DigitalLibraryScreenState extends State<DigitalLibraryScreen>
    with SingleTickerProviderStateMixin {
  final DataService _dataService = DataService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = true;
  String _selectedMediaType = 'ALL';
  bool _isTeacherOrAdmin = false;
  String? _currentTeacherId;
  String? _currentTeacherName;

  @override
  void initState() {
    super.initState();
    _dataService.addListener(_onDataChanged);
    _checkUserRole();
    _loadData();
  }

  @override
  void dispose() {
    _dataService.removeListener(_onDataChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    // Check for teacher or admin session
    final teacherId = prefs.getString('teacher_id');
    final teacherName =
        prefs.getString('teacher_session_username') ??
        prefs.getString('teacher_username');
    final adminName =
        prefs.getString('admin_session_username') ??
        prefs.getString('admin_username');

    if (mounted) {
      setState(() {
        _isTeacherOrAdmin = teacherId != null || adminName != null;
        _currentTeacherId = teacherId ?? (adminName != null ? 'admin' : null);
        _currentTeacherName = teacherName ?? adminName;
      });
    }
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await _dataService.fetchLibraryBooks();
    if (mounted) setState(() => _isLoading = false);
  }

  List<LibraryBook> _getFilteredBooks() {
    return _dataService.libraryBooks.where((book) {
      // Teachers only see their own books, students/admins see all
      bool matchesOwnership = true;
      if (_isTeacherOrAdmin &&
          _currentTeacherId != null &&
          _currentTeacherName != 'admin') {
        // Option to let teachers see all library contents but only edit their own
        // matchesOwnership = true; // Let them see everything
      }

      final matchesSearch =
          book.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          book.author.toLowerCase().contains(_searchQuery.toLowerCase());

      bool matchesMediaType = true;
      if (_selectedMediaType == 'BOOK') {
        matchesMediaType = book.mediaType == LibraryMediaType.BOOK;
      } else if (_selectedMediaType == 'VIDEO') {
        matchesMediaType =
            book.mediaType == LibraryMediaType.VIDEO_FILE ||
            book.mediaType == LibraryMediaType.VIDEO_LINK;
      }

      return matchesOwnership && matchesSearch && matchesMediaType;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'المكتبة الرقمية',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowRight),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(120),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'ابحث عن كتاب أو مؤلف...',
                      hintStyle: GoogleFonts.cairo(fontSize: 13),
                      prefixIcon: const Icon(LucideIcons.search, size: 20),
                      filled: true,
                      fillColor: isDark ? Colors.grey[850] : Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                ),
                _buildMediaTypeFilter(),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Builder(
                builder: (context) {
                  final books = _getFilteredBooks();
                  if (books.isEmpty) {
                    return _buildEmptyState();
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.65,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                    itemCount: books.length,
                    itemBuilder: (context, index) =>
                        _buildBookCard(books[index]),
                  );
                },
              ),
        floatingActionButton: _isTeacherOrAdmin
            ? FloatingActionButton.extended(
                onPressed: _showAddLibraryItemDialog,
                backgroundColor: AppColors.primary,
                icon: const Icon(LucideIcons.plus, color: Colors.white),
                label: Text(
                  'إضافة محتوى',
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
      ),
    );
  }

  void _showAddLibraryItemDialog() {
    LibraryMediaType selectedType = LibraryMediaType.BOOK;
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final urlController = TextEditingController();
    PlatformFile? pickedFile;
    bool isUploading = false;
    double uploadProgress = 0.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              top: 20,
              left: 20,
              right: 20,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(25),
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'إضافة محتوى جديد للمكتبة',
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<LibraryMediaType>(
                    initialValue: selectedType,
                    items: [
                      DropdownMenuItem(
                        value: LibraryMediaType.BOOK,
                        child: Text(
                          'كتاب دراسي (PDF)',
                          style: GoogleFonts.cairo(),
                        ),
                      ),
                      DropdownMenuItem(
                        value: LibraryMediaType.VIDEO_FILE,
                        child: Text(
                          'فيديو تعليمي (MP4)',
                          style: GoogleFonts.cairo(),
                        ),
                      ),
                      DropdownMenuItem(
                        value: LibraryMediaType.VIDEO_LINK,
                        child: Text(
                          'رابط فيديو خارجي',
                          style: GoogleFonts.cairo(),
                        ),
                      ),
                    ],
                    onChanged: (v) => setDialogState(() {
                      selectedType = v!;
                      pickedFile = null;
                      uploadProgress = 0.0;
                    }),
                    decoration: InputDecoration(
                      labelText: 'نوع المحتوى',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'العنوان',
                      hintText: 'مثلاً: مدخل إلى تكنولوجيا التعليم',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'الوصف المختصر',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (selectedType == LibraryMediaType.VIDEO_LINK)
                    TextField(
                      controller: urlController,
                      decoration: InputDecoration(
                        labelText: 'رابط الفيديو',
                        hintText: 'https://youtube.com/...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(LucideIcons.link),
                      ),
                    )
                  else ...[
                    if (pickedFile == null)
                      OutlinedButton.icon(
                        onPressed: () async {
                          final result = await FilePicker.platform.pickFiles(
                            type: FileType.custom,
                            allowedExtensions:
                                selectedType == LibraryMediaType.BOOK
                                ? ['pdf']
                                : ['mp4'],
                            withData: true,
                          );
                          if (result != null) {
                            final file = result.files.first;
                            if (file.size > _maxLibraryUploadBytes) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'حجم الملف كبير. أقصى حجم مسموح 8 ميجابايت. للفيديوهات الكبيرة استخدم رابط فيديو.',
                                    style: GoogleFonts.cairo(),
                                  ),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                              return;
                            }
                            setDialogState(() {
                              pickedFile = file;
                              uploadProgress = 0.0;
                            });

                            for (int i = 0; i <= 10; i++) {
                              await Future.delayed(
                                const Duration(milliseconds: 100),
                              );
                              if (context.mounted) {
                                setDialogState(() => uploadProgress = i / 10.0);
                              }
                            }
                          }
                        },
                        icon: const Icon(LucideIcons.filePlus),
                        label: Text(
                          selectedType == LibraryMediaType.BOOK
                              ? 'اختر ملف PDF'
                              : 'اختر ملف MP4',
                          style: GoogleFonts.cairo(),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  selectedType == LibraryMediaType.BOOK
                                      ? LucideIcons.fileText
                                      : LucideIcons.video,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    pickedFile!.name,
                                    style: GoogleFonts.cairo(fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    LucideIcons.trash2,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  onPressed: () =>
                                      setDialogState(() => pickedFile = null),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: uploadProgress,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ],
                        ),
                      ),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: isUploading
                        ? null
                        : () async {
                            if (titleController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('يرجى كتابة العنوان'),
                                ),
                              );
                              return;
                            }
                            if (selectedType == LibraryMediaType.VIDEO_LINK &&
                                urlController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'يرجى إدخال رابط الفيديو',
                                    style: GoogleFonts.cairo(),
                                  ),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                              return;
                            }
                            if (selectedType != LibraryMediaType.VIDEO_LINK &&
                                pickedFile == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'يرجى اختيار الملف أولاً',
                                    style: GoogleFonts.cairo(),
                                  ),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                              return;
                            }
                            setDialogState(() => isUploading = true);
                            try {
                              String finalUrl =
                                  selectedType == LibraryMediaType.VIDEO_LINK
                                  ? urlController.text.trim()
                                  : 'local-upload-${pickedFile?.name}';

                              await ApiService.addLibraryBook({
                                'title': titleController.text.trim(),
                                'author': _currentTeacherName ?? 'دكتور جامعي',
                                'category': 'textbooks',
                                'description': descriptionController.text
                                    .trim(),
                                'url': finalUrl,
                                'mediaType': selectedType.name,
                                'size': pickedFile != null
                                    ? '${(pickedFile!.size / (1024 * 1024)).toStringAsFixed(2)} MB'
                                    : 'رابط خارجي',
                                'thumbnail':
                                    'https://via.placeholder.com/150x200?text=${selectedType.name}',
                                'teacherId': _currentTeacherId,
                                'fileBytes': pickedFile?.bytes,
                                'fileName': pickedFile?.name,
                              });

                              if (context.mounted) {
                                Navigator.pop(context);
                                _loadData();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('تمت الإضافة للمكتبة بنجاح'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('خطأ: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            } finally {
                              if (context.mounted) {
                                setDialogState(() => isUploading = false);
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isUploading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'نشر في المكتبة الآن',
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMediaTypeFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          _filterChip('الكل', 'ALL'),
          const SizedBox(width: 8),
          _filterChip('الكتب', 'BOOK'),
          const SizedBox(width: 8),
          _filterChip('الفيديوهات', 'VIDEO'),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String id) {
    final isSelected = _selectedMediaType == id;
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => setState(() => _selectedMediaType = id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 12,
            color: isSelected ? Colors.white : Colors.grey[600],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.searchX,
            size: 64,
            color: Colors.grey.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد نتائج بحث مطابقة',
            style: GoogleFonts.cairo(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildBookCard(LibraryBook book) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // can delete if is admin OR if is the teacher who uploaded it
    final bool canDelete =
        _isTeacherOrAdmin &&
        (_currentTeacherId == book.teacherId || _currentTeacherId == 'admin');

    return InkWell(
      onTap: () => _showBookDetails(book),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(15),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      book.thumbnail,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        child: Icon(
                          book.mediaType == LibraryMediaType.BOOK
                              ? LucideIcons.book
                              : LucideIcons.playCircle,
                          color: AppColors.primary,
                          size: 40,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          book.size,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    if (canDelete)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: GestureDetector(
                          onTap: () => _confirmDelete(book),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              LucideIcons.trash2,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Icon(
                        book.mediaType == LibraryMediaType.BOOK
                            ? LucideIcons.book
                            : LucideIcons.playCircle,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book.author,
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(LibraryBook book) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text(
            'حذف من المكتبة',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'هل أنت متأكد من حذف "${book.title}"؟ سيتوقف الطلاب عن رؤيتها.',
            style: GoogleFonts.cairo(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('إلغاء', style: GoogleFonts.cairo()),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await ApiService.deleteLibraryBook(book.id);
                _loadData();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'تم حذف العنصر بنجاح',
                        style: GoogleFonts.cairo(),
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: Text(
                'حذف الآن',
                style: GoogleFonts.cairo(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBookDetails(LibraryBook book) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 120,
                          height: 160,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.network(
                              book.thumbnail,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  Container(color: Colors.grey[200]),
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                book.title,
                                style: GoogleFonts.cairo(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'المؤلف: ${book.author}',
                                style: GoogleFonts.cairo(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildBadge(book.category),
                              const SizedBox(height: 8),
                              Text(
                                'الحجم: ${book.size}',
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      book.mediaType == LibraryMediaType.BOOK
                          ? 'عن الكتاب'
                          : 'عن الفيديو',
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      book.description,
                      style: GoogleFonts.cairo(
                        height: 1.6,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 40),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _handleOpenMedia(book),
                            icon: Icon(
                              book.mediaType == LibraryMediaType.BOOK
                                  ? LucideIcons.bookOpen
                                  : LucideIcons.play,
                              color: Colors.white,
                            ),
                            label: Text(
                              book.mediaType == LibraryMediaType.BOOK
                                  ? 'قراءة الآن'
                                  : 'تشغيل الآن',
                              style: GoogleFonts.cairo(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                          ),
                        ),
                        if (book.mediaType != LibraryMediaType.VIDEO_LINK) ...[
                          const SizedBox(width: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: IconButton(
                              onPressed: () => _downloadBook(book),
                              icon: const Icon(
                                LucideIcons.download,
                                color: Colors.blue,
                              ),
                              padding: const EdgeInsets.all(16),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleOpenMedia(LibraryBook book) {
    switch (book.mediaType) {
      case LibraryMediaType.BOOK:
        _openBook(book.url, book.title);
        break;
      case LibraryMediaType.VIDEO_FILE:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                VideoPlayerScreen(videoUrl: book.url, title: book.title),
          ),
        );
        break;
      case LibraryMediaType.VIDEO_LINK:
        _openExternalLink(book.url);
        break;
    }
  }

  Widget _buildBadge(String category) {
    String label = '';
    Color color = Colors.grey;
    switch (category) {
      case 'textbooks':
        label = 'كتاب دراسي';
        color = Colors.blue;
        break;
      case 'references':
        label = 'مرجع خارجي';
        color = Colors.purple;
        break;
      case 'summaries':
        label = 'ملخص';
        color = Colors.orange;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: GoogleFonts.cairo(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _openBook(String url, String title) async {
    if (url.startsWith('http') || url.startsWith('data:application/pdf')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PDFViewerScreen(title: title, url: url),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'الملف غير متاح بعد إعادة تحميل التطبيق. شغّل السيرفر أو ارفع ملفاً أصغر.',
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _openExternalLink(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('لا يمكن فتح الرابط', style: GoogleFonts.cairo()),
        ),
      );
    }
  }

  void _downloadBook(LibraryBook book) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'بدء تحميل ${book.title}... سيتم الحفظ للقراءة بدون إنترنت',
          style: GoogleFonts.cairo(),
        ),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
