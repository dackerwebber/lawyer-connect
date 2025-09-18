import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ChatInterfaceWidget extends StatefulWidget {
  final Map<String, dynamic> conversation;
  final VoidCallback onBack;

  const ChatInterfaceWidget({
    Key? key,
    required this.conversation,
    required this.onBack,
  }) : super(key: key);

  @override
  State<ChatInterfaceWidget> createState() => _ChatInterfaceWidgetState();
}

class _ChatInterfaceWidgetState extends State<ChatInterfaceWidget> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  bool _isRecording = false;

  final List<Map<String, dynamic>> _messages = [
    {
      "id": 1,
      "senderId": "lawyer_001",
      "senderName": "Sarah Johnson",
      "content":
          "Thank you for reaching out. I've reviewed your case details and I'm confident I can help you with your property dispute.",
      "timestamp": DateTime.now().subtract(const Duration(hours: 2)),
      "isMe": false,
      "messageType": "text",
      "status": "read"
    },
    {
      "id": 2,
      "senderId": "client_001",
      "senderName": "Michael Rodriguez",
      "content":
          "That's great to hear! When would be a good time to schedule our first consultation?",
      "timestamp":
          DateTime.now().subtract(const Duration(hours: 1, minutes: 45)),
      "isMe": true,
      "messageType": "text",
      "status": "delivered"
    },
    {
      "id": 3,
      "senderId": "lawyer_001",
      "senderName": "Sarah Johnson",
      "content":
          "I have availability this Friday at 2 PM or Monday at 10 AM. Which works better for you?",
      "timestamp":
          DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
      "isMe": false,
      "messageType": "text",
      "status": "read"
    },
    {
      "id": 4,
      "senderId": "client_001",
      "senderName": "Michael Rodriguez",
      "content":
          "Friday at 2 PM works perfectly. Should I bring any additional documents?",
      "timestamp": DateTime.now().subtract(const Duration(minutes: 45)),
      "isMe": true,
      "messageType": "text",
      "status": "read"
    },
  ];

  final List<String> _quickResponses = [
    'Schedule Follow-up',
    'Request Documents',
    'Confirm Appointment',
    'Thank you',
    'I understand',
    'Please clarify'
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage(String content, {String type = 'text'}) {
    if (content.trim().isEmpty) return;

    final newMessage = {
      "id": _messages.length + 1,
      "senderId": "current_user",
      "senderName": "You",
      "content": content,
      "timestamp": DateTime.now(),
      "isMe": true,
      "messageType": type,
      "status": "sending"
    };

    setState(() {
      _messages.add(newMessage);
      _messageController.clear();
    });

    _scrollToBottom();

    // Simulate message delivery
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _messages.last['status'] = 'delivered';
        });
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: _buildChatAppBar(),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isMe = message['isMe'] ?? false;
                final showTimestamp = index == 0 ||
                    _shouldShowTimestamp(_messages[index - 1], message);

                return Column(
                  children: [
                    if (showTimestamp) _buildTimestamp(message['timestamp']),
                    _buildMessageBubble(message, isMe),
                    SizedBox(height: 1.h),
                  ],
                );
              },
            ),
          ),
          if (_isTyping) _buildTypingIndicator(),
          _buildQuickResponses(),
          _buildMessageComposer(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildChatAppBar() {
    final bool isOnline = widget.conversation['isOnline'] ?? false;

    return AppBar(
      backgroundColor: AppTheme.lightTheme.colorScheme.surface,
      elevation: 1,
      leading: IconButton(
        onPressed: widget.onBack,
        icon: CustomIconWidget(
          iconName: 'arrow_back',
          size: 6.w,
          color: AppTheme.lightTheme.colorScheme.onSurface,
        ),
      ),
      title: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 10.w,
                height: 10.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.lightTheme.colorScheme.outline
                        .withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5.w),
                  child: CustomImageWidget(
                    imageUrl: widget.conversation['profileImage'] ?? '',
                    width: 10.w,
                    height: 10.w,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              if (isOnline)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 2.5.w,
                    height: 2.5.w,
                    decoration: BoxDecoration(
                      color: AppTheme.getSuccessColor(true),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.lightTheme.colorScheme.surface,
                        width: 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.conversation['name'] ?? '',
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  isOnline ? 'Online' : 'Last seen recently',
                  style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                    color: isOnline
                        ? AppTheme.getSuccessColor(true)
                        : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {
            // Handle video call
          },
          icon: CustomIconWidget(
            iconName: 'videocam',
            size: 6.w,
            color: AppTheme.lightTheme.colorScheme.primary,
          ),
        ),
        IconButton(
          onPressed: () {
            // Handle voice call
          },
          icon: CustomIconWidget(
            iconName: 'call',
            size: 6.w,
            color: AppTheme.lightTheme.colorScheme.primary,
          ),
        ),
        PopupMenuButton<String>(
          icon: CustomIconWidget(
            iconName: 'more_vert',
            size: 6.w,
            color: AppTheme.lightTheme.colorScheme.onSurface,
          ),
          onSelected: (value) {
            // Handle menu actions
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
                value: 'view_case', child: Text('View Case Details')),
            const PopupMenuItem(
                value: 'schedule', child: Text('Schedule Meeting')),
            const PopupMenuItem(value: 'block', child: Text('Block Contact')),
          ],
        ),
      ],
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, bool isMe) {
    final String content = message['content'] ?? '';
    final String status = message['status'] ?? '';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: 75.w),
        margin: EdgeInsets.only(
          left: isMe ? 15.w : 0,
          right: isMe ? 0 : 15.w,
        ),
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        decoration: BoxDecoration(
          color: isMe
              ? AppTheme.lightTheme.colorScheme.primary
              : AppTheme.lightTheme.colorScheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(4.w),
            topRight: Radius.circular(4.w),
            bottomLeft: Radius.circular(isMe ? 4.w : 1.w),
            bottomRight: Radius.circular(isMe ? 1.w : 4.w),
          ),
          border: isMe
              ? null
              : Border.all(
                  color: AppTheme.lightTheme.colorScheme.outline
                      .withValues(alpha: 0.2),
                  width: 1,
                ),
          boxShadow: [
            BoxShadow(
              color:
                  AppTheme.lightTheme.colorScheme.shadow.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              content,
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: isMe
                    ? AppTheme.lightTheme.colorScheme.onPrimary
                    : AppTheme.lightTheme.colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 1.h),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(message['timestamp']),
                  style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                    color: isMe
                        ? AppTheme.lightTheme.colorScheme.onPrimary
                            .withValues(alpha: 0.7)
                        : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (isMe) ...[
                  SizedBox(width: 1.w),
                  CustomIconWidget(
                    iconName: _getStatusIcon(status),
                    size: 3.w,
                    color: AppTheme.lightTheme.colorScheme.onPrimary
                        .withValues(alpha: 0.7),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimestamp(DateTime timestamp) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 2.h),
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.surface,
            borderRadius: BorderRadius.circular(2.h),
            border: Border.all(
              color: AppTheme.lightTheme.colorScheme.outline
                  .withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Text(
            _formatDate(timestamp),
            style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: Row(
        children: [
          Container(
            width: 10.w,
            height: 10.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.lightTheme.colorScheme.outline
                    .withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5.w),
              child: CustomImageWidget(
                imageUrl: widget.conversation['profileImage'] ?? '',
                width: 10.w,
                height: 10.w,
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(width: 3.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surface,
              borderRadius: BorderRadius.circular(4.w),
              border: Border.all(
                color: AppTheme.lightTheme.colorScheme.outline
                    .withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Typing',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                SizedBox(width: 2.w),
                SizedBox(
                  width: 4.w,
                  height: 4.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.lightTheme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickResponses() {
    return Container(
      height: 6.h,
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _quickResponses.length,
        itemBuilder: (context, index) {
          return Container(
            margin: EdgeInsets.only(right: 2.w),
            child: OutlinedButton(
              onPressed: () => _sendMessage(_quickResponses[index]),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                side: BorderSide(
                  color: AppTheme.lightTheme.colorScheme.primary,
                  width: 1,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(3.h),
                ),
              ),
              child: Text(
                _quickResponses[index],
                style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.primary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessageComposer() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color:
                AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Attachment Button
            IconButton(
              onPressed: () {
                _showAttachmentOptions();
              },
              icon: CustomIconWidget(
                iconName: 'attach_file',
                size: 6.w,
                color: AppTheme.lightTheme.colorScheme.primary,
              ),
            ),

            // Text Input
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(6.w),
                  border: Border.all(
                    color: AppTheme.lightTheme.colorScheme.outline
                        .withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _messageController,
                  maxLines: 4,
                  minLines: 1,
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle:
                        AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    ),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _isTyping = value.isNotEmpty;
                    });
                  },
                ),
              ),
            ),

            // Voice/Send Button
            IconButton(
              onPressed: () {
                if (_messageController.text.trim().isNotEmpty) {
                  _sendMessage(_messageController.text);
                } else {
                  _startVoiceRecording();
                }
              },
              icon: Container(
                width: 10.w,
                height: 10.w,
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: CustomIconWidget(
                    iconName: _messageController.text.trim().isNotEmpty
                        ? 'send'
                        : (_isRecording ? 'stop' : 'mic'),
                    size: 5.w,
                    color: AppTheme.lightTheme.colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.lightTheme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(5.w)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(4.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12.w,
                height: 1.h,
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.outline
                      .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(0.5.h),
                ),
              ),
              SizedBox(height: 3.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildAttachmentOption('camera', 'Camera', () {
                    Navigator.pop(context);
                    // Handle camera
                  }),
                  _buildAttachmentOption('photo_library', 'Gallery', () {
                    Navigator.pop(context);
                    // Handle gallery
                  }),
                  _buildAttachmentOption('description', 'Document', () {
                    Navigator.pop(context);
                    // Handle document
                  }),
                ],
              ),
              SizedBox(height: 4.h),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttachmentOption(String icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 15.w,
            height: 15.w,
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.primary
                  .withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: CustomIconWidget(
                iconName: icon,
                size: 7.w,
                color: AppTheme.lightTheme.colorScheme.primary,
              ),
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            label,
            style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  void _startVoiceRecording() {
    setState(() {
      _isRecording = !_isRecording;
    });

    if (_isRecording) {
      // Start recording logic here
    } else {
      // Stop recording and send voice message
      _sendMessage('Voice message', type: 'voice');
    }
  }

  bool _shouldShowTimestamp(
      Map<String, dynamic> prevMessage, Map<String, dynamic> currentMessage) {
    final prevTime = prevMessage['timestamp'] as DateTime;
    final currentTime = currentMessage['timestamp'] as DateTime;

    return currentTime.difference(prevTime).inMinutes > 30;
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
  }

  String _formatDate(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      final weekdays = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday'
      ];
      return weekdays[timestamp.weekday - 1];
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  String _getStatusIcon(String status) {
    switch (status) {
      case 'sending':
        return 'schedule';
      case 'delivered':
        return 'done';
      case 'read':
        return 'done_all';
      default:
        return 'schedule';
    }
  }
}
