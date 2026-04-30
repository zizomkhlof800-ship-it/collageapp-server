import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../constants/theme.dart';
import '../providers/theme_provider.dart';
import 'login_screen.dart';
import 'manage_students_screen.dart';
import 'manage_teachers_screen.dart';
import 'add_announcement_screen.dart';
import 'manage_schedules_screen.dart';
import '../services/data_service.dart';
import '../widgets/offline_image.dart';
import 'announcement_detail_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isDeleteMode = false;
  final DataService _dataService = DataService();

  @override
  void initState() {
    super.initState();
    _dataService.addListener(_onDataChanged);
    _dataService.fetchAnnouncements();
    _dataService.fetchSchedules(department: 'all', level: 'all');
  }

  @override
  void dispose() {
    _dataService.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    setState(() {});
  }

  Future<void> _navigateToAddAnnouncement() async {
    final nav = Navigator.of(context);
    final result = await nav.push(
      MaterialPageRoute(builder: (context) => const AddAnnouncementScreen()),
    );
    if (result != null && result is Announcement) {
      _dataService.addAnnouncement(result);
    }
  }

  void _navigateToSchedule(bool isExam) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ManageSchedulesScreen(isExam: isExam),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        drawer: _buildSideMenu(context),
        appBar: AppBar(
          elevation: 0,
          centerTitle: false,
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(LucideIcons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          actions: [
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                return IconButton(
                  icon: Icon(
                    themeProvider.isDarkMode
                        ? LucideIcons.sun
                        : LucideIcons.moon,
                  ),
                  onPressed: () =>
                      themeProvider.toggleTheme(!themeProvider.isDarkMode),
                );
              },
            ),
            const SizedBox(width: 8),
          ],
          title: Row(
            children: [
              Consumer<ThemeProvider>(
                builder: (context, themeProvider, _) => ColorFiltered(
                  colorFilter: themeProvider.isDarkMode
                      ? const ColorFilter.matrix([
                          -1,
                          0,
                          0,
                          0,
                          255,
                          0,
                          -1,
                          0,
                          0,
                          255,
                          0,
                          0,
                          -1,
                          0,
                          255,
                          0,
                          0,
                          0,
                          1,
                          0,
                        ])
                      : const ColorFilter.mode(
                          Colors.transparent,
                          BlendMode.dst,
                        ),
                  child: const Icon(
                    LucideIcons.graduationCap,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Consumer<ThemeProvider>(
                builder: (context, themeProvider, _) => Text(
                  'EduPorta',
                  style: GoogleFonts.cairo(
                    color: themeProvider.isDarkMode
                        ? Colors.white
                        : AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Welcome Card
              _buildWelcomeCard(),
              const SizedBox(height: 16),

              // Quick Actions Grid
              LayoutBuilder(
                builder: (context, constraints) {
                  final w = constraints.maxWidth;
                  int crossAxisCount;
                  double aspect;
                  if (w < 380) {
                    crossAxisCount = 2;
                    aspect = 1.1;
                  } else if (w < 700) {
                    crossAxisCount = 2;
                    aspect = 1.3;
                  } else if (w < 1000) {
                    crossAxisCount = 3;
                    aspect = 1.3;
                  } else {
                    crossAxisCount = 4;
                    aspect = 1.4;
                  }
                  final items = [
                    _buildQuickActionCard(
                      'الجدول الدراسي',
                      'إضافة جدول جديد',
                      LucideIcons.calendarDays,
                      Colors.blue,
                      () => _navigateToSchedule(false),
                    ),
                    _buildQuickActionCard(
                      'جدول الامتحانات',
                      'إضافة جدول الامتحانات',
                      LucideIcons.fileClock,
                      Colors.orange,
                      () => _navigateToSchedule(true),
                    ),
                    _buildQuickActionCard(
                      'إدارة الطلاب',
                      'عرض/إضافة/حذف',
                      LucideIcons.users,
                      Colors.green,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ManageStudentsScreen(),
                        ),
                      ),
                    ),
                    _buildQuickActionCard(
                      'إدارة المعلمين',
                      'تعديل صلاحيات المواد',
                      LucideIcons.briefcase,
                      Colors.teal,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ManageTeachersScreen(),
                        ),
                      ),
                    ),
                    _buildQuickActionCard(
                      'الإعلانات',
                      'نشر إعلان جديد',
                      LucideIcons.megaphone,
                      Colors.purple,
                      _navigateToAddAnnouncement,
                    ),
                  ];
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: aspect,
                    ),
                    itemBuilder: (context, index) => items[index],
                  );
                },
              ),
              const SizedBox(height: 24),

              // Announcements Section
              _buildSectionCard(
                title: 'آخر الإعلانات',
                icon: LucideIcons.bell,
                action: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _isDeleteMode = !_isDeleteMode;
                        });
                      },
                      icon: Icon(
                        _isDeleteMode ? LucideIcons.x : LucideIcons.trash2,
                        size: 20,
                        color: _isDeleteMode
                            ? Colors.red
                            : context.appTextLight,
                      ),
                      tooltip: _isDeleteMode ? 'إلغاء الحذف' : 'حذف إعلان',
                    ),
                  ],
                ),
                child: _dataService.announcements.isEmpty
                    ? _buildEmptyState('لا توجد إعلانات منشورة')
                    : Column(
                        children: _dataService.announcements.map((
                          announcement,
                        ) {
                          return _buildAnnouncementItem(announcement);
                        }).toList(),
                      ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSideMenu(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Drawer(
      backgroundColor: theme.scaffoldBackgroundColor,
      child: Column(
        children: [
          // Logo Area
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40),
            decoration: BoxDecoration(
              color: isDark ? theme.colorScheme.surface : Colors.transparent,
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Consumer<ThemeProvider>(
                    builder: (context, themeProvider, _) => ColorFiltered(
                      colorFilter: themeProvider.isDarkMode
                          ? const ColorFilter.matrix([
                              -1,
                              0,
                              0,
                              0,
                              255,
                              0,
                              -1,
                              0,
                              0,
                              255,
                              0,
                              0,
                              -1,
                              0,
                              255,
                              0,
                              0,
                              0,
                              1,
                              0,
                            ])
                          : const ColorFilter.mode(
                              Colors.transparent,
                              BlendMode.dst,
                            ),
                      child: Icon(
                        LucideIcons.graduationCap,
                        size: 40,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Consumer<ThemeProvider>(
                  builder: (context, themeProvider, _) => Text(
                    'EduPorta',
                    style: GoogleFonts.cairo(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: themeProvider.isDarkMode
                          ? Colors.white
                          : theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Divider(color: theme.dividerColor),

          // Menu Items
          _buildMenuItem(
            icon: LucideIcons.layoutDashboard,
            title: 'لوحة المعلومات',
            isActive: true,
            onTap: () => Navigator.pop(context),
          ),
          _buildMenuItem(
            icon: LucideIcons.calendarDays,
            title: 'إدارة الجدول الدراسي',
            onTap: () {
              Navigator.pop(context);
              _navigateToSchedule(false);
            },
          ),
          _buildMenuItem(
            icon: LucideIcons.fileClock,
            title: 'إدارة جدول الامتحانات',
            onTap: () {
              Navigator.pop(context);
              _navigateToSchedule(true);
            },
          ),
          _buildMenuItem(
            icon: LucideIcons.megaphone,
            title: 'إضافة إعلان',
            onTap: () {
              Navigator.pop(context);
              _navigateToAddAnnouncement();
            },
          ),
          _buildMenuItem(
            icon: LucideIcons.users,
            title: 'إدارة الطلاب',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ManageStudentsScreen(),
                ),
              );
            },
          ),
          _buildMenuItem(
            icon: LucideIcons.briefcase,
            title: 'إدارة المعلمين',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ManageTeachersScreen(),
                ),
              );
            },
          ),

          const Spacer(),

          // Theme Toggle in Drawer
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) => ListTile(
              leading: Icon(
                themeProvider.isDarkMode ? LucideIcons.sun : LucideIcons.moon,
                color: theme.colorScheme.primary,
              ),
              title: Text(
                themeProvider.isDarkMode ? 'الوضع الفاتح' : 'الوضع الداكن',
                style: GoogleFonts.cairo(
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              trailing: Switch(
                value: themeProvider.isDarkMode,
                onChanged: (value) => themeProvider.toggleTheme(value),
                activeThumbColor: theme.colorScheme.primary,
              ),
              onTap: () => themeProvider.toggleTheme(!themeProvider.isDarkMode),
            ),
          ),

          Divider(color: theme.dividerColor),

          // Logout
          _buildMenuItem(
            icon: LucideIcons.logOut,
            title: 'تسجيل الخروج',
            color: Colors.red,
            isActive: false,
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoginScreen(userType: 'admin'),
                ),
                (route) => false,
              );
            },
          ),

          const SizedBox(height: 16),

          // User Profile at bottom
          Container(
            padding: const EdgeInsets.all(16),
            color: isDark
                ? theme.colorScheme.surface
                : theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primary.withValues(
                    alpha: 0.1,
                  ),
                  child: Text(
                    'A',
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'المدير العام',
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    Text(
                      'admin',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: theme.textTheme.bodySmall?.color,
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

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isActive = false,
    Color? color,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final defaultIconColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final defaultTextColor = isDark ? Colors.white : Colors.grey[800];

    return ListTile(
      leading: Icon(
        icon,
        color:
            color ?? (isActive ? theme.colorScheme.primary : defaultIconColor),
      ),
      title: Text(
        title,
        style: GoogleFonts.cairo(
          color:
              color ??
              (isActive ? theme.colorScheme.primary : defaultTextColor),
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: onTap,
      selected: isActive,
      selectedTileColor: theme.colorScheme.primary.withValues(alpha: 0.05),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      shape: const Border(
        right: BorderSide(
          width: 4,
          color: AppColors.primary,
          style: BorderStyle.none,
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.white,
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'مرحباً، المدير العام',
                style: GoogleFonts.cairo(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'لديك صلاحيات كاملة لإدارة النظام',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  color: isDark ? Colors.grey[400] : context.appTextLight,
                ),
              ),
            ],
          ),
          const Text('👋', style: TextStyle(fontSize: 32)),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? theme.colorScheme.surface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: theme.textTheme.bodyLarge?.color,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              subtitle,
              style: GoogleFonts.cairo(
                fontSize: 12,
                color: isDark ? Colors.grey[400] : context.appTextLight,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
    Widget? action,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon, color: theme.colorScheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                  ],
                ),
                ?action,
              ],
            ),
          ),
          Divider(
            height: 1,
            color: isDark ? Colors.grey[800] : Colors.grey[200],
          ),
          Padding(padding: const EdgeInsets.all(24), child: child),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.inbox,
            size: 48,
            color: isDark ? Colors.grey[700] : Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.cairo(
              color: isDark ? Colors.grey[400] : context.appTextLight,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementItem(Announcement announcement) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Stack(
      children: [
        InkWell(
          onTap: _isDeleteMode
              ? null
              : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AnnouncementDetailScreen(
                        announcementId: announcement.id,
                      ),
                    ),
                  );
                },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? theme.colorScheme.surface : Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        announcement.title,
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                    ),
                    if (announcement.priority == 'هام جداً')
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'هام',
                          style: GoogleFonts.cairo(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  announcement.content,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : context.appTextLight,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (announcement.imageUrl.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: OfflineImage(
                      url: announcement.imageUrl,
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(LucideIcons.clock, size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      announcement.date,
                      style: GoogleFonts.cairo(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (_isDeleteMode)
          Positioned(
            left: 0,
            top: 0,
            bottom: 12,
            child: Center(
              child: Container(
                margin: const EdgeInsets.only(left: 8),
                child: IconButton(
                  icon: const Icon(LucideIcons.trash2, color: Colors.red),
                  onPressed: () {
                    _dataService.deleteAnnouncement(announcement.id);
                    if (_dataService.announcements.isEmpty) {
                      setState(() {
                        _isDeleteMode = false;
                      });
                    }
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }
}
