import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../services/database.dart';
import '../models/post.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../models/account.dart';
import 'dart:ui'; // For ImageFilter.blur


class CreatePostScreen extends StatefulWidget {
  final String userId;
  final Color themeMain;
  final Color themeLite;
  final double bodyFontSize;
  final VoidCallback? onPostCreated;
  final int navItem;
  final ValueChanged<int>? onItemSelected;
  final bool isAdmin;
  final bool isSignedIn;
  final Color themeGrey;
  final bool isFullyLoaded;
  final Account user; // NEW

  const CreatePostScreen({
    super.key,
    required this.userId,
    required this.themeMain,
    required this.themeLite,
    required this.bodyFontSize,
    this.onPostCreated,
    required this.navItem,
    this.onItemSelected,
    required this.isAdmin,
    required this.isSignedIn,
    required this.themeGrey,
    required this.isFullyLoaded,
    required this.user, // 👈 ADD THIS
  });

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _contentController = TextEditingController();
  final _tagsController = TextEditingController();
  bool _isAnonymous = false;
  final _uuid = const Uuid();

  void _submitPost() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) return;

    final tags = _tagsController.text.trim().split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
    final post = Post(
      id: _uuid.v4(),
      userId: widget.userId,
      content: content,
      isAnonymous: _isAnonymous,
      tags: tags,
      createdAt: DateTime.now().toIso8601String(),
    );

    await DatabaseService().insertPost(post);
    _contentController.clear();
    _tagsController.clear();
    widget.onPostCreated?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg_pattern.jpg',
              fit: BoxFit.cover,
            ),
          ),

          // Blur filter
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                color: Colors.black.withOpacity(0), // Required for blur to work
              ),
            ),
          ),

          // Foreground content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Create a Hush',
                    style: TextStyle(
                      fontSize: widget.bodyFontSize + 8,
                      fontWeight: FontWeight.bold,
                      color: widget.themeMain,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  TextField(
                    controller: _contentController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: 'Share your thoughts...',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.8),
                    ),
                    style: TextStyle(fontSize: widget.bodyFontSize),
                  ),
                  const SizedBox(height: 12.0),
                  TextField(
                    controller: _tagsController,
                    decoration: InputDecoration(
                      hintText: 'Tags (comma-separated)',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.8),
                    ),
                    style: TextStyle(fontSize: widget.bodyFontSize),
                  ),
                  const SizedBox(height: 12.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Post Anonymously',
                        style: TextStyle(fontSize: widget.bodyFontSize),
                      ),
                      Switch(
                        value: _isAnonymous,
                        activeColor: widget.themeMain,
                        activeTrackColor: widget.themeLite,
                        onChanged: (value) {
                          setState(() {
                            _isAnonymous = value;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: _submitPost,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.themeMain,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                    ),
                    child: Text(
                      'Post',
                      style: TextStyle(fontSize: widget.bodyFontSize),
                    ),
                  ),
                ],
              ),
            ),
          ),
              // Add this at the end of children list in Stack:
              Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: CustomBottomNavBar(
                      themeLite: widget.themeLite,
                      themeDark: widget.themeMain,
                      themeGrey: widget.themeGrey,
                      navItem: widget.navItem,
                      isAdminMode: widget.isAdmin,
                      isSignedIn: widget.isSignedIn,
                      hideAdminFeatures: !widget.isAdmin,
                      isFullyLoaded: widget.isFullyLoaded,
                      onItemSelected: widget.onItemSelected,
                      user: widget.user,
                 ),
              ),
        ],
      ),


    );
  }
}