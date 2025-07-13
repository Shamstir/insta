import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:instagram_clone/resources/auth_methods.dart';
import 'package:instagram_clone/resources/firestore_methods.dart';
import 'package:instagram_clone/screens/login_screen.dart';
import 'package:instagram_clone/utils/utils.dart';
import 'package:instagram_clone/widgets/follow_button.dart';
import 'package:instagram_clone/widgets/theme_toggle_button.dart';
import 'package:instagram_clone/providers/theme_provider.dart';

class ProfileScreen extends StatefulWidget {
  final String uid;
  const ProfileScreen({Key? key, required this.uid}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  var userData = {};
  int postLen = 0;
  int followers = 0;
  int following = 0;
  bool isFollowing = false;
  bool isLoading = false;

  late AnimationController _profileAnimationController;
  late AnimationController _statsAnimationController;
  late Animation<double> _profileAnimation;
  late Animation<double> _statsAnimation;

  @override
  void initState() {
    super.initState();

    _profileAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _statsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _profileAnimation = CurvedAnimation(
      parent: _profileAnimationController,
      curve: Curves.elasticOut,
    );

    _statsAnimation = CurvedAnimation(
      parent: _statsAnimationController,
      curve: Curves.bounceOut,
    );

    getData();
  }

  @override
  void dispose() {
    _profileAnimationController.dispose();
    _statsAnimationController.dispose();
    super.dispose();
  }

  Future<void> getData() async {
    setState(() {
      isLoading = true;
    });

    try {
      var userSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .get();

      if (!userSnap.exists) {
        throw Exception('User not found');
      }

      var postSnap = await FirebaseFirestore.instance
          .collection('posts')
          .where('uid', isEqualTo: widget.uid)
          .get();

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final data = userSnap.data() as Map<String, dynamic>?;
      if (data == null) {
        throw Exception('Invalid user data');
      }

      setState(() {
        userData = data;
        postLen = postSnap.docs.length;
        followers = (userData['followers'] as List?)?.length ?? 0;
        following = (userData['following'] as List?)?.length ?? 0;
        isFollowing = (userData['followers'] as List?)?.contains(currentUser.uid) ?? false;
      });

      // Start animations
      _profileAnimationController.forward();
      await Future.delayed(const Duration(milliseconds: 300));
      _statsAnimationController.forward();

    } catch (e) {
      if (mounted) {
        showSnackBar(context, e.toString());
      }
    }

    setState(() {
      isLoading = false;
    });
  }
  

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;
        final bgColor = isDark ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
        final cardColor = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF8F8F8);
        final textColor = isDark ? Colors.white : Colors.black;
        final subtitleColor = isDark ? const Color(0xFF888888) : const Color(0xFF666666);

        return Scaffold(
          backgroundColor: bgColor,
          body: isLoading
              ? _buildLoadingState(isDark, textColor)
              : NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  backgroundColor: bgColor,
                  elevation: 0,
                  pinned: true,
                  expandedHeight: 60,
                  leading: IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: textColor,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  title: Text(
                    userData['username'] ?? '',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  actions: [
                    if (FirebaseAuth.instance.currentUser!.uid == widget.uid)
                      Container(
                        margin: const EdgeInsets.only(right: 16),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const ThemeToggleIconButton(),
                      ),
                  ],
                ),
              ];
            },
            body: RefreshIndicator(
              onRefresh: getData,
              color: isDark ? Colors.white : Colors.black,
              backgroundColor: cardColor,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Profile Header
                    _buildProfileHeader(isDark, bgColor, cardColor, textColor, subtitleColor),

                    // Posts Grid
                    _buildPostsSection(isDark, cardColor, textColor, subtitleColor),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingState(bool isDark, Color textColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF8F8F8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(textColor),
              strokeWidth: 2.5,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading profile...',
            style: TextStyle(
              color: textColor.withOpacity(0.7),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(bool isDark, Color bgColor, Color cardColor, Color textColor, Color subtitleColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Profile Picture and Basic Info
          Row(
            children: [
              // Profile Picture
              ScaleTransition(
                scale: _profileAnimation,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Colors.purple.withOpacity(0.8),
                        Colors.pink.withOpacity(0.8),
                        Colors.orange.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  padding: const EdgeInsets.all(3),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: bgColor,
                    ),
                    padding: const EdgeInsets.all(3),
                    child: CircleAvatar(
                      backgroundColor: cardColor,
                      backgroundImage: userData['photoUrl'] != null
                          ? NetworkImage(userData['photoUrl'])
                          : null,
                      radius: 42,
                      child: userData['photoUrl'] == null
                          ? Icon(
                        Icons.person_rounded,
                        size: 40,
                        color: subtitleColor,
                      )
                          : null,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 32),

              // Stats
              Expanded(
                child: ScaleTransition(
                  scale: _statsAnimation,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatItem(postLen, 'Posts', textColor, subtitleColor),
                      _buildStatItem(followers, 'Followers', textColor, subtitleColor),
                      _buildStatItem(following, 'Following', textColor, subtitleColor),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Username and Bio
          SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.3),
              end: Offset.zero,
            ).animate(_profileAnimation),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: Text(
                    userData['username'] ?? '',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (userData['bio'] != null && userData['bio'].toString().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      userData['bio'],
                      style: TextStyle(
                        color: textColor,
                        fontSize: 15,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Action Button
          FadeTransition(
            opacity: _statsAnimation,
            child: _buildActionButton(isDark, cardColor, textColor),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(int value, String label, Color textColor, Color subtitleColor) {
    return TweenAnimationBuilder<int>(
      duration: const Duration(milliseconds: 1000),
      tween: IntTween(begin: 0, end: value),
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, child) {
        return Column(
          children: [
            Text(
              '$animatedValue',
              style: TextStyle(
                color: textColor,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: subtitleColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionButton(bool isDark, Color cardColor, Color textColor) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return Container();

    if (currentUser.uid == widget.uid) {
      return _buildSignOutButton(isDark, cardColor, textColor);
    } else {
      return _buildFollowButton(isDark, textColor);
    }
  }

  Widget _buildSignOutButton(bool isDark, Color cardColor, Color textColor) {
    return Container(
      width: double.infinity,
      height: 44,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF333333) : const Color(0xFFE0E0E0),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            await AuthMethods().signOut();
            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            }
          },
          child: Center(
            child: Text(
              'Sign out',
              style: TextStyle(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFollowButton(bool isDark, Color textColor) {
    return Container(
      width: double.infinity,
      height: 44,
      decoration: BoxDecoration(
        color: isFollowing
            ? (isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF0F0F0))
            : const Color(0xFF0095F6),
        borderRadius: BorderRadius.circular(12),
        border: isFollowing ? Border.all(
          color: isDark ? const Color(0xFF333333) : const Color(0xFFE0E0E0),
          width: 1,
        ) : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            await FireStoreMethods().followUser(
              FirebaseAuth.instance.currentUser!.uid,
              userData['uid'],
            );
            setState(() {
              isFollowing = !isFollowing;
              followers += isFollowing ? 1 : -1;
            });
          },
          child: Center(
            child: Text(
              isFollowing ? 'Following' : 'Follow',
              style: TextStyle(
                color: isFollowing ? textColor : Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPostsSection(bool isDark, Color cardColor, Color textColor, Color subtitleColor) {
    return Column(
      children: [
        // Section divider
        Container(
          height: 1,
          color: isDark ? const Color(0xFF262626) : const Color(0xFFEFEFEF),
        ),

        // Posts header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              Icon(
                Icons.grid_on_rounded,
                color: textColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Posts',
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        // Posts grid
        _buildPostsGrid(isDark, cardColor, textColor, subtitleColor),
      ],
    );
  }

  Widget _buildPostsGrid(bool isDark, Color cardColor, Color textColor, Color subtitleColor) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('posts')
          .where('uid', isEqualTo: widget.uid)
          .get(), // Removed orderBy for now to test basic query
      builder: (context, snapshot) {
        // Enhanced debugging
        print('=== POSTS DEBUG INFO ===');
        print('Current user UID: ${widget.uid}');
        print('Connection state: ${snapshot.connectionState}');
        print('Has error: ${snapshot.hasError}');

        if (snapshot.hasError) {
          print('Error details: ${snapshot.error}');
          print('Error type: ${snapshot.error.runtimeType}');

          return Container(
            height: 300,
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading posts',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${snapshot.error}',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Force rebuild to retry
                      setState(() {});
                    },
                    child: Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          print('Still loading...');
          return Container(
            height: 200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(textColor),
                    strokeWidth: 2,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading posts...',
                    style: TextStyle(
                      color: subtitleColor,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          print('No data in snapshot');
          return Container(
            height: 200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 48, color: subtitleColor),
                  const SizedBox(height: 16),
                  Text(
                    'No data received',
                    style: TextStyle(color: textColor),
                  ),
                ],
              ),
            ),
          );
        }

        final docs = snapshot.data!.docs;
        print('Number of documents found: ${docs.length}');

        // Debug first few documents
        for (int i = 0; i < docs.length && i < 3; i++) {
          print('Document $i data: ${docs[i].data()}');
          print('Document $i ID: ${docs[i].id}');
        }

        if (docs.isEmpty) {
          return Container(
            height: 300,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.photo_camera_outlined,
                    size: 32,
                    color: subtitleColor,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'No posts yet',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'When you share photos, they\'ll appear here.',
                  style: TextStyle(
                    color: subtitleColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        print('Building grid with ${docs.length} posts');

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: docs.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 2,
              mainAxisSpacing: 2,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              final snap = docs[index];
              final data = snap.data() as Map<String, dynamic>;

              // Debug individual post data
              print('Post $index - postUrl: ${data['postUrl']}');

              // Handle missing postUrl
              final postUrl = data['postUrl'] as String?;
              if (postUrl == null || postUrl.isEmpty) {
                return Container(
                  color: cardColor,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image_outlined,
                          color: subtitleColor,
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'No URL',
                          style: TextStyle(
                            color: subtitleColor,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return TweenAnimationBuilder<double>(
                duration: Duration(milliseconds: 200 + (index * 50)),
                tween: Tween<double>(begin: 0, end: 1),
                curve: Curves.easeOutQuart,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: GestureDetector(
                      onTap: () => _showImageDialog(context, snap),
                      child: Container(
                        decoration: BoxDecoration(
                          color: cardColor,
                          border: Border.all(
                            color: isDark ? const Color(0xFF333333) : const Color(0xFFE0E0E0),
                            width: 0.5,
                          ),
                        ),
                        child: Image.network(
                          postUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              color: cardColor,
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: progress.expectedTotalBytes != null
                                      ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                                      : null,
                                  valueColor: AlwaysStoppedAnimation<Color>(subtitleColor),
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            print('Image error for $postUrl: $error');
                            return Container(
                              color: cardColor,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.broken_image_outlined,
                                      color: subtitleColor,
                                      size: 24,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Failed',
                                      style: TextStyle(
                                        color: subtitleColor,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  void _showImageDialog(BuildContext context, DocumentSnapshot snap) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.95),
      builder: (BuildContext dialogContext) {
        return Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(20),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                decoration: BoxDecoration(
                  color: themeProvider.isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: themeProvider.isDarkMode
                                ? const Color(0xFF262626)
                                : const Color(0xFFEFEFEF),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundImage: NetworkImage(userData['photoUrl'] ?? ''),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            userData['username'] ?? '',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            icon: Icon(
                              Icons.close_rounded,
                              color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Image
                    Flexible(
                      child: Container(
                        width: double.infinity,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(16),
                            bottomRight: Radius.circular(16),
                          ),
                          child: Image.network(
                            snap['postUrl'],
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return Container(
                                height: 200,
                                child: const Center(
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 200,
                                child: const Center(
                                  child: Icon(Icons.error_outline, size: 40),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}