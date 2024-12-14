// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'firebase_options.dart';
import 'landing_page.dart';
import 'home_page.dart';
import 'services/assistant_services.dart';
import 'services/notification_service.dart';
import 'services/firestore_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Handle background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await _handleMessage(message);
  print('Handling background message: ${message.messageId}');
}

Future<void> _handleMessage(RemoteMessage message) async {
  try {
    final FirestoreService firestoreService = FirestoreService();
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      print('No user logged in');
      return;
    }

    print('Adding notification to Firestore...');
    print('User ID: ${user.uid}');
    print('Title: ${message.notification?.title}');
    print('Body: ${message.notification?.body}');
    print('Data: ${message.data}');
    
    await firestoreService.addNotification(
      title: message.notification?.title ?? 'New Notification',
      message: message.notification?.body ?? '',
      type: message.data['type'] ?? 'system',
      relatedId: message.data['relatedId'],
    );
    
    print('Notification added successfully');
  } catch (e) {
    print('Error handling message: $e');
  }
}

Future<void> _initializeFirebaseMessaging() async {
  final fcm = FirebaseMessaging.instance;
  
  // Request permission
  await fcm.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // Get FCM token
  final token = await fcm.getToken();
  print('FCM Token: $token');

  // Save token to Firestore
  if (token != null) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'fcmToken': token});
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Gemini
  Gemini.init(
    apiKey: GEMINI_API_KEY,
  );

  // Initialize Firebase Messaging
  await _initializeFirebaseMessaging();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  // Handle foreground messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    _handleMessage(message);
  });
  
  // Handle message open
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    _handleMessage(message);
  });
  
  // Initialize Notification Service
  final notificationService = NotificationService();
  await notificationService.initialize();

  runApp(const MealPlannerApp());
}

class MealPlannerApp extends StatelessWidget {
  const MealPlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'NutriGuide',
          theme: ThemeData(
            visualDensity: VisualDensity.adaptivePlatformDensity,
            fontFamily: 'Roboto',
          ),
          home: StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasData && snapshot.data != null) {
                return const HomePage();
              }

              return const LandingPage();
            },
          ),
        );
      },
    );
  }
}