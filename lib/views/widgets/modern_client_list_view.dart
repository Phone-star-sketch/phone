import 'package:flutter/material.dart';
import 'package:phone_system_app/models/client.dart';
import 'package:phone_system_app/views/pages/all_clinets_page.dart';

class ModernClientListView extends StatelessWidget {
  const ModernClientListView({
    super.key,
    required this.data,
    required this.isLoading,
    required this.query,
  });

  final List<Client> data;
  final bool isLoading;
  final String query;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Color(0xFF94A3B8),
            ),
            SizedBox(height: 16),
            Text(
              'لا توجد نتائج',
              style: TextStyle(
                fontSize: 18,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: data.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return ModernClientCard(
          client: data[index],
          index: index,
        );
      },
    );
  }
}
