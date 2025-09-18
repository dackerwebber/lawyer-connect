import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/chat_interface_widget.dart';
import './widgets/conversation_item_widget.dart';
import './widgets/message_search_bar_widget.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({Key? key, required List<Map<String, dynamic>> messageList}) : super(key: key);

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  int _currentBottomIndex = 1; // Messages tab is active
  List<Map<String, dynamic>> _filteredConversations = [];
  Map<String, dynamic>? _selectedConversation;

  final List<Map<String, dynamic>> _conversations = [
    {
      "id": 1,
      "name": "Sarah Johnson",
      "profileImage":
          "https://images.unsplash.com/photo-1494790108755-2616b612b786?w=150&h=150&fit=crop&crop=face",
      "lastMessage":
          "I've reviewed your case details and I'm confident I can help you with your property dispute.",
      "lastMessageTime": "2:30 PM",
      "isOnline": true,
      "unreadCount": 2,
      "caseType": "Property",
      "caseReference": "PROP-2024-001",
      "userType": "lawyer"
    },
    {
      "id": 2,
      "name": "Michael Rodriguez",
      "profileImage":
          "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face",
      "lastMessage":
          "Thank you for the consultation. I'll gather the documents you mentioned.",
      "lastMessageTime": "1:45 PM",
      "isOnline": false,
      "unreadCount": 0,
      "caseType": "Family",
      "caseReference": "FAM-2024-003",
      "userType": "client"
    },
    {
      "id": 3,
      "name": "Emily Chen",
      "profileImage":
          "https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150&h=150&fit=crop&crop=face",
      "lastMessage":
          "The contract review is complete. I found several clauses that need attention.",
      "lastMessageTime": "12:20 PM",
      "isOnline": true,
      "unreadCount": 1,
      "caseType": "Corporate",
      "caseReference": "CORP-2024-007",
      "userType": "lawyer"
    },
    {
      "id": 4,
      "name": "David Thompson",
      "profileImage":
          "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&h=150&fit=crop&crop=face",
      "lastMessage": "Can we schedule a follow-up meeting for next week?",
      "lastMessageTime": "11:30 AM",
      "isOnline": false,
      "unreadCount": 0,
      "caseType": "Criminal",
      "caseReference": "CRIM-2024-012",
      "userType": "client"
    },
    {
      "id": 5,
      "name": "Lisa Wang",
      "profileImage":
          "https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150&h=150&fit=crop&crop=face",
      "lastMessage":
          "Your immigration application has been submitted successfully.",
      "lastMessageTime": "Yesterday",
      "isOnline": false,
      "unreadCount": 0,
      "caseType": "Immigration",
      "caseReference": "IMM-2024-005",
      "userType": "lawyer"
    },
    {
      "id": 6,
      "name": "James Wilson",
      "profileImage":
          "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150&h=150&fit=crop&crop=face",
      "lastMessage": "I need help with my business partnership agreement.",
      "lastMessageTime": "Yesterday",
      "isOnline": true,
      "unreadCount": 3,
      "caseType": "Corporate",
      "caseReference": "CORP-2024-009",
      "userType": "client"
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _filteredConversations = List.from(_conversations);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _filterConversations(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredConversations = List.from(_conversations);
      } else {
        _filteredConversations = _conversations.where((conversation) {
          final name = (conversation['name'] ?? '').toLowerCase();
          final caseRef = (conversation['caseReference'] ?? '').toLowerCase();
          final caseType = (conversation['caseType'] ?? '').toLowerCase();
          final searchQuery = query.toLowerCase();

          return name.contains(searchQuery) ||
              caseRef.contains(searchQuery) ||
              caseType.contains(searchQuery);
        }).toList();
      }
    });
  }

  void _openChat(Map<String, dynamic> conversation) {
    setState(() {
      _selectedConversation = conversation;
    });
  }

  void _closeChat() {
    setState(() {
      _selectedConversation = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedConversation != null) {
      return ChatInterfaceWidget(
        conversation: _selectedConversation!,
        onBack: _closeChat,
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          MessageSearchBarWidget(
            controller: _searchController,
            onChanged: _filterConversations,
            onClear: () => _filterConversations(''),
          ),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildConversationsList(_filteredConversations
                    .where((c) => c['userType'] == 'lawyer')
                    .toList()),
                _buildConversationsList(_filteredConversations),
                _buildConversationsList(_filteredConversations
                    .where((c) => c['unreadCount'] > 0)
                    .toList()),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final int totalUnread = _conversations.fold(
        0, (sum, conv) => sum + (conv['unreadCount'] as int? ?? 0));

    return AppBar(
      backgroundColor: AppTheme.lightTheme.colorScheme.surface,
      elevation: 1,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Messages',
            style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (totalUnread > 0)
            Text(
              '$totalUnread unread message${totalUnread > 1 ? 's' : ''}',
              style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.primary,
              ),
            ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {
            // Handle notifications
          },
          icon: Stack(
            children: [
              CustomIconWidget(
                iconName: 'notifications',
                size: 6.w,
                color: AppTheme.lightTheme.colorScheme.onSurface,
              ),
              if (totalUnread > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 2.5.w,
                    height: 2.5.w,
                    decoration: BoxDecoration(
                      color: AppTheme.lightTheme.colorScheme.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
        PopupMenuButton<String>(
          icon: CustomIconWidget(
            iconName: 'more_vert',
            size: 6.w,
            color: AppTheme.lightTheme.colorScheme.onSurface,
          ),
          onSelected: (value) {
            switch (value) {
              case 'mark_all_read':
                _markAllAsRead();
                break;
              case 'settings':
                // Handle settings
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
                value: 'mark_all_read', child: Text('Mark all as read')),
            const PopupMenuItem(
                value: 'settings', child: Text('Message settings')),
          ],
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppTheme.lightTheme.colorScheme.surface,
      child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.lightTheme.colorScheme.primary,
        unselectedLabelColor: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
        indicatorColor: AppTheme.lightTheme.colorScheme.primary,
        indicatorWeight: 3,
        labelStyle: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle:
            AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w400,
        ),
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomIconWidget(
                  iconName: 'gavel',
                  size: 4.w,
                  color: _tabController.index == 0
                      ? AppTheme.lightTheme.colorScheme.primary
                      : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
                SizedBox(width: 2.w),
                const Text('Lawyers'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomIconWidget(
                  iconName: 'chat',
                  size: 4.w,
                  color: _tabController.index == 1
                      ? AppTheme.lightTheme.colorScheme.primary
                      : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
                SizedBox(width: 2.w),
                const Text('All'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomIconWidget(
                  iconName: 'mark_chat_unread',
                  size: 4.w,
                  color: _tabController.index == 2
                      ? AppTheme.lightTheme.colorScheme.primary
                      : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
                SizedBox(width: 2.w),
                const Text('Unread'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationsList(List<Map<String, dynamic>> conversations) {
    if (conversations.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        // Simulate refresh
        await Future.delayed(const Duration(seconds: 1));
      },
      color: AppTheme.lightTheme.colorScheme.primary,
      child: ListView.builder(
        padding: EdgeInsets.only(top: 1.h),
        itemCount: conversations.length,
        itemBuilder: (context, index) {
          final conversation = conversations[index];
          return ConversationItemWidget(
            conversation: conversation,
            onTap: () => _openChat(conversation),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: 'chat_bubble_outline',
            size: 20.w,
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant
                .withValues(alpha: 0.5),
          ),
          SizedBox(height: 3.h),
          Text(
            'No conversations found',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Start a conversation with a lawyer\nor client to see messages here',
            textAlign: TextAlign.center,
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _currentBottomIndex,
      onTap: (index) {
        setState(() {
          _currentBottomIndex = index;
        });

        switch (index) {
          case 0:
            Navigator.pushNamed(context, '/splash-screen');
            break;
          case 1:
            // Already on messages screen
            break;
        }
      },
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppTheme.lightTheme.colorScheme.surface,
      selectedItemColor: AppTheme.lightTheme.colorScheme.primary,
      unselectedItemColor: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
      elevation: 8,
      items: [
        BottomNavigationBarItem(
          icon: CustomIconWidget(
            iconName: 'home',
            size: 6.w,
            color: _currentBottomIndex == 0
                ? AppTheme.lightTheme.colorScheme.primary
                : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Stack(
            children: [
              CustomIconWidget(
                iconName: 'chat',
                size: 6.w,
                color: _currentBottomIndex == 1
                    ? AppTheme.lightTheme.colorScheme.primary
                    : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
              if (_conversations
                  .any((c) => (c['unreadCount'] as int? ?? 0) > 0))
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 2.5.w,
                    height: 2.5.w,
                    decoration: BoxDecoration(
                      color: AppTheme.lightTheme.colorScheme.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          label: 'Messages',
        ),
      ],
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () {
        _showNewMessageDialog();
      },
      backgroundColor: AppTheme.lightTheme.colorScheme.primary,
      child: CustomIconWidget(
        iconName: 'add',
        size: 6.w,
        color: AppTheme.lightTheme.colorScheme.onPrimary,
      ),
    );
  }

  void _showNewMessageDialog() {
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
              Text(
                'Start New Conversation',
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 3.h),
              ListTile(
                leading: Container(
                  width: 12.w,
                  height: 12.w,
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.primary
                        .withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: CustomIconWidget(
                      iconName: 'gavel',
                      size: 6.w,
                      color: AppTheme.lightTheme.colorScheme.primary,
                    ),
                  ),
                ),
                title: Text(
                  'Find a Lawyer',
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurface,
                  ),
                ),
                subtitle: Text(
                  'Browse available lawyers by specialty',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // Handle find lawyer
                },
              ),
              ListTile(
                leading: Container(
                  width: 12.w,
                  height: 12.w,
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.secondary
                        .withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: CustomIconWidget(
                      iconName: 'person_add',
                      size: 6.w,
                      color: AppTheme.lightTheme.colorScheme.secondary,
                    ),
                  ),
                ),
                title: Text(
                  'Contact Client',
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurface,
                  ),
                ),
                subtitle: Text(
                  'Message an existing client',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // Handle contact client
                },
              ),
              SizedBox(height: 4.h),
            ],
          ),
        );
      },
    );
  }

  void _markAllAsRead() {
    setState(() {
      for (var conversation in _conversations) {
        conversation['unreadCount'] = 0;
      }
      _filteredConversations = List.from(_conversations);
    });
  }
}
