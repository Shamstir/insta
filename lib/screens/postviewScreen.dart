import 'package:flutter/material.dart';
import 'package:instagram_clone/utils/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PostViewScreen extends StatefulWidget {
  final Map<String, dynamic> postData;

  const PostViewScreen({
    Key? key,
    required this.postData,
  }) : super(key: key);

  @override
  State<PostViewScreen> createState() => _PostViewScreenState();
}

class _PostViewScreenState extends State<PostViewScreen> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool isLiked = false;
  int likesCount = 0;

  @override
  void initState() {
    super.initState();
    likesCount = widget.postData['likes']?.length ?? 0;
    isLiked = widget.postData['likes']?.contains(FirebaseAuth.instance.currentUser?.uid) ?? false;
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Helper method to determine device type
  DeviceType _getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1200) return DeviceType.desktop;
    if (width >= 768) return DeviceType.tablet;
    return DeviceType.mobile;
  }

  // Helper method to get responsive dimensions
  ResponsiveDimensions _getResponsiveDimensions(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final deviceType = _getDeviceType(context);

    switch (deviceType) {
      case DeviceType.desktop:
        return ResponsiveDimensions(
          maxWidth: 800,
          imageAspectRatio: 16 / 9,
          horizontalPadding: 24,
          verticalPadding: 16,
          avatarRadius: 20,
          fontSize: 16,
          spacing: 16,
          isLandscape: size.width > size.height,
        );
      case DeviceType.tablet:
        return ResponsiveDimensions(
          maxWidth: 600,
          imageAspectRatio: size.width > size.height ? 16 / 9 : 4 / 3,
          horizontalPadding: 20,
          verticalPadding: 14,
          avatarRadius: 18,
          fontSize: 15,
          spacing: 14,
          isLandscape: size.width > size.height,
        );
      case DeviceType.mobile:
        return ResponsiveDimensions(
          maxWidth: size.width,
          imageAspectRatio: size.width > size.height ? 16 / 9 : 1,
          horizontalPadding: 16,
          verticalPadding: 12,
          avatarRadius: 16,
          fontSize: 14,
          spacing: 12,
          isLandscape: size.width > size.height,
        );
    }
  }

  void _toggleLike() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final postRef = FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postData['postId']);

      if (isLiked) {
        await postRef.update({
          'likes': FieldValue.arrayRemove([currentUser.uid])
        });
        setState(() {
          likesCount--;
          isLiked = false;
        });
      } else {
        await postRef.update({
          'likes': FieldValue.arrayUnion([currentUser.uid])
        });
        setState(() {
          likesCount++;
          isLiked = true;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  void _postComment() async {
    if (_commentController.text.trim().isEmpty) return;

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Get current user data with multiple field name attempts
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      final userData = userDoc.data() ?? {};

      // Try different possible field names for username
      String username = userData['username'] ??
          userData['displayName'] ??
          userData['name'] ??
          currentUser.displayName ??
          currentUser.email?.split('@').first ??
          'User';

      // Try different possible field names for profile picture
      String profilePic = userData['photoUrl'] ??
          userData['profilePic'] ??
          userData['photoURL'] ??
          userData['profilePicture'] ??
          currentUser.photoURL ??
          '';

      print('User data: $userData'); // Debug print
      print('Username: $username'); // Debug print
      print('Profile pic: $profilePic'); // Debug print

      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postData['postId'])
          .collection('comments')
          .add({
        'text': _commentController.text.trim(),
        'uid': currentUser.uid,
        'username': username,
        'profilePic': profilePic,
        'datePublished': DateTime.now(),
      });

      _commentController.clear();

      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      print('Error posting comment: $e'); // Debug print
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error posting comment: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dimensions = _getResponsiveDimensions(context);
    final deviceType = _getDeviceType(context);
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: mobileBackgroundColor,
      appBar: _buildAppBar(context, dimensions),
      body: Center(
        child: Container(
          width: deviceType == DeviceType.mobile
              ? screenSize.width
              : dimensions.maxWidth,
          child: dimensions.isLandscape && deviceType != DeviceType.mobile
              ? _buildLandscapeLayout(context, dimensions)
              : _buildPortraitLayout(context, dimensions),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, ResponsiveDimensions dimensions) {
    return AppBar(
      backgroundColor: mobileBackgroundColor,
      title: Text(
        'Post',
        style: TextStyle(fontSize: dimensions.fontSize + 2),
      ),
      centerTitle: false,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        iconSize: dimensions.fontSize + 8,
        onPressed: () => Navigator.of(context).pop(),
      ),
      elevation: 0,
    );
  }

  Widget _buildLandscapeLayout(BuildContext context, ResponsiveDimensions dimensions) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left side - Image and post info
        Expanded(
          flex: 3,
          child: Column(
            children: [
              _buildPostImage(context, dimensions),
              _buildPostInfo(context, dimensions),
            ],
          ),
        ),

        // Right side - Comments
        Expanded(
          flex: 2,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: Colors.grey.shade800, width: 0.5),
              ),
            ),
            child: Column(
              children: [
                _buildCommentsHeader(dimensions),
                Expanded(child: _buildCommentsList(context, dimensions)),
                _buildCommentInput(context, dimensions),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPortraitLayout(BuildContext context, ResponsiveDimensions dimensions) {
    return Column(
      children: [
        _buildPostImage(context, dimensions),
        _buildPostInfo(context, dimensions),
        const Divider(height: 1, color: Colors.grey),
        _buildCommentsHeader(dimensions),
        Expanded(child: _buildCommentsList(context, dimensions)),
        _buildCommentInput(context, dimensions),
      ],
    );
  }

  Widget _buildPostImage(BuildContext context, ResponsiveDimensions dimensions) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade800, width: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      margin: EdgeInsets.all(dimensions.horizontalPadding / 2),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: AspectRatio(
          aspectRatio: dimensions.imageAspectRatio,
          child: Image.network(
            widget.postData['postUrl'] ?? '',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey.shade800,
                child: Icon(
                  Icons.error,
                  color: Colors.white,
                  size: dimensions.avatarRadius * 2,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPostInfo(BuildContext context, ResponsiveDimensions dimensions) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dimensions.horizontalPadding,
        vertical: dimensions.verticalPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info and actions
          Row(
            children: [
              CircleAvatar(
                radius: dimensions.avatarRadius,
                backgroundImage: NetworkImage(
                  widget.postData['profImage'] ?? '',
                ),
                onBackgroundImageError: (exception, stackTrace) {},
                child: widget.postData['profImage'] == null
                    ? Icon(Icons.person, size: dimensions.avatarRadius)
                    : null,
              ),
              SizedBox(width: dimensions.spacing),
              Expanded(
                child: Text(
                  widget.postData['username'] ?? 'Unknown',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: dimensions.fontSize,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  color: isLiked ? Colors.red : Colors.white,
                  size: dimensions.fontSize + 8,
                ),
                onPressed: _toggleLike,
              ),
            ],
          ),

          // Likes count
          Padding(
            padding: EdgeInsets.only(left: 4, top: dimensions.verticalPadding / 2),
            child: Text(
              '$likesCount likes',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: dimensions.fontSize - 1,
              ),
            ),
          ),

          // Caption
          if (widget.postData['description'] != null &&
              widget.postData['description'].toString().isNotEmpty)
            Padding(
              padding: EdgeInsets.only(left: 4, top: dimensions.verticalPadding),
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: widget.postData['username'] ?? 'Unknown',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: dimensions.fontSize - 1,
                      ),
                    ),
                    TextSpan(
                      text: ' ${widget.postData['description']}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: dimensions.fontSize - 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Post date
          Padding(
            padding: EdgeInsets.only(left: 4, top: dimensions.verticalPadding),
            child: Text(
              _formatDate(widget.postData['datePublished']),
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: dimensions.fontSize - 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsHeader(ResponsiveDimensions dimensions) {
    return Container(
      padding: EdgeInsets.all(dimensions.horizontalPadding),
      child: Row(
        children: [
          Text(
            'Comments',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: dimensions.fontSize,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsList(BuildContext context, ResponsiveDimensions dimensions) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postData['postId'])
          .collection('comments')
          .orderBy('datePublished', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'No comments yet. Be the first to comment!',
              style: TextStyle(
                color: Colors.grey,
                fontSize: dimensions.fontSize - 1,
              ),
            ),
          );
        }

        return ListView.builder(
          controller: _scrollController,
          padding: EdgeInsets.zero,
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final comment = snapshot.data!.docs[index];
            return _buildCommentItem(
              comment.data() as Map<String, dynamic>,
              dimensions,
            );
          },
        );
      },
    );
  }

  Widget _buildCommentItem(Map<String, dynamic> comment, ResponsiveDimensions dimensions) {
    // Try different possible field names for username
    String username = comment['username'] ??
        comment['displayName'] ??
        comment['name'] ??
        'User';

    // Try different possible field names for profile picture
    String profilePic = comment['profilePic'] ??
        comment['photoUrl'] ??
        comment['photoURL'] ??
        comment['profilePicture'] ??
        '';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dimensions.horizontalPadding,
        vertical: dimensions.verticalPadding,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: dimensions.avatarRadius - 2,
            backgroundImage: profilePic.isNotEmpty
                ? NetworkImage(profilePic)
                : null,
            onBackgroundImageError: (exception, stackTrace) {},
            child: profilePic.isEmpty
                ? Icon(Icons.person, size: dimensions.avatarRadius - 2)
                : null,
          ),
          SizedBox(width: dimensions.spacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: username,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: dimensions.fontSize - 1,
                        ),
                      ),
                      TextSpan(
                        text: ' ${comment['text'] ?? ''}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: dimensions.fontSize - 1,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: dimensions.verticalPadding / 2),
                Text(
                  _formatDate(comment['datePublished']),
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: dimensions.fontSize - 2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput(BuildContext context, ResponsiveDimensions dimensions) {
    return Container(
      padding: EdgeInsets.all(dimensions.horizontalPadding),
      decoration: BoxDecoration(
        color: mobileBackgroundColor,
        border: Border(
          top: BorderSide(color: Colors.grey.shade800, width: 0.5),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            CircleAvatar(
              radius: dimensions.avatarRadius - 2,
              backgroundImage: NetworkImage(
                FirebaseAuth.instance.currentUser?.photoURL ?? '',
              ),
              onBackgroundImageError: (exception, stackTrace) {},
              child: FirebaseAuth.instance.currentUser?.photoURL == null
                  ? Icon(Icons.person, size: dimensions.avatarRadius - 2)
                  : null,
            ),
            SizedBox(width: dimensions.spacing),
            Expanded(
              child: TextField(
                controller: _commentController,
                decoration: InputDecoration(
                  hintText: 'Add a comment...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                    color: Colors.grey,
                    fontSize: dimensions.fontSize - 1,
                  ),
                ),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: dimensions.fontSize - 1,
                ),
                maxLines: null,
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.send,
                color: Colors.blue,
                size: dimensions.fontSize + 4,
              ),
              onPressed: _postComment,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';

    DateTime dateTime;
    if (date is Timestamp) {
      dateTime = date.toDate();
    } else if (date is DateTime) {
      dateTime = date;
    } else {
      return '';
    }

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }
}

// Helper classes for responsive design
enum DeviceType { mobile, tablet, desktop }

class ResponsiveDimensions {
  final double maxWidth;
  final double imageAspectRatio;
  final double horizontalPadding;
  final double verticalPadding;
  final double avatarRadius;
  final double fontSize;
  final double spacing;
  final bool isLandscape;

  ResponsiveDimensions({
    required this.maxWidth,
    required this.imageAspectRatio,
    required this.horizontalPadding,
    required this.verticalPadding,
    required this.avatarRadius,
    required this.fontSize,
    required this.spacing,
    required this.isLandscape,
  });
}