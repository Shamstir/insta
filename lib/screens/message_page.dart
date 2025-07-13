import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'dart:ui';
import 'chat_page.dart';
// Import your existing User model
import 'package:instagram_clone/models/user.dart';

class UserWithChatInfo {
  final User user;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;

  UserWithChatInfo({
    required this.user,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
  });
}

class Note {
  final String id;
  final String userId;
  final String content;
  final DateTime createdAt;
  final DateTime expiresAt;
  final User user;

  Note({
    required this.id,
    required this.userId,
    required this.content,
    required this.createdAt,
    required this.expiresAt,
    required this.user,
  });

  factory Note.fromFirestore(DocumentSnapshot doc, User user) {
    final data = doc.data() as Map<String, dynamic>;
    return Note(
      id: doc.id,
      userId: data['userId'],
      content: data['content'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      expiresAt: (data['expiresAt'] as Timestamp).toDate(),
      user: user,
    );
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

class MessagesPage extends StatefulWidget {
  @override
  _MessagesPageState createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;

  String _searchQuery = '';
  List<UserWithChatInfo> _mutualUsers = [];
  List<Note> _notes = [];
  bool _isLoading = true;
  bool _isLoadingNotes = true;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _loadMutualConnections();
    _loadNotes();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  String getChatId(String uid1, String uid2) {
    List<String> ids = [uid1, uid2]..sort();
    return ids.join('_');
  }

  Future<void> _loadNotes() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Get current user's followers and following
      final currentUserDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      if (!currentUserDoc.exists) return;

      final currentUserData = User.fromSnap(currentUserDoc);
      final followingIds = Set<String>.from(currentUserData.following);

      // Add current user to see their own notes
      followingIds.add(currentUser.uid);

      List<Note> notes = [];

      // Get notes from all followed users
      final notesSnapshot = await _firestore
          .collection('notes')
          .where('userId', whereIn: followingIds.toList())
          .where('expiresAt', isGreaterThan: DateTime.now())
          .orderBy('expiresAt')
          .orderBy('createdAt', descending: true)
          .get();

      for (var noteDoc in notesSnapshot.docs) {
        final userId = noteDoc.data()['userId'];
        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          final user = User.fromSnap(userDoc);
          notes.add(Note.fromFirestore(noteDoc, user));
        }
      }

      setState(() {
        _notes = notes;
        _isLoadingNotes = false;
      });
    } catch (e) {
      print('Error loading notes: $e');
      setState(() {
        _isLoadingNotes = false;
      });
    }
  }

  Future<void> _addNote() async {
    if (_noteController.text.trim().isEmpty) return;

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Notes expire after 24 hours
      final expiresAt = DateTime.now().add(Duration(hours: 24));

      await _firestore.collection('notes').add({
        'userId': currentUser.uid,
        'content': _noteController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': expiresAt,
      });

      _noteController.clear();
      _loadNotes(); // Refresh notes
      Navigator.pop(context); // Close dialog
    } catch (e) {
      print('Error adding note: $e');
    }
  }

  void _showAddNoteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Share a note',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        content: TextField(
          controller: _noteController,
          style: TextStyle(color: Colors.grey),
          maxLength: 60,
          decoration: InputDecoration(
            hintText: 'What\'s on your mind?',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.blue),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.white.withOpacity(0.7))),
          ),
          ElevatedButton(
            onPressed: _addNote,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Share', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _loadMutualConnections() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Get current user's data to access followers and following arrays
      final currentUserDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      if (!currentUserDoc.exists) return;

      final currentUserData = User.fromSnap(currentUserDoc);

      // Convert arrays to sets for easier intersection
      final followingIds = Set<String>.from(currentUserData.following);
      final followersIds = Set<String>.from(currentUserData.followers);

      // Find mutual connections (intersection)
      final mutualIds = followingIds.intersection(followersIds);

      // Get user details for mutual connections
      List<UserWithChatInfo> mutualUsers = [];
      for (String userId in mutualIds) {
        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          User user = User.fromSnap(userDoc);

          // Get last message for this user
          final chatId = getChatId(currentUser.uid, userId);
          final lastMessageSnapshot = await _firestore
              .collection('chats')
              .doc(chatId)
              .collection('messages')
              .orderBy('timestamp', descending: true)
              .limit(1)
              .get();

          // Get unread count
          final unreadSnapshot = await _firestore
              .collection('chats')
              .doc(chatId)
              .collection('messages')
              .where('senderId', isNotEqualTo: currentUser.uid)
              .where('isRead', isEqualTo: false)
              .get();

          String? lastMessage;
          DateTime? lastMessageTime;

          if (lastMessageSnapshot.docs.isNotEmpty) {
            final lastMessageDoc = lastMessageSnapshot.docs.first;
            lastMessage = lastMessageDoc.data()['content'];
            lastMessageTime = (lastMessageDoc.data()['timestamp'] as Timestamp).toDate();
          }

          mutualUsers.add(UserWithChatInfo(
            user: user,
            lastMessage: lastMessage,
            lastMessageTime: lastMessageTime,
            unreadCount: unreadSnapshot.docs.length,
          ));
        }
      }

      // Sort by last message time (most recent first)
      mutualUsers.sort((a, b) {
        if (a.lastMessageTime == null && b.lastMessageTime == null) return 0;
        if (a.lastMessageTime == null) return 1;
        if (b.lastMessageTime == null) return -1;
        return b.lastMessageTime!.compareTo(a.lastMessageTime!);
      });

      setState(() {
        _mutualUsers = mutualUsers;
        _isLoading = false;
      });

      _fadeController.forward();
      _slideController.forward();
    } catch (e) {
      print('Error loading mutual connections: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<UserWithChatInfo> get filteredUsers {
    if (_searchQuery.isEmpty) {
      return _mutualUsers;
    }
    return _mutualUsers
        .where((userWithChat) =>
    userWithChat.user.username.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        userWithChat.user.email.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';

    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${time.day}/${time.month}';
    }
  }

  String _formatNoteTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  Widget _buildNotesSection() {
    return Container(
      height: 100,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: _isLoadingNotes
          ? Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.5)),
          strokeWidth: 2,
        ),
      )
          : ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16),
        itemCount: _notes.length + 1, // +1 for add note button
        itemBuilder: (context, index) {
          if (index == 0) {
            // Add note button
            return Container(
              width: 70,
              margin: EdgeInsets.only(right: 12),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _showAddNoteDialog,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF667eea),
                            Color(0xFF764ba2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF667eea).withOpacity(0.4),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Your note',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          final note = _notes[index - 1];
          return Container(
            width: 70,
            margin: EdgeInsets.only(right: 12),
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.pink.withOpacity(0.8),
                            Colors.orange.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.pink.withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: note.user.photoUrl.isNotEmpty
                            ? Image.network(
                          note.user.photoUrl,
                          fit: BoxFit.cover,
                        )
                            : Center(
                          child: Text(
                            note.user.username.isNotEmpty
                                ? note.user.username[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Note bubble
                    Positioned(
                      bottom: -5,
                      left: -10,
                      right: -10,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Color(0xFF1A1A2E).withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          note.content,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  note.user.username,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0A0A0A),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 1.5,
            colors: [
              Color(0xFF1A1A2E).withOpacity(0.8),
              Color(0xFF0F0F23).withOpacity(0.9),
              Color(0xFF0A0A0A),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                margin: EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Messages',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isLoading = true;
                          _isLoadingNotes = true;
                        });
                        _loadMutualConnections();
                        _loadNotes();
                      },
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.refresh_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Notes Section
              _buildNotesSection(),

              // Search Bar
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search messages...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                    prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.7)),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),

              // Content Area
              Expanded(
                child: _isLoading
                    ? Center(
                  child: Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white.withOpacity(0.8),
                      ),
                      strokeWidth: 2,
                    ),
                  ),
                )
                    : filteredUsers.isEmpty
                    ? FadeTransition(
                  opacity: _fadeAnimation,
                  child: Center(
                    child: Container(
                      margin: EdgeInsets.all(32),
                      padding: EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(0.08),
                            Colors.white.withOpacity(0.03),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.blue.withOpacity(0.2),
                                  Colors.purple.withOpacity(0.2),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 48,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                          SizedBox(height: 24),
                          Text(
                            'No conversations yet',
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Connect with mutual followers to start chatting',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.6),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                    : SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: RefreshIndicator(
                      onRefresh: () async {
                        await _loadMutualConnections();
                        await _loadNotes();
                      },
                      backgroundColor: Colors.white.withOpacity(0.1),
                      color: Colors.white,
                      child: ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredUsers.length,
                        itemBuilder: (context, index) {
                          final userWithChat = filteredUsers[index];
                          return AnimatedContainer(
                            duration: Duration(milliseconds: 300 + (index * 50)),
                            curve: Curves.easeOutCubic,
                            child: LiquidUserTile(
                              userWithChat: userWithChat,
                              onTap: () => _openChat(userWithChat.user),
                              formatTime: _formatTime,
                              index: index,
                            ),
                          );
                        },
                      ),
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

  void _openChat(User user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(
          recipientUser: user,
          chatId: getChatId(_auth.currentUser!.uid, user.uid),
        ),
      ),
    );
  }
}

class LiquidUserTile extends StatefulWidget {
  final UserWithChatInfo userWithChat;
  final VoidCallback onTap;
  final String Function(DateTime?) formatTime;
  final int index;

  const LiquidUserTile({
    Key? key,
    required this.userWithChat,
    required this.onTap,
    required this.formatTime,
    required this.index,
  }) : super(key: key);

  @override
  _LiquidUserTileState createState() => _LiquidUserTileState();
}

class _LiquidUserTileState extends State<LiquidUserTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOut),
    );
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.userWithChat.user;
    return AnimatedBuilder(
      animation: _hoverController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            margin: EdgeInsets.only(bottom: 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.1 + (_glowAnimation.value * 0.05)),
                        Colors.white.withOpacity(0.05 + (_glowAnimation.value * 0.03)),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1 + (_glowAnimation.value * 0.1)),
                      width: 1,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: widget.onTap,
                      onTapDown: (_) => _hoverController.forward(),
                      onTapUp: (_) => _hoverController.reverse(),
                      onTapCancel: () => _hoverController.reverse(),
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // Avatar with Glow Effect
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.3 * _glowAnimation.value),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.transparent,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.blue.withOpacity(0.6),
                                          Colors.purple.withOpacity(0.6),
                                        ],
                                      ),
                                    ),
                                    child: user.photoUrl.isNotEmpty
                                        ? Image.network(
                                      user.photoUrl,
                                      fit: BoxFit.cover,
                                      width: 48,
                                      height: 48,
                                    )
                                        : Center(
                                      child: Text(
                                        user.username.isNotEmpty
                                            ? user.username[0].toUpperCase()
                                            : '?',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          user.username,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                            letterSpacing: -0.2,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        widget.formatTime(widget.userWithChat.lastMessageTime),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white.withOpacity(0.6),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          widget.userWithChat.lastMessage ?? 'No messages yet',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: widget.userWithChat.unreadCount > 0
                                                ? Colors.white.withOpacity(0.9)
                                                : Colors.white.withOpacity(0.6),
                                            fontWeight: widget.userWithChat.unreadCount > 0
                                                ? FontWeight.w500
                                                : FontWeight.normal,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (widget.userWithChat.unreadCount > 0)
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.blue,
                                                Colors.blue.withOpacity(0.8),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(12),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.blue.withOpacity(0.4),
                                                blurRadius: 8,
                                                spreadRadius: 1,
                                              ),
                                            ],
                                          ),
                                          child: Text(
                                            widget.userWithChat.unreadCount.toString(),
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}