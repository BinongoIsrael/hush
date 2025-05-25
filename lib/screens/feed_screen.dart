import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../services/database.dart';
import '../models/post.dart';
import '../models/account.dart';

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
  final _commentController = TextEditingController();
  // Removed _isCommentAnonymous from here to manage it locally in the modal

  Future<String> _getDisplayName(Post post) async {
    if (post.isAnonymous) return 'Anonymous_${post.id.substring(0, 8)}';
    final accounts = await DatabaseService().getAccount(post.userId);
    return accounts.isNotEmpty ? accounts.first.apiName ?? 'Unknown' : 'Unknown';
  }

  Future<String> _getCommentDisplayName(Comment comment) async {
    if (comment.isAnonymous) return 'Reply_${comment.id.substring(0, 8)}';
    final accounts = await DatabaseService().getAccount(comment.userId);
    return accounts.isNotEmpty ? accounts.first.apiName ?? 'Unknown' : 'Unknown';
  }

  void _submitComment(String postId, bool isAnonymous) async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    final comment = Comment(
      id: _uuid.v4(),
      postId: postId,
      userId: widget.userId,
      content: content,
      isAnonymous: isAnonymous,
      createdAt: DateTime.now().toIso8601String(),
    );

    await DatabaseService().insertComment(comment);
    _commentController.clear();
    setState(() {});
  }

  void _reactToPost(String postId) async {
    final hasReacted = await DatabaseService().hasReacted(postId, widget.userId);
    if (!hasReacted) {
      await DatabaseService().insertReaction(
        _uuid.v4(),
        postId,
        widget.userId,
        DateTime.now().toIso8601String(),
      );
      setState(() {});
    }
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
          padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0), // Changed top padding from 120.0 to 8.0
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            return Card(
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
                        children: post.tags.map((tag) => Chip(label: Text(tag, style: TextStyle(fontSize: widget.bodyFontSize - 2)))).toList(),
                      ),
                    const SizedBox(height: 8.0),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.favorite, color: widget.themeMain),
                          onPressed: widget.isSignedIn ? () => _reactToPost(post.id) : null,
                        ),
                        Text('${post.reactionCount}', style: TextStyle(fontSize: widget.bodyFontSize)),
                        const SizedBox(width: 16.0),
                        IconButton(
                          icon: Icon(Icons.comment, color: widget.themeMain),
                          onPressed: widget.isSignedIn
                              ? () {
                            bool isCommentAnonymous = false; // Local state for the modal
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              builder: (context) => StatefulBuilder(
                                builder: (BuildContext context, StateSetter modalSetState) {
                                  return Padding(
                                    padding: EdgeInsets.only(
                                      bottom: MediaQuery.of(context).viewInsets.bottom,
                                      left: 16.0,
                                      right: 16.0,
                                      top: 16.0,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        TextField(
                                          controller: _commentController,
                                          decoration: InputDecoration(
                                            hintText: 'Add a comment...',
                                            border: OutlineInputBorder(),
                                          ),
                                          style: TextStyle(fontSize: widget.bodyFontSize),
                                          autofocus: true,
                                        ),
                                        const SizedBox(height: 12.0),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text('Comment Anonymously', style: TextStyle(fontSize: widget.bodyFontSize)),
                                            Switch(
                                              value: isCommentAnonymous,
                                              activeColor: widget.themeMain,
                                              onChanged: (value) {
                                                modalSetState(() {
                                                  isCommentAnonymous = value;
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12.0),
                                        ElevatedButton(
                                          onPressed: () => _submitComment(post.id, isCommentAnonymous),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: widget.themeMain,
                                            foregroundColor: Colors.white,
                                          ),
                                          child: Text('Comment', style: TextStyle(fontSize: widget.bodyFontSize)),
                                        ),
                                        const SizedBox(height: 16.0),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            );
                          }
                              : null,
                        ),
                        IconButton(
                          icon: Icon(Icons.report, color: widget.themeGrey),
                          onPressed: widget.isSignedIn ? () => _reportContent(post.id, 'post') : null,
                        ),
                      ],
                    ),
                    FutureBuilder<List<Comment>>(
                      future: DatabaseService().getComments(post.id),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const SizedBox.shrink();
                        final comments = snapshot.data!;
                        return Column(
                          children: comments.map((comment) => ListTile(
                            title: FutureBuilder<String>(
                              future: _getCommentDisplayName(comment),
                              builder: (context, snapshot) => Text(
                                snapshot.data ?? 'Loading...',
                                style: TextStyle(fontSize: widget.bodyFontSize - 2),
                              ),
                            ),
                            subtitle: Text(comment.content, style: TextStyle(fontSize: widget.bodyFontSize - 2)),
                            trailing: widget.isSignedIn
                                ? IconButton(
                              icon: Icon(Icons.report, color: widget.themeGrey),
                              onPressed: () => _reportContent(comment.id, 'comment'),
                            )
                                : null,
                          )).toList(),
                        );
                      },
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