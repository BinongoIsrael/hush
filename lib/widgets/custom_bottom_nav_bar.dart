import 'package:flutter/material.dart';
import '../models/account.dart';


class CustomBottomNavBar extends StatefulWidget {
  final Color themeLite;
  final Color themeDark;
  final Color themeGrey;
  final int navItem;
  final bool isAdminMode;
  final bool isSignedIn;
  final bool hideAdminFeatures;
  final bool isFullyLoaded;
  final ValueChanged<int>? onItemSelected;
  final Account user;



  const CustomBottomNavBar({
    super.key,
    required this.themeLite,
    required this.themeDark,
    required this.themeGrey,
    required this.navItem,
    required this.isAdminMode,
    required this.isSignedIn,
    required this.hideAdminFeatures,
    required this.isFullyLoaded,
    required this.user, // NEW
    this.onItemSelected,

  });

  @override
  State<CustomBottomNavBar> createState() => _CustomBottomNavBarState();
}

class _CustomBottomNavBarState extends State<CustomBottomNavBar> {
  static const double _iconSize = 24;
  static const double _iconSizeLarge = 43; // Hush icon size
  static const double _itemWidthLarge = 90; // Hush width
  static const double _labelFontSize = 14;
  static const double _itemWidth = 80;
  static const double _spacingWidth = 14;
  static const double _itemPadding = 8;
  static const double _iconPadding = 12;
  static const double _labelSpacing = 3;
  static const double _navBarHeight = 71;
  static const EdgeInsets _navBarPadding = EdgeInsets.fromLTRB(12, 2, 12, 10);
  static final BorderRadius _itemBorderRadius = BorderRadius.circular(24);

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    required bool isSelected,
    bool isHush = false,
    bool emphasize = false,
  }) {
    final themeLite = widget.themeLite;
    final themeDark = widget.themeDark;
    final themeGrey = widget.themeGrey;
    final onItemSelected = widget.onItemSelected;

    //final double iconSize = emphasize ? 36 : _iconSize;
    final double containerSize = emphasize ? 60 : _itemWidth;

    final bool isHush = label.toLowerCase() == 'hush' && widget.user.userLevel == 1;
    final double iconSize = isHush ? _iconSizeLarge : _iconSize;
    final double itemWidth = isHush ? _itemWidthLarge : _itemWidth;
    final Color bgColor = isHush ? widget.themeLite.withOpacity(0.2) : Colors.transparent;
    //final Color iconColor = isHush ? Colors.redAccent : (isSelected ? widget.themeDark : Colors.black45);
    final Color iconColor = isSelected ? widget.themeDark : Colors.black45;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: itemWidth,
          decoration: BoxDecoration(
            color: emphasize ? themeLite.withOpacity(0.2) : Colors.transparent,
            borderRadius: _itemBorderRadius,
          ),
          child: Material(
            color: isSelected ? themeLite : Colors.transparent,
            borderRadius: _itemBorderRadius,
            child: InkWell(
              borderRadius: _itemBorderRadius,
              onTap: onItemSelected != null ? () => onItemSelected(index) : null,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(_iconPadding, _itemPadding, _iconPadding, _itemPadding),
                child: Icon(
                  icon,
                  size: iconSize,
                  color: iconColor,
                ),
              ),
            ),
          ),
        ),
//        const SizedBox(height: _labelSpacing),
//        Text(
//          label,
//         textAlign: TextAlign.center,
//          style: TextStyle(
//            fontSize: _labelFontSize,
//            fontWeight: FontWeight.bold,
//            color: bgColor,
//          ),
//        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final navItem = widget.navItem;
    final isAdminMode = widget.isAdminMode;
    final isSignedIn = widget.isSignedIn;
    final hideAdminFeatures = widget.hideAdminFeatures;
    final isFullyLoaded = widget.isFullyLoaded;

    return Container(
      height: _navBarHeight,
      width: double.infinity,
      padding: _navBarPadding,
      color: widget.themeLite.withOpacity(1.0), // semi-transparent to let blur show
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildNavItem(
                index: 0,
                icon: Icons.home,
                label: "Home",
                isSelected: navItem == 0,
              ),
              if (isSignedIn) const SizedBox(width: _spacingWidth),
              if (isSignedIn)
                _buildNavItem(
                  index: 1,
                  icon: Icons.add_circle_outline,
                  label: "Hush",
                  isSelected: navItem == 1,
                  isHush: true,
                  emphasize: widget.user.userLevel == 1, // Highlight if standard user
                ),
              if (isSignedIn) const SizedBox(width: _spacingWidth),
              if (isSignedIn)
                _buildNavItem(
                  index: 2,
                  icon: Icons.person,
                  label: "My Activity",
                  isSelected: navItem == 2,
                ),
              if (!hideAdminFeatures) const SizedBox(width: _spacingWidth),
              if (!hideAdminFeatures)
                _buildNavItem(
                  index: 3,
                  icon: Icons.gavel,
                  label: "Moderate",
                  isSelected: navItem == 3,
                ),
              if (!hideAdminFeatures) const SizedBox(width: _spacingWidth),
              if (!hideAdminFeatures)
                _buildNavItem(
                  index: 4,
                  icon: Icons.group,
                  label: "Users",
                  isSelected: navItem == 4,
                ),
            ],
          ),
        ),
      ),
    );
  }
}