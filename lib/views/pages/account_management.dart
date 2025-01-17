import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phone_system_app/controllers/account_view_controller.dart';

class AccountManagement extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.amberAccent),
          onPressed: () => Get.put(AccountViewController())
              .checkSystemBillsByYearsAndMonths(10, 2024),
          child: const Text('إدفع لجميع العملاء')),
    );
  }
}
