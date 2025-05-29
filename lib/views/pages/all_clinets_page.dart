import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:phone_system_app/controllers/account_client_info_data.dart';
import 'package:phone_system_app/controllers/money_display_loading.dart';
import 'package:phone_system_app/models/client.dart';
import 'package:phone_system_app/utils/string_utils.dart';
import 'package:phone_system_app/views/client_list_view.dart';

class AllClientsPage extends StatefulWidget {
  const AllClientsPage({super.key});

  @override
  State<AllClientsPage> createState() => _AllClientsPageState();
}

class _AllClientsPageState extends State<AllClientsPage> with SingleTickerProviderStateMixin {
  final controller = Get.find<AccountClientInfo>();
  late AnimationController _animationController;
  final ScrollController _scrollController = ScrollController();
  bool _showFloatingSearch = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.offset > 100 && !_showFloatingSearch) {
      setState(() => _showFloatingSearch = true);
    } else if (_scrollController.offset <= 100 && _showFloatingSearch) {
      setState(() => _showFloatingSearch = false);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              _buildAppBar(),
              _buildSearchBar(),
              _buildClientsList(),
            ],
          ),
          if (_showFloatingSearch) _buildFloatingSearchBar(),
          _buildFloatingActionButton(),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 200.0,
      floating: false,
      pinned: true,
      stretch: true,
      backgroundColor: Colors.blue[700],
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'قائمة العملاء',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ).animate().fadeIn().slideY(begin: 0.3, duration: 600.ms),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    Colors.blue[700]!,
                    Colors.blue[900]!,
                  ],
                ),
              ),
            ),
            Positioned(
              right: -50,
              top: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            Positioned(
              left: -30,
              bottom: -30,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: controller.searchController,
                  onChanged: controller.searchQueryChanged,
                  decoration: InputDecoration(
                    hintText: 'البحث عن عميل...',
                    prefixIcon: Icon(Icons.search, color: Colors.blue[700]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.blue[200]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.blue[200]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.blue[700]!, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
                const SizedBox(height: 16),
                _buildStatisticsRow(),
              ],
            ),
          ),
        ),
      ).animate().fadeIn().slideY(begin: 0.2, duration: 800.ms),
    );
  }

  Widget _buildStatisticsRow() {
    return Obx(() {
      final totalClients = controller.clinets.length;
      final activeClients = controller.clinets.where((c) => c.totalCash >= 0).length;
      final inactiveClients = totalClients - activeClients;

      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatCard('إجمالي العملاء', totalClients.toString(), Icons.people, Colors.blue),
          _buildStatCard('العملاء النشطون', activeClients.toString(), Icons.check_circle, Colors.green),
          _buildStatCard('العملاء غير النشطين', inactiveClients.toString(), Icons.warning, Colors.orange),
        ],
      );
    });
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientsList() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const SliverFillRemaining(
          child: Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      final filteredClients = controller.getCurrentClients();
      
      if (filteredClients.isEmpty) {
        return SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'لم يتم العثور على عملاء',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return SliverPadding(
        padding: const EdgeInsets.all(16),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 400,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.2,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final client = filteredClients[index];
              return _buildClientCard(client)
                  .animate()
                  .fadeIn(delay: (100 * index).ms)
                  .slideX(begin: 0.2, delay: (100 * index).ms);
            },
            childCount: filteredClients.length,
          ),
        ),
      );
    });
  }

  Widget _buildClientCard(Client client) {
    final hasDebt = client.totalCash < 0;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () {
          // Handle client tap
        },
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: hasDebt 
                ? [Colors.red[50]!, Colors.white]
                : [Colors.green[50]!, Colors.white],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: hasDebt ? Colors.red[100] : Colors.green[100],
                    child: Text(
                      client.name?.substring(0, 1).toUpperCase() ?? '',
                      style: TextStyle(
                        color: hasDebt ? Colors.red[700] : Colors.green[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          client.name ?? '',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          client.numbers?.first.phoneNumber ?? '',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () {
                      // Show client options
                    },
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: hasDebt ? Colors.red[50] : Colors.green[50],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'الرصيد:',
                      style: TextStyle(
                        color: hasDebt ? Colors.red[700] : Colors.green[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${client.totalCash.abs()} جنيه',
                      style: TextStyle(
                        color: hasDebt ? Colors.red[700] : Colors.green[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingSearchBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        color: Colors.white,
        child: SafeArea(
          child: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: TextField(
              controller: controller.searchController,
              onChanged: controller.searchQueryChanged,
              decoration: InputDecoration(
                hintText: 'البحث عن عميل...',
                border: InputBorder.none,
                icon: Icon(Icons.search, color: Colors.blue[700]),
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn();
  }

  Widget _buildFloatingActionButton() {
    return Positioned(
      bottom: 16,
      right: 16,
      child: FloatingActionButton.extended(
        onPressed: () {
          // Add new client
        },
        backgroundColor: Colors.blue[700],
        icon: const Icon(Icons.add),
        label: const Text('إضافة عميل'),
      ).animate().fadeIn().scale(),
    );
  }
}