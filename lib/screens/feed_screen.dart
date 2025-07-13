import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:instagram_clone/utils/colors.dart';
import 'package:instagram_clone/utils/global_variable.dart';
import 'package:instagram_clone/widgets/post_card.dart'; // Use your original PostCard
import 'package:instagram_clone/widgets/theme_toggle_button.dart';
import 'package:instagram_clone/screens/profile_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({Key? key}) : super(key: key);

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bool isWeb = width > webScreenSize;

    return Scaffold(
      backgroundColor: isWeb ? getBackgroundColor(context) : getBackgroundColor(context),
      appBar: isWeb
          ? null
          : AppBar(
        elevation: 0,
        backgroundColor: getBackgroundColor(context),
        title: SvgPicture.asset(
          'assets/ic_instagram.svg',
          color: getPrimaryColor(context),
          height: 32,
        ),
        actions: [
          IconButton(
              icon: Icon(
                Icons.notification_add_outlined,
                color: getPrimaryColor(context),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('No new notifications'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
          ),
          // Add theme toggle button
          const Padding(
            padding: EdgeInsets.only(right: 8.0),
            child: ThemeToggleIconButton(),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .orderBy('datePublished', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          // Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Error state
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                "Something went wrong!",
                style: TextStyle(color: Colors.red),
              ),
            );
          }

          // Empty state
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No posts yet!',
                style: TextStyle(color: Colors.grey, fontSize: 18),
              ),
            );
          }

          // Success state - Use your original PostCard
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 10),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final snap = snapshot.data!.docs[index].data();
              return Container(
                margin: EdgeInsets.symmetric(
                  horizontal: isWeb ? width * 0.2 : 0,
                  vertical: isWeb ? 15 : 8,
                ),
                child: PostCard(
                  snap: snap, // Use your original PostCard which has working like/comment
                ),
              );
            },
          );
        },
      ),
    );
  }
}