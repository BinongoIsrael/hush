import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'widgets/loading_screen.dart';
import 'widgets/personal_island.dart';
import 'widgets/app_settings_dialog.dart';
import 'widgets/custom_bottom_nav_bar.dart';
import 'authentication_screen.dart';
import 'screens/create_post_screen.dart';
import 'screens/feed_screen.dart';
import 'screens/activity_screen.dart';
import 'services/database.dart';
import 'models/account.dart';
import 'package:flutter/services.dart'; //added

void main() {
  // Set status bar to use dark icons on light background (or vice versa)
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Color(0xFFF5F5F5), // light grey background
    statusBarIconBrightness: Brightness.dark, // dark icons
    statusBarBrightness: Brightness.light, // for iOS
  ));


  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hush',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'A safe space for everyone to socialize and share their experiences in life anonymously.'),
      debugShowCheckedModeBanner: false,
    );
  }
}

class BackgroundWrapper extends StatelessWidget {
  final Widget body;
  final Widget? bottomNavigationBar;

  const BackgroundWrapper({required this.body, this.bottomNavigationBar, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/images/bg_pattern.jpg"),
          fit: BoxFit.cover,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: body,
        bottomNavigationBar: bottomNavigationBar,
      ),
    );
  }
}


class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final uuid = const Uuid();
  static const Color _themeBG = Color(0xfff5f5f5);
  static const Color _themeMain = Color(0xFF0097A7);
  static const Color _themeLite = Color(0xFFB2EBF2);
  static const Color _themeGrey = Color(0xff505050);

  late bool _keepScreenOn = false;
  late bool _useLargeTexts = false;
  late double _extraLarge = 36.0;
  late double _headLine2 = 22.0;
  late double _headLine3 = 20.0;
  late double _body = 16.0;

  bool _isLoading = true;
  bool _isOfflineMode = true;
  bool _isConnectionLost = false;
  bool _isSignedIn = false;
  bool _isAdmin = false;
  int _selectedIndex = 0;
  late Widget _signingScreen;
  late Widget _loadingScreen = SizedBox();
  late Widget _homeScreen = Container();
  late Widget _createPostScreen = Container();
  late Widget _activityScreen = Container();
  late Widget _moderateScreen = Container();
  late Widget _usersScreen = Container();
  late Widget _currentScreen;

  late Account _signedAccount;
  Widget _netImgSm = const SizedBox(width: 15.0);
  Widget _netImgLg = const SizedBox(width: 30.0);
  String _apiPhotoUrl = '';
  String _apiEmail = '';
  String _fullName = '';

  @override
  void initState() {
    super.initState();
    _initializeRequirements();
  }

  void _handleNavItemSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _buildScreens();
  }

  void _handleAppSettingsTap() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AppSettingsDialog(
          netImgLg: _netImgLg,
          apiName: _fullName,
          apiEmail: _apiEmail,
          headLine2: _headLine2,
          body: _body,
          themeBG: _themeBG,
          themeGrey: _themeGrey,
          themeMain: _themeMain,
          themeLite: _themeLite,
          keepScreenOn: _keepScreenOn,
          useLargeTexts: _useLargeTexts,
          onKeepScreenOnChanged: (newValue) {
            setState(() {
              _keepScreenOn = newValue;
            });
            WakelockPlus.toggle(enable: _keepScreenOn);
            Navigator.of(context).pop();
            _handleAppSettingsTap();
            _buildScreens();
          },
          onUseLargeTextsChanged: (newValue) {
            setState(() {
              _useLargeTexts = newValue;
            });
            _rescaleFontSizes();
            Navigator.of(context).pop();
            _handleAppSettingsTap();
            _buildScreens();
          },
          onSignOutTap: () {
            Navigator.of(context).pop();
            DatabaseService().signOutAccount(_signedAccount.uuid).then((_) {
              setState(() {
                _isSignedIn = false;
                _selectedIndex = 0;
                _fullName = '';
                _apiEmail = '';
                _apiPhotoUrl = '';
                _isAdmin = false;
                _netImgSm = const SizedBox(width: 15.0);
                _netImgLg = const SizedBox(width: 30.0);
              });
              _buildScreens();
            }).catchError((e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error signing out: $e')),
              );
            });
          },
        );
      },
    );
  }

  Future<void> _rescaleFontSizes() async {
    setState(() {
      _extraLarge = _useLargeTexts ? 54.0 : 32.0;
      _headLine2 = _useLargeTexts ? 34.0 : 22.0;
      _headLine3 = _useLargeTexts ? 24.0 : 20.0;
      _body = _useLargeTexts ? 20.0 : 16.0;
    });
  }

  Widget _buildProfileImage({required double radius}) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.white,
      child: _apiPhotoUrl.isEmpty
          ? const Icon(Icons.person, color: Colors.blueAccent)
          : ClipOval(
        child: Image.network(
          _apiPhotoUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.error_outline, color: Colors.red);
          },
        ),
      ),
    );
  }

  Future<void> _loadNetImg() async {
    if (!_isOfflineMode && _isSignedIn) {
      try {
        final netImgSm = _buildProfileImage(radius: 15);
        final netImgLg = _buildProfileImage(radius: 30);
        setState(() {
          _netImgSm = netImgSm;
          _netImgLg = netImgLg;
        });
      } catch (e) {
        setState(() {
          _netImgSm = const SizedBox(width: 15.0);
          _netImgLg = const SizedBox(width: 30.0);
        });
      }
    } else {
      setState(() {
        _netImgSm = const SizedBox(width: 15.0);
        _netImgLg = const SizedBox(width: 30.0);
      });
    }
  }

  Future<void> _showAppOfflineDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(
          "Device is Offline",
          style: TextStyle(fontSize: _headLine2),
        ),
        content: Text(
          "Please check your internet connection.",
          style: TextStyle(fontSize: _body),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              setState(() => _isConnectionLost = true);
              Navigator.of(context).pop();
              _checkInternetConnection();
            },
            child: Text(
              "Retry",
              style: TextStyle(
                fontSize: _body,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _buildAuthenticationScreen() async {
    _loadingScreen = LoadingScreen(size: 80.0, color: _themeMain);
    _signingScreen = AuthenticationScreen(
      onSignedIn: () {
        setState(() => _isSignedIn = true);
        _checkSignedAccount();
        _loadNetImg();
      },
    );
    _updateCurrentScreen();
  }

  Future<void> _buildScreens() async {
    WakelockPlus.toggle(enable: _keepScreenOn);

    _homeScreen = Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/images/bg_pattern.jpg"),
          fit: BoxFit.cover,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent, // So the image is visible
        body: Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 140.0), //✅ adjust until there's no overlap
                Expanded(
                  child: FeedScreen(
                    isSignedIn: _isSignedIn,
                    userId: _signedAccount.uuid,
                    isAdmin: _isAdmin,
                    themeMain: _themeMain,
                    themeGrey: _themeGrey,
                    bodyFontSize: _body,
                  ),
                ),
              ],
            ),
            if (_isSignedIn)
              PersonalIsland(
                netImgSm: _netImgSm,
                apiName: _fullName,
                themeLite: _themeLite,
                headLine3: _headLine3,
                isSignedIn: _isSignedIn,
                onAppSettingsTap: _handleAppSettingsTap,
              ),
          ],
        ),
        bottomNavigationBar: CustomBottomNavBar(
          themeLite: _themeLite,
          themeDark: _themeMain,
          themeGrey: _themeGrey,
          navItem: _selectedIndex,
          isAdminMode: _isAdmin,
          isSignedIn: _isSignedIn,
          hideAdminFeatures: !_isAdmin,
          isFullyLoaded: !_isLoading,
          onItemSelected: _handleNavItemSelected,
          user: _signedAccount,
        ),
      ),
    );

    _createPostScreen = CreatePostScreen(
      userId: _signedAccount.uuid,
      themeMain: _themeMain,
      themeLite: _themeLite,
      bodyFontSize: _body,
      onPostCreated: () {
        setState(() {
          _selectedIndex = 0;
        });
        _buildScreens();
      },
      navItem: _selectedIndex,
      onItemSelected: _handleNavItemSelected,
      isAdmin: _isAdmin,
      isSignedIn: _isSignedIn,
      themeGrey: _themeGrey,
      isFullyLoaded: !_isLoading,
        user: _signedAccount

    );

    _activityScreen = ActivityScreen(
      userId: _signedAccount.uuid,
      themeMain: _themeMain,
      themeGrey: _themeGrey,
      bodyFontSize: _body,
      navItem: _selectedIndex,
      onItemSelected: _handleNavItemSelected,
      isAdmin: _isAdmin,
      isSignedIn: _isSignedIn,
      themeLite: _themeLite,
      isFullyLoaded: !_isLoading,
      netImgSm: _netImgSm, // Added
      apiName: _fullName, // Added
      headLine3: _headLine3, // Added
      onAppSettingsTap: _handleAppSettingsTap,
        user: _signedAccount

    );

    _moderateScreen = Scaffold(
      body: Center(
        child: Text(
          'Moderate Content (Admin)',
          style: TextStyle(fontSize: _headLine2, color: _themeMain),
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        themeLite: _themeLite,
        themeDark: _themeMain,
        themeGrey: _themeGrey,
        navItem: _selectedIndex,
        isAdminMode: _isAdmin,
        isSignedIn: _isSignedIn,
        hideAdminFeatures: !_isAdmin,
        isFullyLoaded: !_isLoading,
        onItemSelected: _handleNavItemSelected,
          user: _signedAccount
      ),
    );


    _usersScreen = Scaffold(
      body: Center(
        child: Text(
          'Manage Users (Admin)',
          style: TextStyle(fontSize: _headLine2, color: _themeMain),
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        themeLite: _themeLite,
        themeDark: _themeMain,
        themeGrey: _themeGrey,
        navItem: _selectedIndex,
        isAdminMode: _isAdmin,
        isSignedIn: _isSignedIn,
        hideAdminFeatures: !_isAdmin,
        isFullyLoaded: !_isLoading,
        onItemSelected: _handleNavItemSelected,
          user: _signedAccount
      ),
    );

    _updateCurrentScreen();
  }

  void _updateCurrentScreen() {
    // 🔽 Dynamically set system status bar based on screen and user level
    if (_isAdmin && (_selectedIndex == 3 || _selectedIndex == 4)) {
      // High-contrast status bar for admin screens
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Color(0xFF004D40), // darker teal
          statusBarIconBrightness: Brightness.light, // light icons
          statusBarBrightness: Brightness.dark, // iOS
        ),
      );
    } else {
      // Default status bar
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Color(0xFFF5F5F5), // light gray
          statusBarIconBrightness: Brightness.dark, // dark icons
          statusBarBrightness: Brightness.light, // iOS
        ),
      );
    }

    // 🔽 Then continue with setting the screen
    setState(() {
      if (!_isSignedIn) {
        _currentScreen = _signingScreen;
      } else {
        switch (_selectedIndex) {
          case 0:
            _currentScreen = _homeScreen;
            break;
          case 1:
            _currentScreen = _createPostScreen;
            break;
          case 2:
            _currentScreen = _activityScreen;
            break;
          case 3:
            _currentScreen = _moderateScreen;
            break;
          case 4:
            _currentScreen = _usersScreen;
            break;
          default:
            _currentScreen = _homeScreen;
        }
      }
    });
  }


  Future<void> _checkInternetConnection() async {
    setState(() => _isLoading = true);
    bool connected = false;
    try {
      final result = await InternetAddress.lookup('google.com').timeout(const Duration(seconds: 15));
      connected = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      if (_isConnectionLost) {
        setState(() => _isConnectionLost = false);
        _initializeRequirements();
      }
    } catch (_) {
      _showAppOfflineDialog();
    }
    setState(() {
      _isOfflineMode = !connected;
      _isLoading = false;
    });
  }

  Future<void> _checkSignedAccount() async {
    final accounts = await DatabaseService().getSignedAccount();
    if (accounts.isEmpty) {
      setState(() => _isSignedIn = false);
      _buildScreens();
      return;
    }
    setState(() {
      _signedAccount = accounts.first;
      _fullName = _signedAccount.apiName ?? '';
      _apiEmail = _signedAccount.apiEmail ?? '';
      _apiPhotoUrl = _signedAccount.apiPhotoUrl ?? '';
      _isAdmin = (_signedAccount.userLevel ?? 0) >= 2;
      _isSignedIn = true;
    });
    _buildScreens();
  }

  Future<void> _initializeRequirements() async {
    await _checkInternetConnection();
    await _buildAuthenticationScreen();
    await _checkSignedAccount();
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading ? _loadingScreen : _currentScreen;
  }
}