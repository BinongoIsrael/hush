import 'package:flutter/material.dart';
import '../services/database.dart';
import '../models/post.dart';
import '../models/account.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../widgets/personal_island.dart';
import 'post_detail_screen.dart';
import 'dart:ui'; // For ImageFilter.blur


class ActivityScreen extends StatelessWidget {
  final String userId;
  final Color themeMain;
  final Color themeGrey;
  final double bodyFontSize;
  final int navItem;
  final ValueChanged<int>? onItemSelected;
  final bool isAdmin;
  final bool isSignedIn;
  final Color themeLite;
  final bool isFullyLoaded;
  final Widget? netImgSm;
  final String? apiName;
  final double headLine3;
  final VoidCallback? onAppSettingsTap;
  final Account user; // NEW


  const ActivityScreen({
    super.key,
    required this.userId,
    required this.themeMain,
    required this.themeGrey,
    required this.bodyFontSize,
    required this.navItem,
    this.onItemSelected,
    required this.isAdmin,
    required this.isSignedIn,
    required this.themeLite,
    required this.isFullyLoaded,
    this.netImgSm,
    this.apiName,
    required this.headLine3,
    this.onAppSettingsTap,
    required this.user, // 👈 ADD THIS
  });




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg_pattern.jpg',
              fit: BoxFit.cover,
            ),
          ),

          /*// Optional: Blur effect on background image (remove if you don’t want blur)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                color: Colors.black.withOpacity(0), // required for blur to work
              ),
            ),
          ),
          */


          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 140.0),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 32.0),
                child: Text(
                  'Your Posts',
                  style: TextStyle(
                    fontSize: bodyFontSize + 2,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Expanded(
                child: FutureBuilder<List<Post>>(
                  future: DatabaseService().getPosts(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Center(child: CircularProgressIndicator(color: themeMain));
                    }
                    final posts = snapshot.data!.where((post) => post.userId == userId).toList();
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
                      children: [
                        ...posts.asMap().entries.map((entry) {
                          final post = entry.value;
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PostDetailScreen(
                                    post: post,
                                    isSignedIn: isSignedIn,
                                    userId: userId,
                                    isAdmin: isAdmin,
                                    themeMain: themeMain,
                                    themeGrey: themeGrey,
                                    bodyFontSize: bodyFontSize,

                                  ),
                                ),
                              );
                            },
                            child: Card(
                              color: Colors.white, // ✅ Set card background to white
                              elevation: 2, // Optional: slight shadow for depth
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8), // Optional: rounded corners
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      post.isAnonymous ? 'Posted Anonymously' : 'Posted by You',
                                      style: TextStyle(
                                        fontSize: bodyFontSize,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8.0),
                                    Text(
                                      post.content,
                                      style: TextStyle(fontSize: bodyFontSize),
                                    ),
                                    if (post.tags.isNotEmpty)
                                      Wrap(
                                        spacing: 8.0,
                                        children: post.tags
                                            .map((tag) => Chip(
                                          label: Text(
                                            tag,
                                            style: TextStyle(fontSize: bodyFontSize - 2),
                                          ),
                                        ))
                                            .toList(),
                                      ),
                                    const SizedBox(height: 8.0),
                                    Text(
                                      'Reactions: ${post.reactionCount}',
                                      style: TextStyle(
                                        fontSize: bodyFontSize - 2,
                                        color: themeGrey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
          if (isSignedIn)
            PersonalIsland(
              netImgSm: netImgSm,
              apiName: apiName,
              themeLite: themeLite,
              headLine3: headLine3,
              isSignedIn: isSignedIn,
              onAppSettingsTap: onAppSettingsTap,
            ),
        ],
      ),
      bottomNavigationBar: Container(
        color: Colors.white,  // or use themeLite or themeMain if you want a themed color
        child: CustomBottomNavBar(
          themeLite: themeLite,
          themeDark: themeMain,
          themeGrey: themeGrey,
          navItem: navItem,
          isAdminMode: isAdmin,
          isSignedIn: isSignedIn,
          hideAdminFeatures: !isAdmin,
          isFullyLoaded: isFullyLoaded,
          user: user,
          onItemSelected: onItemSelected,
        ),
      ),

    );
  }
}