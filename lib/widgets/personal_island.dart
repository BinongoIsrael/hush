import 'package:flutter/material.dart';

class PersonalIsland extends StatelessWidget {
  final Widget? netImgSm;
  final String? apiName;
  final Color themeLite;
  final double headLine3;
  final bool isSignedIn;
  final VoidCallback? onAppSettingsTap;

  const PersonalIsland({
  super.key,
  this.netImgSm,
  this.apiName,
  required this.themeLite,
  required this.headLine3,
  required this.isSignedIn,
  this.onAppSettingsTap,
  });

  static const double _islandTopPadding = 64.0;
  static const double _islandHorizontalPadding = 16.0;
  static const double _containerPadding = 8.0;
  static const double _borderRadius = 30.0;
  static const double _smallSpacing = 4.0;
  static const double _mediumSpacing = 8.0;

  @override
  Widget build(BuildContext context) {
    if (!isSignedIn) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: _islandTopPadding,
      left: _islandHorizontalPadding,
      right: _islandHorizontalPadding,
      child: GestureDetector(
        onTap: () async {
          onAppSettingsTap?.call();
        },
        child: Container(
          padding: const EdgeInsets.all(_containerPadding),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(_borderRadius),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 12.0), // 🔄 Adjust value as needed
                child: Row(
                  children: [
                    Icon(Icons.menu, size: headLine3 * 1.5, color: Color(0xFF0097A7)),
                    const SizedBox(width: _mediumSpacing),
                    Text(
                      'Hush',
                      style: TextStyle(
                        fontSize: headLine3 * 2,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        fontFamily: 'Roboto',
                        color: Color(0xB300808e), // ✅ updated font color here
                      ),
                    ),
                  ],
                ),
              ),
              // Optional: Add trailing icons or profile picture here
            ],
          ),
        ),
      ),
    );
  }
}