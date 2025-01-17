import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:phone_system_app/pages/notification_service.dart';

class NotificationSettingsPage extends StatefulWidget {
  @override
  _NotificationSettingsPageState createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _notificationsEnabled = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text('إعدادات الإشعارات',
            style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Color(0xFF2196F3),
        elevation: 0,
      ),
      body: Container(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            SizedBox(height: 20),
            // Animated Bell Icon
            Lottie.asset(
              'assets/animations/bell_notification.json',
              controller: _animationController,
              height: 200,
              width: 200,
            ),
            SizedBox(height: 40),
            // Settings Card
            Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    ListTile(
                      title: Text(
                        'تفعيل الإشعارات كل يومين',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        'ستتلقى تذكيراً كل يومين في الساعة 10 صباحاً',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      trailing: Switch(
                        value: _notificationsEnabled,
                        onChanged: (value) async {
                          setState(() {
                            _notificationsEnabled = value;
                          });
                          if (value) {
                            _animationController.forward();
                            await NotificationService()
                                .scheduleBiDailyNotification();
                          } else {
                            _animationController.reverse();
                            // Cancel notifications
                            await NotificationService()
                                .notificationsPlugin
                                .cancelAll();
                          }
                        },
                        activeColor: Color(0xFF2196F3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            // Information Text
            Text(
              'ستساعدك الإشعارات في تتبع نظام الهواتف بشكل منتظم',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}