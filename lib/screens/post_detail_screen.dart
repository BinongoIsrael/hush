import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../services/database.dart';
import '../models/post.dart';
import '../models/account.dart';

class PostDetailScreen extends StatefulWidget {
  final Post post;
  final bool isSignedIn;
  final String userId;
  final bool isAdmin;
  final Color themeMain;
  final Color themeGrey;
  final double bodyFontSize;

  const PostDetailScreen({
    super.key,
    required this.post,
    required this.isSignedIn,
    required this.userId,
    required this.isAdmin,
    required this.themeMain,
    required this.themeGrey,
    required this.bodyFontSize,
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _uuid = const Uuid();
  final _commentController = TextEditingController();
  bool _isCommentAnonymous = false;
  final _futureBuilderKey = GlobalKey();

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

  void _submitComment({String? parentCommentId}) async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    print('Submitting comment: content="$content", parentCommentId="$parentCommentId"');

    final comment = Comment(
      id: _uuid.v4(),
      postId: widget.post.id,
      userId: widget.userId,
      content: content,
      isAnonymous: _isCommentAnonymous,
      parentCommentId: parentCommentId,
      createdAt: DateTime.now().toIso8601String(),
    );

    try {
      await DatabaseService().insertComment(comment);
      print('Comment inserted: id=${comment.id}, parentCommentId=${comment.parentCommentId}');
      _commentController.clear();
      setState(() {
        _isCommentAnonymous = false;
        _futureBuilderKey.currentState?.setState(() {});
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reply added.', style: TextStyle(fontSize: widget.bodyFontSize))),
      );
    } catch (e) {
      print('Error inserting comment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding reply: $e', style: TextStyle(fontSize: widget.bodyFontSize))),
      );
    }
  }

  void _reactToPost() async {
    final hasReacted = await DatabaseService().hasReacted(widget.post.id, widget.userId);
    if (!hasReacted) {
      await DatabaseService().insertReaction(
        _uuid.v4(),
        widget.post.id,
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

  Widget _buildCommentTree(List<Comment> allComments, List<Comment> comments, int depth, {int maxDepth = 10}) {
    print('Building comment tree: depth=$depth, comment count=${comments.length}, allComments count=${allComments.length}');
    if (depth > maxDepth) {
      print('Max depth reached at depth=$depth');
      return const SizedBox.shrink();
    }

    final List<Widget> commentWidgets = [];

    for (var comment in comments) {
      final replyCount = allComments.where((c) => c.parentCommentId == comment.id).length;
      final replies = allComments.where((c) => c.parentCommentId == comment.id).toList();
      print('Comment id=${comment.id}, content="${comment.content}", replies=$replyCount, reply IDs=${replies.map((r) => r.id).toList()}');

      Widget commentWidget;
      if (replies.isEmpty) {
        commentWidget = ListTile(
          title: FutureBuilder<String>(
            future: _getCommentDisplayName(comment),
            builder: (context, snapshot) => Text(
              snapshot.data ?? 'Loading...',
              style: TextStyle(fontSize: widget.bodyFontSize - 2, fontWeight: FontWeight.bold),
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(comment.content, style: TextStyle(fontSize: widget.bodyFontSize - 2)),
              const SizedBox(height: 4.0),
              Text(
                '$replyCount ${replyCount == 1 ? 'Reply' : 'Replies'}',
                style: TextStyle(fontSize: widget.bodyFontSize - 4, color: widget.themeGrey),
              ),
              if (widget.isSignedIn)
                TextButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (context) => StatefulBuilder(
                        builder: (BuildContext context, StateSetter modalSetState) {
                          bool localIsAnonymous = _isCommentAnonymous;
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
                                  decoration: const InputDecoration(
                                    hintText: 'Reply to comment...',
                                    border: OutlineInputBorder(),
                                  ),
                                  style: TextStyle(fontSize: widget.bodyFontSize),
                                  autofocus: true,
                                ),
                                const SizedBox(height: 12.0),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Reply Anonymously', style: TextStyle(fontSize: widget.bodyFontSize)),
                                    Switch(
                                      value: localIsAnonymous,
                                      activeColor: widget.themeMain,
                                      onChanged: (value) {
                                        modalSetState(() {
                                          localIsAnonymous = value;
                                        });
                                        setState(() {
                                          _isCommentAnonymous = value;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12.0),
                                ElevatedButton(
                                  onPressed: () {
                                    _submitComment(parentCommentId: comment.id);
                                    Navigator.pop(context);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: widget.themeMain,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: Text('Reply', style: TextStyle(fontSize: widget.bodyFontSize)),
                                ),
                                const SizedBox(height: 16.0),
                              ],
                            ),
                          );
                        },
                      ),
                    ).then((_) {
                      print('Refreshing UI after reply');
                      setState(() {});
                    });
                  },
                  child: Text('Reply', style: TextStyle(fontSize: widget.bodyFontSize - 2, color: widget.themeMain)),
                ),
            ],
          ),
          trailing: widget.isSignedIn
              ? IconButton(
            icon: Icon(Icons.report, color: widget.themeGrey),
            onPressed: () => _reportContent(comment.id, 'comment'),
          )
              : null,
        );
      } else {
        commentWidget = ExpansionTile(
          initiallyExpanded: depth < 2,
          title: FutureBuilder<String>(
            future: _getCommentDisplayName(comment),
            builder: (context, snapshot) => Text(
              snapshot.data ?? 'Loading...',
              style: TextStyle(fontSize: widget.bodyFontSize - 2, fontWeight: FontWeight.bold),
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(comment.content, style: TextStyle(fontSize: widget.bodyFontSize - 2)),
              const SizedBox(height: 4.0),
              Text(
                '$replyCount ${replyCount == 1 ? 'Reply' : 'Replies'}',
                style: TextStyle(fontSize: widget.bodyFontSize - 4, color: widget.themeGrey),
              ),
              if (widget.isSignedIn)
                TextButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (context) => StatefulBuilder(
                        builder: (BuildContext context, StateSetter modalSetState) {
                          bool localIsAnonymous = _isCommentAnonymous;
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
                                  decoration: const InputDecoration(
                                    hintText: 'Reply to comment...',
                                    border: OutlineInputBorder(),
                                  ),
                                  style: TextStyle(fontSize: widget.bodyFontSize),
                                  autofocus: true,
                                ),
                                const SizedBox(height: 12.0),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Reply Anonymously', style: TextStyle(fontSize: widget.bodyFontSize)),
                                    Switch(
                                      value: localIsAnonymous,
                                      activeColor: widget.themeMain,
                                      onChanged: (value) {
                                        modalSetState(() {
                                          localIsAnonymous = value;
                                        });
                                        setState(() {
                                          _isCommentAnonymous = value;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12.0),
                                ElevatedButton(
                                  onPressed: () {
                                    _submitComment(parentCommentId: comment.id);
                                    Navigator.pop(context);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: widget.themeMain,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: Text('Reply', style: TextStyle(fontSize: widget.bodyFontSize)),
                                ),
                                const SizedBox(height: 16.0),
                              ],
                            ),
                          );
                        },
                      ),
                    ).then((_) {
                      print('Refreshing UI after reply');
                      setState(() {});
                    });
                  },
                  child: Text('Reply', style: TextStyle(fontSize: widget.bodyFontSize - 2, color: widget.themeMain)),
                ),
            ],
          ),
          trailing: widget.isSignedIn
              ? IconButton(
            icon: Icon(Icons.report, color: widget.themeGrey),
            onPressed: () => _reportContent(comment.id, 'comment'),
          )
              : null,
          children: [
            _buildCommentTree(allComments, replies, depth + 1, maxDepth: maxDepth),
          ],
        );
      }
      commentWidgets.add(Padding(
        padding: EdgeInsets.only(left: (16.0 * depth).clamp(0.0, 80.0)),
        child: commentWidget,
      ));
    }
    return Column(children: commentWidgets);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Post', style: TextStyle(fontSize: widget.bodyFontSize + 2)),
        backgroundColor: widget.themeMain,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Card(
              margin: const EdgeInsets.all(16.0),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FutureBuilder<String>(
                      future: _getDisplayName(widget.post),
                      builder: (context, snapshot) => Text(
                        snapshot.data ?? 'Loading...',
                        style: TextStyle(fontSize: widget.bodyFontSize, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(widget.post.content, style: TextStyle(fontSize: widget.bodyFontSize)),
                    if (widget.post.tags.isNotEmpty)
                      Wrap(
                        spacing: 8.0,
                        children: widget.post.tags
                            .map((tag) => Chip(
                          label: Text(tag, style: TextStyle(fontSize: widget.bodyFontSize - 2)),
                        ))
                            .toList(),
                      ),
                    const SizedBox(height: 8.0),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.favorite, color: widget.themeMain),
                          onPressed: widget.isSignedIn ? _reactToPost : null,
                        ),
                        Text('${widget.post.reactionCount}', style: TextStyle(fontSize: widget.bodyFontSize)),
                        const SizedBox(width: 16.0),
                        IconButton(
                          icon: Icon(Icons.comment, color: widget.themeMain),
                          onPressed: widget.isSignedIn
                              ? () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              builder: (context) => StatefulBuilder(
                                builder: (BuildContext context, StateSetter modalSetState) {
                                  bool localIsAnonymous = _isCommentAnonymous;
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
                                          decoration: const InputDecoration(
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
                                            Text('Comment Anonymously',
                                                style: TextStyle(fontSize: widget.bodyFontSize)),
                                            Switch(
                                              value: localIsAnonymous,
                                              activeColor: widget.themeMain,
                                              onChanged: (value) {
                                                modalSetState(() {
                                                  localIsAnonymous = value;
                                                });
                                                setState(() {
                                                  _isCommentAnonymous = value;
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12.0),
                                        ElevatedButton(
                                          onPressed: () {
                                            _submitComment();
                                            Navigator.pop(context);
                                          },
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
                            ).then((_) {
                              print('Refreshing UI after top-level comment');
                              setState(() {});
                            });
                          }
                              : null,
                        ),
                        IconButton(
                          icon: Icon(Icons.report, color: widget.themeGrey),
                          onPressed: widget.isSignedIn ? () => _reportContent(widget.post.id, 'post') : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            FutureBuilder<List<Comment>>(
              key: _futureBuilderKey,
              future: DatabaseService().getComments(widget.post.id),
              builder: (context, snapshot) {
                print('FutureBuilder state: hasData=${snapshot.hasData}, hasError=${snapshot.hasError}');
                if (snapshot.hasError) {
                  print('FutureBuilder error: ${snapshot.error}');
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('Error loading comments: ${snapshot.error}',
                        style: TextStyle(fontSize: widget.bodyFontSize)),
                  );
                }
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator(color: widget.themeMain));
                }
                final comments = snapshot.data!;
                print('Comments loaded: ${comments.length}');
                if (comments.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('No comments yet.', style: TextStyle(fontSize: widget.bodyFontSize)),
                  );
                }
                return _buildCommentTree(comments, comments.where((c) => c.parentCommentId == null).toList(), 0);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}