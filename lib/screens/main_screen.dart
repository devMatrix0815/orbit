import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../main.dart' show pendingInviteCircleId;
import '../models/circle_model.dart';
import 'circle_detail_screen.dart';
import 'my_circles.dart';
import 'discover.dart';
import 'notifcations.dart';
import 'profile.dart';

// main screen with bottom navigation
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  int _inviteCount = 0;
  int _requestCount = 0;
  int get _notificationCount => _inviteCount + _requestCount;
  StreamSubscription? _inviteSub;
  StreamSubscription? _requestSub;

  @override
  void initState() {
    super.initState();
    _saveFcmToken();
    _ensureDisplayNameLower();
    _listenNotifications();
    pendingInviteCircleId.addListener(_handleDeepLink);
    // Check if a link arrived before MainScreen was ready
    if (pendingInviteCircleId.value != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _handleDeepLink());
    }
  }

  void _handleDeepLink() {
    final circleId = pendingInviteCircleId.value;
    if (circleId == null || !mounted) return;
    pendingInviteCircleId.value = null;
    _openCircleById(circleId);
  }

  Future<void> _openCircleById(String circleId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('circles')
          .doc(circleId)
          .get();
      if (!doc.exists || !mounted) return;
      final circle = Circle.fromFirestore(doc);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CircleDetailScreen(circle: circle)),
      );
    } catch (_) {}
  }

  void _listenNotifications() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _inviteSub = FirebaseFirestore.instance
        .collection('invites')
        .where('invitedUserId', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snap) {
      if (mounted) setState(() => _inviteCount = snap.docs.length);
    });

    _requestSub = FirebaseFirestore.instance
        .collection('joinRequests')
        .where('adminId', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snap) {
      if (mounted) setState(() => _requestCount = snap.docs.length);
    });
  }

  @override
  void dispose() {
    pendingInviteCircleId.removeListener(_handleDeepLink);
    _inviteSub?.cancel();
    _requestSub?.cancel();
    super.dispose();
  }

  // makes sure displayNameLower exists for user search
  Future<void> _ensureDisplayNameLower() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    final data = doc.data();
    if (data == null || data.containsKey('displayNameLower')) return;
    final displayName = data['displayName'] as String? ?? '';
    if (displayName.isEmpty) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update({'displayNameLower': displayName.toLowerCase()});
  }

  // saves fcm token to firestore for push notifications
  Future<void> _saveFcmToken() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'fcmToken': token});
    }

    // update token when it refreshes
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'fcmToken': newToken});
    });
  }

  // tab screens
  final _screens = [
    const MyCircles(),
    const Discover(),
    const Notifcations(),
    const Profile(),
  ];

  @override
  Widget build(BuildContext context) {
    // theme
    final bool isLight = Theme.of(context).brightness == Brightness.light;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        systemNavigationBarContrastEnforced: false,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: isLight
            ? Brightness.dark
            : Brightness.light,
      ),
      child: Scaffold(
        body: _screens[_selectedIndex],

        // bottom nav
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          indicatorColor: Colors.transparent,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
          onDestinationSelected: (i) => setState(() => _selectedIndex = i),
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.circle_outlined),
              selectedIcon: Icon(Icons.circle),
              label: '',
            ),
            const NavigationDestination(
              icon: Icon(Icons.explore_outlined),
              selectedIcon: Icon(Icons.explore),
              label: '',
            ),
            NavigationDestination(
              icon: Badge(
                label: Text('$_notificationCount'),
                isLabelVisible: _notificationCount > 0,
                child: const Icon(Icons.notifications_outlined),
              ),
              selectedIcon: Badge(
                label: Text('$_notificationCount'),
                isLabelVisible: _notificationCount > 0,
                child: const Icon(Icons.notifications_rounded),
              ),
              label: '',
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: '',
            ),
          ],
        ),
      ),
    );
  }
}
