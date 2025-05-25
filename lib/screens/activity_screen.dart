import 'package:flutter/material.dart';
import '../services/database.dart';
import '../models/post.dart';
import '../models/account.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../widgets/personal_island.dart';

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
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 100.0),
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
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                          child: Text(
                            'Your Posts',
                            style: TextStyle(
                              fontSize: bodyFontSize + 2,
                              fontWeight: FontWeight.bold,
                              color: themeMain,
                            ),
                          ),
                        ),
                        ...posts.asMap().entries.map((entry) {
                          final index = entry.key;
                          final post = entry.value;
                          return Card(
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
                                  FutureBuilder<List<Comment>>(
                                    future: DatabaseService().getComments(post.id),
                                    builder: (context, snapshot) {
                                      if (!snapshot.hasData) return const SizedBox.shrink();
                                      final comments = snapshot.data!.where((comment) => comment.userId == userId).toList();
                                      return Column(
                                        children: comments.map((comment) => ListTile(
                                          title: Text(
                                            comment.isAnonymous ? 'Commented Anonymously' : 'Commented by You',
                                            style: TextStyle(fontSize: bodyFontSize - 2),
                                          ),
                                          subtitle: Text(
                                            comment.content,
                                            style: TextStyle(fontSize: bodyFontSize - 2),
                                          ),
                                        )).toList(),
                                      );
                                    },
                                  ),
                                ],
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
      bottomNavigationBar: CustomBottomNavBar(
        themeLite: themeLite,
        themeDark: themeMain,
        themeGrey: themeGrey,
        navItem: navItem,
        isAdminMode: isAdmin,
        isSignedIn: isSignedIn,
        hideAdminFeatures: !isAdmin,
        isFullyLoaded: isFullyLoaded,
        onItemSelected: onItemSelected,
      ),
    );
  }
}