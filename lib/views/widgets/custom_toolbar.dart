import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phone_system_app/controllers/account_client_info_data.dart';
import 'package:phone_system_app/models/client.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:phone_system_app/views/print_clients_receipts.dart';
import 'package:flutter/services.dart';

class CustomToolbar extends StatelessWidget {
  const CustomToolbar({
    super.key,
    required this.controller,
    required this.printingClients,
  });

  final AccountClientInfo controller;
  final List<Client> printingClients;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller.searchController,
              onChanged: controller.searchQueryChanged,
              decoration: InputDecoration(
                hintText: 'بحث...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () {
              Get.to(() => PrintClientsReceipts(
                    clients: printingClients,
                  ));
            },
          ),
        ],
      ),
    );
  }
}
