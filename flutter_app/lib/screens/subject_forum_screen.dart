import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/api_service.dart';

class LevelForumScreen extends StatefulWidget {
  final String levelId;
  final String levelName;
  final String userName;
  final String userRole;
  final String teacherId;
  final String teacherName;

  const LevelForumScreen({
    super.key,
    required this.levelId,
    required this.levelName,
    required this.userName,
    required this.userRole,
    required this.teacherId,
    required this.teacherName,
  });

  @override
  State<LevelForumScreen> createState() => _LevelForumScreenState();
}

class _LevelForumScreenState extends State<LevelForumScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _loading = true;
  bool _sending = false;
  List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    _markAsRead();
    _loadMessages();
  }

  Future<void> _markAsRead() async {
    await ApiService.markMessagesAsRead(widget.levelId, widget.teacherId, widget.userRole);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _formatTime(int timestamp) {
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _loadMessages() async {
    setState(() => _loading = true);
    try {
      final items = await ApiService.getLevelMessages(widget.levelId, teacherId: widget.teacherId);
      if (!mounted) return;
      setState(() {
        _messages = items;
        _loading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _sendMessage() async {
    if (_sending) return;
    final content = _messageController.text.trim();
    if (content.isEmpty) return;
    setState(() => _sending = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final msg = await ApiService.sendLevelMessage(
        widget.levelId,
        widget.teacherId,
        widget.userName,
        widget.userRole,
        content,
      );
      _messageController.clear();
      if (!mounted) return;
      setState(() {
        _messages = [..._messages, msg];
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (_) {
      final theme = Theme.of(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text('تعذر إرسال الرسالة', style: GoogleFonts.cairo(color: theme.colorScheme.onError)),
          backgroundColor: theme.colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg, bool isMe) {
    final theme = Theme.of(context);
    final senderName = (msg['senderName'] ?? '').toString();
    final role = (msg['role'] ?? '').toString();
    final content = (msg['content'] ?? '').toString();
    final timestamp = (msg['timestamp'] ?? 0) as int;

    final bubbleColor = isMe ? theme.colorScheme.primary : theme.colorScheme.surface;
    final textColor = isMe ? Colors.white : theme.textTheme.bodyLarge?.color;
    final metaColor = isMe ? Colors.white70 : theme.textTheme.bodySmall?.color;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.circular(14),
              border: isMe ? null : Border.all(color: theme.dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Text(
                    role == 'teacher' ? 'المعلم: $senderName' : 'طالب: $senderName',
                    style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: metaColor),
                  ),
                if (!isMe) const SizedBox(height: 4),
                Text(content, style: GoogleFonts.cairo(color: textColor, height: 1.4)),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(_formatTime(timestamp), style: GoogleFonts.cairo(fontSize: 11, color: metaColor)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(      
        appBar: AppBar(
          title: Column(
            children: [
              Text(widget.levelName, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)),
              Text('المعلم: ${widget.teacherName}', style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey)),
            ],
          ),
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowRight),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: ApiService.getLevelMessagesStream(widget.levelId, teacherId: widget.teacherId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('خطأ في تحميل الرسائل', style: GoogleFonts.cairo()));
                  }

                  final messages = snapshot.data ?? [];
                  if (messages.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.messagesSquare, size: 64, color: theme.colorScheme.primary.withValues(alpha: 0.2)),
                          const SizedBox(height: 16),
                          Text('لا توجد رسائل بعد. ابدأ المحادثة!', style: GoogleFonts.cairo(color: Colors.grey)),
                        ],
                      ),
                    );
                  }

                  // Scroll to bottom when new messages arrive
                  WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final bool isMe = msg['senderName'] == widget.userName;
                      return _buildMessageBubble(msg, isMe);
                    },
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(top: BorderSide(color: theme.dividerColor)),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        style: GoogleFonts.cairo(color: theme.textTheme.bodyLarge?.color),
                        decoration: InputDecoration(
                          hintText: 'اكتب رسالة...',
                          hintStyle: GoogleFonts.cairo(color: theme.textTheme.bodySmall?.color),
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      onPressed: _sending ? null : _sendMessage,
                      icon: Icon(LucideIcons.send, color: _sending ? Colors.grey : theme.colorScheme.primary),
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
}
