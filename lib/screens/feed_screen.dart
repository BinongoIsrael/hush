import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../services/database.dart';
import '../models/post.dart';
import '../models/account.dart';
import 'post_detail_screen.dart';

class FeedScreen extends StatefulWidget {
  final bool isSignedIn;
  final String userId;
  final bool isAdmin;
  final Color themeMain;
  final Color themeGrey;
  final double bodyFontSize;

  const FeedScreen({
    super.key,
    required this.isSignedIn,
    required this.userId,
    required this.isAdmin,
    required this.themeMain,
    required this.themeGrey,
    required this.bodyFontSize,
  });

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final _uuid = const Uuid();

  Future<String> _getDisplayName(Post post) async {
    if (post.isAnonymous) return 'Anonymous_${post.id.substring(0, 8)}';
    final accounts = await DatabaseService().getAccount(post.userId);
    return accounts.isNotEmpty ? accounts.first.apiName ?? 'Unknown' : 'Unknown';
  }

  void _reactToPost(String postId) async {
    final hasReacted = await DatabaseService().hasReacted(postId, widget.userId);
    if (hasReacted) {
      await DatabaseService().deleteReaction(postId, widget.userId);
    } else {
      await DatabaseService().insertReaction(
        _uuid.v4(),
        postId,
        widget.userId,
        DateTime.now().toIso8601String(),
      );
    }
    setState(() {}); // Refresh UI after reacting/unreacting
  }


  void _reportContent(String contentId, String contentType) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Report Content', style: TextStyle(fontSize: widget.bodyFontSize + 2)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('Abuse', style: TextStyle(fontSize: widget.bodyFontSize)),
              onTap: () => Navigator.pop(context, 'Abuse'),
            ),
            ListTile(
              title: Text('Harassment', style: TextStyle(fontSize: widget.bodyFontSize)),
              onTap: () => Navigator.pop(context, 'Harassment'),
            ),
            ListTile(
              title: Text('Spam', style: TextStyle(fontSize: widget.bodyFontSize)),
              onTap: () => Navigator.pop(context, 'Spam'),
            ),
          ],
        ),
      ),
    );

    if (reason != null) {
      await DatabaseService().insertReport(
        _uuid.v4(),
        contentId,
        contentType,
        reason,
        widget.userId,
        DateTime.now().toIso8601String(),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Content reported.', style: TextStyle(fontSize: widget.bodyFontSize))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Post>>(
      future: DatabaseService().getPosts(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator(color: widget.themeMain));
        final posts = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PostDetailScreen(
                      post: post,
                      isSignedIn: widget.isSignedIn,
                      userId: widget.userId,
                      isAdmin: widget.isAdmin,
                      themeMain: widget.themeMain,
                      themeGrey: widget.themeGrey,
                      bodyFontSize: widget.bodyFontSize,
                    ),
                  ),
                ).then((_) => setState(() {})); // Refresh on return
              },
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FutureBuilder<String>(
                        future: _getDisplayName(post),
                        builder: (context, snapshot) => Text(
                          snapshot.data ?? 'Loading...',
                          style: TextStyle(fontSize: widget.bodyFontSize, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Text(post.content, style: TextStyle(fontSize: widget.bodyFontSize)),
                      if (post.tags.isNotEmpty)
                        Wrap(
                          spacing: 8.0,
                          children: post.tags.map((tag) => Chip(
                            label: Text(tag, style: TextStyle(fontSize: widget.bodyFontSize - 2)),
                          )).toList(),
                        ),
                      const SizedBox(height: 8.0),
                      // Inside the Card in FeedScreen's ListView.builder
                      Row(
                        children: [
                          // React emoji button
                          IconButton(
                            icon: Text(
                              '✨',
                              style: TextStyle(fontSize: 20.0),
                            ),
                            onPressed: widget.isSignedIn ? () => _reactToPost(post.id) : null,
                          ),

                          // Show reaction count only if > 0
                          if (post.reactionCount > 0)
                            Text(
                              '${post.reactionCount}',
                              style: TextStyle(fontSize: widget.bodyFontSize),
                            ),

                          const SizedBox(width: 16.0),

                          // Comment emoji + conditional count
                          FutureBuilder<List<Comment>>(
                            future: DatabaseService().getComments(post.id),
                            builder: (context, snapshot) {
                              final commentCount = snapshot.hasData ? snapshot.data!.length : 0;
                              return Row(
                                children: [
                                  GestureDetector(
                                    onTap: widget.isSignedIn
                                        ? () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => PostDetailScreen(
                                            post: post,
                                            isSignedIn: widget.isSignedIn,
                                            userId: widget.userId,
                                            isAdmin: widget.isAdmin,
                                            themeMain: widget.themeMain,
                                            themeGrey: widget.themeGrey,
                                            bodyFontSize: widget.bodyFontSize,
                                          ),
                                        ),
                                      ).then((_) => setState(() {}));
                                    }
                                        : null,
                                    child: Text(
                                      '💬',
                                      style: TextStyle(fontSize: 20, color: widget.themeMain),
                                    ),
                                  ),

                                  // Show comment count only if > 0
                                  if (commentCount > 0)
                                    Text(
                                      '$commentCount',
                                      style: TextStyle(fontSize: widget.bodyFontSize),
                                    ),
                                ],
                              );
                            },
                          ),

                          const SizedBox(width: 16.0),

                          // Report emoji
                          GestureDetector(
                            onTap: widget.isSignedIn ? () => _reportContent(post.id, 'post') : null,
                            child: Text(
                              '🛑',
                              style: TextStyle(fontSize: 20, color: widget.themeGrey),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}