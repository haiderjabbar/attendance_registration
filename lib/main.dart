import 'package:flutter/material.dart';
import 'src/ui/screens/home_screen.dart';
import 'src/ui/screens/splash_screen.dart';  // if using the splash from earlier
import 'package:permission_handler/permission_handler.dart';


// void requestNotificationPermission() async {
//   final status = await Permission.notification.request();
//
//   if (status.isGranted) {
//     print("✅ Notification permission granted.");
//   } else if (status.isDenied) {
//     print("❌ Notification permission denied.");
//   } else if (status.isPermanentlyDenied) {
//     openAppSettings(); // Open system settings for manual permission
//   }
// }


void main() {
  runApp(MyApp());
  // requestNotificationPermission();
}


class MyApp extends StatelessWidget {
  const MyApp({Key? key}): super(key: key);

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'nfc',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(primarySwatch: Colors.blue),
    home: const SplashScreen(
      duration: 4,
      nextPage: HomeScreen(),
    ),
  );
}
