import 'package:flutter/material.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:flutter/services.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;
import '../../services/teacher_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const platform = MethodChannel('com.attendance/lock');

  String _nfcResult = 'يجب الضغط على تسجيل الحضور';
  final TeacherService _teacherService = TeacherService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _checkNotificationPermission();

      // Check and handle overlay permission
      if (await Permission.systemAlertWindow.isGranted) {
        // If permission is already granted, start the service
        // await startLockService(intervalSeconds: 60);
      } else {
        // If not granted, request permission
        await requestOverlayPermission();
      }
    });
  }

  //-----------------------custom dialog overlay---------------------------------------------
  Future<void> requestOverlayPermission() async {
    if (!await Permission.systemAlertWindow.isGranted) {
      final intent = AndroidIntent(
        action: 'android.settings.action.MANAGE_OVERLAY_PERMISSION',
      );
      await intent.launch();
    }
  }

  //--------------------------------------------------------------------
  Future<void> _checkNotificationPermission() async {
    if (await Permission.notification.isDenied) {
      showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              title: Text("Allow Notifications"),
              content: Text(
                "We use notifications to alert you before locking the screen.",
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await Permission.notification.request();
                  },
                  child: Text("Allow"),
                ),
              ],
            ),
      );
    }
  }

  Future<void> _lockDevice() async {
    try {
      final result = await platform.invokeMethod('lockScreen');
      print("Result: $result");
    } on PlatformException catch (e) {
      print("Failed to lock screen: '${e.message}'.");
    }
  }

  Future<void> startLockService({required int intervalSeconds}) async {
    try {
      final result = await platform.invokeMethod('startLockService', {
        'interval': intervalSeconds,
      });
      print('✅ Foreground service started with $intervalSeconds sec interval');
      print('Native response: $result');
    } on PlatformException catch (e) {
      print("❌ Failed to start service: '${e.message}'.");
    }
  }

  void _activateAdmin() {
    if (Platform.isAndroid) {
      const intent = AndroidIntent(
        action: 'android.app.action.ADD_DEVICE_ADMIN',
        arguments: <String, dynamic>{
          'android.app.extra.DEVICE_ADMIN':
              'com.example.attendance_registration/.MyDeviceAdminReceiver',
          'android.app.extra.ADD_EXPLANATION':
              'This app requires device admin to lock the screen.',
        },
        flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
      );

      intent.launch();
    }
  }

  Future<void> _scanNfc() async {
    setState(() => _isLoading = true);
    try {
      // Poll for the tag
      final tag = await FlutterNfcKit.poll();
      final id = tag.id ?? '';

      if (id.isEmpty) {
        throw Exception('Empty NFC tag ID');
      }

      // Example fetch by ID
      final teacherService = TeacherService();
      final teacherResponse = await teacherService.fetchTeacherData(id);

      var interval = teacherResponse.data.duration ?? 0;

      interval = interval * 60;
      print(interval);

      setState(() {
        _nfcResult =
            'الاستاذ : ${teacherResponse.data.userName}\n'
            'المادة: ${teacherResponse.data.subject}\n'
            'وقت بداية الدرس: ${teacherResponse.data.startTime}\n'
            'وقت نهاية الدرس: ${teacherResponse.data.endTime}\n'
            'الفترة : ${teacherResponse.data.duration}\n'
            'الدرس: ${teacherResponse.data.lessonNumber}\n'
            'وقت تسجيل الحضور: ${teacherResponse.data.currentTime}\n';
      });

      await startLockService(intervalSeconds: interval);
    } catch (e) {
      setState(() {
        _nfcResult = ' $e';
      });
    } finally {
      // Always finish the session and hide loading
      await FlutterNfcKit.finish().catchError((_) {});
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(title: const Text('تسجيل الحضور'), centerTitle: true),
      body: Stack(
        children: [
          // 🔷 Main Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _nfcResult,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                ElevatedButton.icon(
                  icon: const Icon(Icons.nfc),
                  label: const Text('تسجيل الحضور'),
                  onPressed: () {
                    _startNfcFlow(context, screenSize);
                  },
                ),

                // const SizedBox(height: 16),
                // ElevatedButton(
                //   onPressed: _activateAdmin,
                //   child: const Text('Activate Device Admin'),
                // ),
                // const SizedBox(height: 16),
                // ElevatedButton(
                //   onPressed: _lockDevice,
                //   child: const Text('Lock Screen'),
                // ),
              ],
            ),
          ),

          // 🔄 Loading Indicator
          if (_isLoading)
            Container(
              color: Colors.black45,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  /// Kicks off the dialog + NFC scan, with availability check
  void _startNfcFlow(BuildContext context, Size screenSize) async {
    // 0️⃣ Check NFC availability
    try {
      final availability = await FlutterNfcKit.nfcAvailability;
      if (availability != NFCAvailability.available) {
        setState(() {
          _nfcResult = 'NFC is not available: $availability';
        });
        return;
      }
    } catch (e) {
      setState(() {
        _nfcResult = 'Error checking NFC: $e';
      });
      return;
    }

    // 1️⃣ Show the “hold your card here” dialog immediately
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final screenSize = MediaQuery.of(dialogContext).size;
        return Align(
          alignment: Alignment.topCenter,
          child: Material(
            // the Material widget gives you the default dialog background & shadows
            type: MaterialType.transparency,
            child: SizedBox(
              width: screenSize.width * 0.5,
              height: screenSize.height * 0.5,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/nfc_hold_card.jpg',
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'ضع البطاقة على هذه الايقونه',
                    style: TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    // 2️⃣ Start the NFC scan
    await _scanNfc();

    // 3️⃣ Dismiss the dialog when scan completes or errors
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }
}
