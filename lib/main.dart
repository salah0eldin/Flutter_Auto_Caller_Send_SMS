import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:telephony/telephony.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Auto Call & SMS', home: AutoCallSmsPage());
  }
}

class AutoCallSmsPage extends StatefulWidget {
  @override
  State<AutoCallSmsPage> createState() => _AutoCallSmsPageState();
}

class _AutoCallSmsPageState extends State<AutoCallSmsPage> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController timesController = TextEditingController();
  final TextEditingController smsController = TextEditingController();
  bool isCalling = false;
  bool isSendingSms = false;
  bool cancelRequested = false;
  final Telephony telephony = Telephony.instance;
  static const platform = MethodChannel('com.example.callsms/call');

  Future<void> _requestPermissions() async {
    await Permission.phone.request();
    await Permission.sms.request();
  }

  Future<void> _autoCall() async {
    setState(() {
      isCalling = true;
      cancelRequested = false;
    });
    final phone = phoneController.text;
    final times = int.tryParse(timesController.text) ?? 1;
    for (int i = 0; i < times; i++) {
      if (cancelRequested) break;
      try {
        await platform.invokeMethod('directCall', {'phone': phone});
      } catch (e) {
        // Optionally show error
      }
      await Future.delayed(const Duration(seconds: 5));
    }
    setState(() {
      isCalling = false;
    });
  }

  Future<void> _autoSendSms() async {
    setState(() {
      isSendingSms = true;
      cancelRequested = false;
    });
    final phone = phoneController.text;
    final times = int.tryParse(timesController.text) ?? 1;
    final message = smsController.text;
    for (int i = 0; i < times; i++) {
      if (cancelRequested) break;
      await telephony.sendSms(to: phone, message: message);
      await Future.delayed(const Duration(seconds: 1));
    }
    setState(() {
      isSendingSms = false;
    });
  }

  void _cancelOperation() {
    setState(() {
      cancelRequested = true;
      isCalling = false;
      isSendingSms = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Auto Call & SMS')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Phone Number'),
              keyboardType: TextInputType.phone,
            ),
            TextField(
              controller: timesController,
              decoration: const InputDecoration(labelText: 'Number of Times'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: smsController,
              decoration: const InputDecoration(labelText: 'SMS Message'),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: isCalling || isSendingSms ? null : _autoCall,
                  child: const Text('Call'),
                ),
                ElevatedButton(
                  onPressed: isCalling || isSendingSms ? null : _autoSendSms,
                  child: const Text('Send SMS'),
                ),
                ElevatedButton(
                  onPressed: _cancelOperation,
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
