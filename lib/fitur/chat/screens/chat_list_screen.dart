import 'package:bersatubantu/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'chat_detail_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> with AutomaticKeepAliveClientMixin {
  final supabase = Supabase.instance.client;
  
  List<Map<String, dynamic>> _chatList = [];
  bool _isLoading = true;
  String _searchQuery = '';
  
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    print('[ChatList] initState');
    _loadChatList();
  }

  Future<void> _loadChatList() async {
    try {
      setState(() => _isLoading = true);
      
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) {
        print('[ChatList] No authenticated user');
        return;
      }

      print('[ChatList] Current user ID: ${currentUser.id}');

      // Get conversations user is part of via conversation_participants
      final participantRows = await supabase
          .from('conversation_participants')
          .select('conversation_id')
          .eq('user_id', currentUser.id);

      final conversationIds = (participantRows as List)
          .map((r) => r['conversation_id'] as String)
          .toList();

      print('[ChatList] User in ${conversationIds.length} conversations');

      if (conversationIds.isEmpty) {
        setState(() => _chatList = []);
        return;
      }

      // Get latest message per conversation
      final messages = await supabase
          .from('messages')
          .select('id, conversation_id, sender_id, content, created_at, is_read')
          .inFilter('conversation_id', conversationIds)
          .order('created_at', ascending: false);

      print('[ChatList] Total messages found: ${messages.length}');

      if (messages.isEmpty) {
        setState(() => _chatList = []);
        return;
      }

      // Group by conversation_id — keep only latest message per conversation
      Map<String, Map<String, dynamic>> conversations = {};
      for (var msg in messages) {
        final conversationId = msg['conversation_id'] as String? ?? 'unknown';
        final senderId = msg['sender_id'] as String?;

        if (!conversations.containsKey(conversationId)) {
          conversations[conversationId] = {
            'conversation_id': conversationId,
            'sender_id': senderId,
            'last_message': msg['content'] ?? '',
            'last_message_time': msg['created_at'],
            'unread_count': msg['is_read'] == false ? 1 : 0,
            'name': '',
          };
        } else {
          if (msg['is_read'] == false) {
            conversations[conversationId]!['unread_count'] =
                (conversations[conversationId]!['unread_count'] ?? 0) + 1;
          }
        }
      }

      // Load other participant's name for each conversation
      List<Map<String, dynamic>> chatList = [];
      for (var convo in conversations.values) {
        try {
          // Find other participant in conversation (not current user)
          final otherParticipants = await supabase
              .from('conversation_participants')
              .select('user_id')
              .eq('conversation_id', convo['conversation_id'])
              .neq('user_id', currentUser.id)
              .limit(1);

          final otherId = otherParticipants.isNotEmpty
              ? otherParticipants[0]['user_id'] as String?
              : convo['sender_id'];

          if (otherId != null) {
            final profileData = await supabase
                .from('profiles')
                .select('full_name')
                .eq('id', otherId)
                .maybeSingle();
            convo['name'] = profileData?['full_name'] ?? 'User';
            convo['sender_id'] = otherId;
          }
          chatList.add(convo);
        } catch (e) {
          print('[ChatList] Error loading name: $e');
          convo['name'] = 'Unknown';
          chatList.add(convo);
        }
      }

      // Sort by last message time
      chatList.sort((a, b) {
        final aTime = DateTime.parse(a['last_message_time'] ?? '2000-01-01');
        final bTime = DateTime.parse(b['last_message_time'] ?? '2000-01-01');
        return bTime.compareTo(aTime);
      });

      if (mounted) {
        setState(() {
          _chatList = chatList;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('[ChatList] Error loading chat list: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Map<String, dynamic>> get _filteredChats {
    if (_searchQuery.isEmpty) return _chatList;
    return _chatList
        .where((chat) => (chat['name'] as String).toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        title: const Text(
          'Pesan',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
              decoration: InputDecoration(
                hintText: 'Cari pesan...',
                prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: const BorderSide(color: AppTheme.primaryColor),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          
          // Chat List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredChats.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'Ada Pertanyaan?\nHubungi Bobi!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                                fontFamily: 'CircularStd',
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredChats.length,
                        itemBuilder: (context, index) {
                          final chat = _filteredChats[index];
                          return GestureDetector(
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatDetailScreen(
                                    conversationId: chat['conversation_id'],
                                    senderId: chat['sender_id'],
                                    senderName: chat['name'],
                                  ),
                                ),
                              );
                              
                              if (result == true) {
                                _loadChatList();
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  // Avatar
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Icon(
                                        chat['avatar_type'] == 'organization'
                                            ? Icons.business
                                            : Icons.person,
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  
                                  // Chat Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          chat['name'],
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'CircularStd',
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          chat['last_message'] ?? '',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[600],
                                            fontFamily: 'CircularStd',
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // Time
                                  Text(
                                    _formatTime(chat['last_message_time']),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                      fontFamily: 'CircularStd',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String? timeStr) {
    if (timeStr == null) return '';
    try {
      final time = DateTime.parse(timeStr);
      final now = DateTime.now();
      final diff = now.difference(time);

      if (diff.inMinutes < 1) return 'Baru';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m';
      if (diff.inHours < 24) return '${diff.inHours}h';
      if (diff.inDays < 7) return '${diff.inDays}d';
      
      return '${time.day}/${time.month}';
    } catch (e) {
      return '';
    }
  }
}
