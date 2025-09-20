import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phone_system_app/controllers/account_client_info_data.dart';
import 'package:phone_system_app/controllers/client_bottom_sheet_controller.dart';
import 'package:phone_system_app/models/client.dart';
import 'package:phone_system_app/models/system.dart';
import 'package:phone_system_app/models/system_type.dart';
import 'package:phone_system_app/utils/string_utils.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/services.dart';
import 'package:phone_system_app/services/backend/backend_services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as developer;
import 'package:phone_system_app/services/excel_generator.dart';

class ClientsReceipts extends StatefulWidget {
  const ClientsReceipts({super.key});

  @override
  State<ClientsReceipts> createState() => _ClientsReceiptsState();
}

class _ClientsReceiptsState extends State<ClientsReceipts>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  final controller = Get.find<AccountClientInfo>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Selection state
  final Set<String> _selectedClientIds = <String>{};
  bool get _isAnySelected => _selectedClientIds.isNotEmpty;
  bool _isAllSelected(List<Client> clients) =>
      clients.isNotEmpty && _selectedClientIds.length == clients.length;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Container(
      key: const PageStorageKey<String>('clientsReceiptsPage'),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFF8FAFC),
            Color(0xFFE2E8F0),
          ],
        ),
      ),
      child: Obx(() {
        final q = controller.query.value;
        final filteredData = _getFilteredClients(q);
        final totalCash = _calculateTotalCash(filteredData);

        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              children: [
                // Header Section
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFFFF).withOpacity(0.9),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 12.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF10B981),
                                      Color(0xFF059669)
                                    ],
                                  ),
                                  borderRadius: const BorderRadius.all(
                                      Radius.circular(8)),
                                ),
                                child: const Icon(
                                  FontAwesomeIcons.receipt,
                                  color: Color(0xFFFFFFFF),
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'الفواتير الشهرية ',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              // Selection Info
                              if (_isAnySelected)
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[100],
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'محدد: ${_selectedClientIds.length}',
                                    style: TextStyle(
                                      color: Colors.blue[800],
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              // Excel Export Button
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: _isAnySelected
                                        ? [Color(0xFF2196F3), Color(0xFF1976D2)]
                                        : [
                                            Colors.grey[400]!,
                                            Colors.grey[500]!
                                          ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: _isAnySelected
                                        ? () =>
                                            _exportSelectedToExcel(filteredData)
                                        : null,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.file_download,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            _isAnySelected
                                                ? 'تصدير المحدد'
                                                : 'تصدير Excel',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Selection Controls Row
                          if (filteredData.isNotEmpty)
                            Row(
                              children: [
                                // Select All Button
                                TextButton.icon(
                                  onPressed: () =>
                                      _toggleSelectAll(filteredData),
                                  icon: Icon(
                                    _isAllSelected(filteredData)
                                        ? Icons.check_box
                                        : Icons.check_box_outline_blank,
                                    size: 18,
                                    color: Colors.blue[700],
                                  ),
                                  label: Text(
                                    _isAllSelected(filteredData)
                                        ? 'إلغاء تحديد الكل'
                                        : 'تحديد الكل',
                                    style: TextStyle(
                                      color: Colors.blue[700],
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                // Clear Selection Button
                                if (_isAnySelected)
                                  TextButton.icon(
                                    onPressed: _clearSelection,
                                    icon: Icon(
                                      Icons.clear,
                                      size: 18,
                                      color: Colors.red[600],
                                    ),
                                    label: Text(
                                      'مسح التحديد',
                                      style: TextStyle(
                                        color: Colors.red[600],
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                              ],
                            ),

                          const SizedBox(height: 12),
                          // Search Field
                          ModernSearchField(
                            controller: controller.searchController,
                            onChanged: controller.searchQueryChanged,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Client Cards List
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: filteredData.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            itemCount: filteredData.length,
                            itemBuilder: (context, index) {
                              final client = filteredData[index];
                              final isSelected = _selectedClientIds
                                  .contains(client.id?.toString());

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: ClientReceiptCard(
                                  client: client,
                                  isSelected: isSelected,
                                  onSelectionChanged: (selected) {
                                    setState(() {
                                      if (selected) {
                                        _selectedClientIds
                                            .add(client.id?.toString() ?? '');
                                      } else {
                                        _selectedClientIds
                                            .remove(client.id?.toString());
                                      }
                                    });
                                  },
                                  onNoteSaved: () {
                                    // Refresh the list after note is saved
                                    controller.updateCurrnetClinets();
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  // Extract filtering logic
  List<Client> _getFilteredClients(String query) {
    List<Client> clients =
        controller.clinets.where((element) => element.totalCash < 0).toList();

    if (query.isEmpty) return clients;

    return clients.where((element) {
      final hasMatchingPhone = element.numbers?.isNotEmpty == true &&
          element.numbers![0].phoneNumber?.contains(query) == true;

      final hasMatchingName = element.name != null &&
          removeSpecialArabicChars(element.name!)
              .contains(removeSpecialArabicChars(query));

      return hasMatchingPhone || hasMatchingName;
    }).toList();
  }

  // Calculate total cash
  num _calculateTotalCash(List<Client> clients) {
    if (clients.isEmpty) return 0;
    return clients
        .map((e) => e.totalCash)
        .reduce((value, element) => value + element);
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required String unit,
    required List<Color> gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [gradient[0].withOpacity(0.1), gradient[1].withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: gradient[0].withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradient),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 14,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: gradient[0],
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: gradient[0],
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: TextStyle(
                  color: gradient[0].withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Color(0xFFF5F5F5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              FontAwesomeIcons.receipt,
              size: 64,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'لا توجد مستحقات',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'جميع العملاء قد سددوا مستحقاتهم',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  // Selection Methods
  void _toggleSelectAll(List<Client> clients) {
    setState(() {
      if (_isAllSelected(clients)) {
        _selectedClientIds.clear();
      } else {
        _selectedClientIds.clear();
        for (final client in clients) {
          if (client.id != null) {
            _selectedClientIds.add(client.id.toString());
          }
        }
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedClientIds.clear();
    });
  }

  // Export Selected Items
  Future<void> _exportSelectedToExcel(List<Client> allClients) async {
    try {
      final selectedClients = allClients.where((client) {
        return _selectedClientIds.contains(client.id?.toString());
      }).toList();

      if (selectedClients.isEmpty) {
        Get.showSnackbar(
          GetSnackBar(
            title: 'تنبيه',
            message: 'لم يتم تحديد أي عملاء للتصدير',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange[100]!,
            messageText: Text(
              'لم يتم تحديد أي عملاء للتصدير',
              style: TextStyle(color: Colors.orange[900]),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }

      // Show loading indicator
      Get.dialog(
        Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'جاري تصدير ${selectedClients.length} عميل...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ),
        barrierDismissible: false,
      );

      // Generate Excel file for selected clients
      await SimpleExcelGenerator.generateClientsReceiptsExcel(selectedClients);

      // Close loading dialog
      Get.back();

      // Clear selection after successful export
      setState(() {
        _selectedClientIds.clear();
      });
    } catch (e) {
      // Close loading dialog if open
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      developer.log('Error exporting selected to Excel: $e',
          name: 'ClientsReceipts');

      Get.showSnackbar(
        GetSnackBar(
          title: 'خطأ',
          message: 'فشل في تصدير البيانات المحددة إلى Excel',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red[100]!,
          messageText: Text(
            'فشل في تصدير البيانات المحددة إلى Excel',
            style: TextStyle(color: Colors.red[900]),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}

class ClientReceiptCard extends StatefulWidget {
  final Client client;
  final bool isSelected;
  final Function(bool) onSelectionChanged;
  final VoidCallback onNoteSaved;

  const ClientReceiptCard({
    super.key,
    required this.client,
    required this.isSelected,
    required this.onSelectionChanged,
    required this.onNoteSaved,
  });

  @override
  State<ClientReceiptCard> createState() => _ClientReceiptCardState();
}

class _ClientReceiptCardState extends State<ClientReceiptCard>
    with TickerProviderStateMixin {
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;
  bool _isExpanded = false;
  List<System> _clientSystems = [];
  bool _isLoadingSystems = true;

  final TextEditingController _noteController = TextEditingController();
  bool _isSavingNote = false;
  String _currentSavedNote = ''; // Track the currently saved note from database

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    );

    // Load existing note
    _loadExistingNotes();

    _loadClientSystems();
  }

  Future<void> _loadExistingNotes() async {
    try {
      // Load notes from the clients table notes column
      final supabase = Supabase.instance.client;
      final result = await supabase
          .from('client')
          .select('notes')
          .eq('id', widget.client.id)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _currentSavedNote = result?['notes'] ?? '';
          _noteController.text = _currentSavedNote;
        });
      }
    } catch (e) {
      // Log errors silently to terminal only
      if (e.toString().contains('ChannelRateLimitReached') ||
          e.toString().contains('Too many channels')) {
        developer.log(
            'Supabase channel rate limit reached while loading notes: $e',
            name: 'ClientReceiptCard');
      } else {
        developer.log('Error loading notes: $e', name: 'ClientReceiptCard');
      }

      // Set empty text if there's any error
      if (mounted) {
        setState(() {
          _currentSavedNote = '';
          _noteController.text = '';
        });
      }
    }
  }

  Future<void> _loadClientSystems() async {
    try {
      // Use the exact same approach as show_client_info_sheet.dart
      final String controllerTag =
          'temp_${widget.client.id}_${DateTime.now().millisecondsSinceEpoch}';

      try {
        // Create temporary controller with unique tag - ensure it's not null
        final tempController =
            Get.put(ClientBottomSheetController(), tag: controllerTag);
        await tempController.setClient(widget.client);

        final systems = tempController.getClientSystems();

        if (mounted) {
          setState(() {
            _clientSystems = systems;
            _isLoadingSystems = false;
          });
        }

        // Wait a bit before cleanup to ensure data is used
        await Future.delayed(const Duration(milliseconds: 50));
      } finally {
        // Clean up immediately after use
        if (Get.isRegistered<ClientBottomSheetController>(tag: controllerTag)) {
          Get.delete<ClientBottomSheetController>(
              tag: controllerTag, force: true);
        }
      }
    } catch (e) {
      // Log Supabase channel errors silently
      if (e.toString().contains('ChannelRateLimitReached') ||
          e.toString().contains('Too many channels')) {
        developer.log(
            'Supabase channel rate limit reached while loading client systems: $e',
            name: 'ClientReceiptCard');
      } else {
        developer.log('Error loading client systems: $e',
            name: 'ClientReceiptCard');
      }

      // Fallback: try to get systems from client numbers
      if (mounted) {
        try {
          List<System> systemsFromNumbers = [];
          if (widget.client.numbers != null &&
              widget.client.numbers!.isNotEmpty) {
            for (var number in widget.client.numbers!) {
              if (number.systems != null) {
                systemsFromNumbers.addAll(number.systems!);
              }
            }
          }
          setState(() {
            _clientSystems = systemsFromNumbers;
            _isLoadingSystems = false;
          });
        } catch (fallbackError) {
          developer.log('Fallback error: $fallbackError',
              name: 'ClientReceiptCard');
          setState(() {
            _clientSystems = [];
            _isLoadingSystems = false;
          });
        }
      }
    }
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _expandController.forward();
      } else {
        _expandController.reverse();
      }
    });
  }

  Future<void> _saveNote() async {
    setState(() {
      _isSavingNote = true;
    });

    try {
      // Update the notes column in clients table using Supabase
      final supabase = Supabase.instance.client;

      developer.log('Saving note for client ID: ${widget.client.id}',
          name: 'ClientReceiptCard');

      // First, let's check if the client exists
      final existingClient = await supabase
          .from('client')
          .select('id, name')
          .eq('id', widget.client.id)
          .maybeSingle();

      developer.log('Existing client found: $existingClient',
          name: 'ClientReceiptCard');

      if (existingClient == null) {
        throw Exception(
            'Client with ID ${widget.client.id} not found in database');
      }

      // Now update the notes
      final result = await supabase
          .from('client')
          .update({
            'notes': _noteController.text.isEmpty ? null : _noteController.text
          })
          .eq('id', widget.client.id)
          .select('id, notes');

      developer.log('Note update successful: $result',
          name: 'ClientReceiptCard');

      // Update the current saved note state
      setState(() {
        _currentSavedNote = _noteController.text;
      });

      // Update the main client data controller to refresh the entire client list
      final accountController = Get.find<AccountClientInfo>();
      accountController.updateCurrnetClinets();

      widget.onNoteSaved();

      // Only show success message, no error messages
      Get.showSnackbar(
        GetSnackBar(
          title: 'نجح الحفظ',
          message: 'تم حفظ الملاحظة بنجاح',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green[100]!,
          messageText: Text(
            'تم حفظ الملاحظة بنجاح',
            style: TextStyle(color: Colors.green[900]),
          ),
          duration: const Duration(seconds: 2),
          icon: const Icon(Icons.check_circle, color: Colors.green),
        ),
      );
    } catch (e) {
      // Log all errors silently to terminal only, no UI feedback
      if (e.toString().contains('ChannelRateLimitReached') ||
          e.toString().contains('Too many channels')) {
        developer.log(
            'Supabase channel rate limit reached while saving note: $e',
            name: 'ClientReceiptCard');
      } else if (e
          .toString()
          .contains('type \'int\' is not a subtype of type \'double\'')) {
        developer.log('Type conversion error while saving note: $e',
            name: 'ClientReceiptCard');
      } else {
        developer.log('Error updating notes: $e', name: 'ClientReceiptCard');
      }

      // Don't show any error snackbar to user, handle silently
      // The user will simply not see the success message if it fails
    } finally {
      setState(() {
        _isSavingNote = false;
      });
    }
  }

  // Helper methods from show_client_info_sheet for system management
  List<System> _getVisibleSystems(List<System> systems) {
    return systems.where((system) {
      if (system.type!.category == SystemCategory.mobileInternet) {
        // Show other services only if not paid and within collection period
        bool isPaid = _isSystemPaid(system);
        bool shouldShow = _shouldShowSystem(system);
        return !isPaid && shouldShow;
      }
      // Always show flex systems
      return true;
    }).toList();
  }

  bool _isSystemPaid(System system) {
    // Check if system is marked as paid
    bool isPaid = system.name?.contains('[مدفوع]') ?? false;
    return isPaid;
  }

  bool _shouldShowSystem(System system) {
    if (system.type!.category == SystemCategory.mobileInternet) {
      if (system.createdAt != null) {
        final accountController = Get.find<AccountClientInfo>();
        final collectionDay = accountController.currentAccount.day;
        final nextCollection = DateTime(
          system.createdAt!.month == 12
              ? system.createdAt!.year + 1
              : system.createdAt!.year,
          system.createdAt!.month == 12 ? 1 : system.createdAt!.month + 1,
          collectionDay,
        );
        return !DateTime.now().isAfter(nextCollection);
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: widget.isSelected
            ? Border.all(color: Colors.blue[400]!, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: widget.isSelected
                ? Colors.blue.withOpacity(0.2)
                : _isExpanded
                    ? Colors.blue.withOpacity(0.1)
                    : Colors.black.withOpacity(0.05),
            blurRadius: _isExpanded ? 15 : 10,
            offset: const Offset(0, 5),
            spreadRadius: _isExpanded ? 2 : 0,
          ),
        ],
      ),
      child: Column(
        children: [
          // Main Card Content
          InkWell(
            onTap: _toggleExpanded,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Client Info Row with Selection
                  Row(
                    children: [
                      // Selection Checkbox
                      GestureDetector(
                        onTap: () =>
                            widget.onSelectionChanged(!widget.isSelected),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: widget.isSelected
                                ? Colors.blue[600]
                                : Colors.transparent,
                            border: Border.all(
                              color: widget.isSelected
                                  ? Colors.blue[600]!
                                  : Colors.grey[400]!,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: widget.isSelected
                              ? const Icon(
                                  Icons.check,
                                  size: 18,
                                  color: Colors.white,
                                )
                              : const SizedBox(width: 18, height: 18),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Avatar
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: widget.isSelected
                                ? [Colors.blue[600]!, Colors.blue[800]!]
                                : [Colors.blue[700]!, Colors.blue[900]!],
                          ),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            widget.client.name?[0].toUpperCase() ?? 'N',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Client Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.client.name ?? 'غير محدد',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: widget.isSelected
                                    ? Colors.blue[800]
                                    : const Color(0xFF1E293B),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.phone,
                                  size: 16,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    widget.client.numbers?.isNotEmpty == true
                                        ? (widget.client.numbers![0]
                                                .phoneNumber ??
                                            'غير متوفر')
                                        : 'غير متوفر',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Current Notes Display (Real-time from database)
                            if (_currentSavedNote.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.blue[200]!),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.note_alt,
                                      size: 14,
                                      color: Colors.blue[700],
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'ملاحظة: $_currentSavedNote',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.blue[700],
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 8),
                            // Due Amount - Fix type conversion error
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red[200]!),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    FontAwesomeIcons.moneyBillWave,
                                    size: 14,
                                    color: Colors.red[700],
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'مستحق: ${((widget.client.totalCash ?? 0) * -1).toStringAsFixed(0)} ج.م',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red[700],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Expand/Collapse Icon
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: widget.isSelected
                              ? Colors.blue[50]
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: AnimatedRotation(
                          turns: _isExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 300),
                          child: Icon(
                            Icons.keyboard_arrow_down,
                            color: widget.isSelected
                                ? Colors.blue[700]
                                : Colors.grey[600],
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Expandable Content
          AnimatedBuilder(
            animation: _expandAnimation,
            builder: (context, child) {
              return ClipRect(
                child: Align(
                  alignment: Alignment.topCenter,
                  heightFactor: _expandAnimation.value,
                  child: child,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 20),

                  // Systems Section
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.devices,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'الخدمات المشترك بها',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  _isLoadingSystems
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : _clientSystems.isEmpty
                          ? Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'لا توجد خدمات مشترك بها',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _getVisibleSystems(_clientSystems)
                                  .map((system) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        _isSystemPaid(system)
                                            ? Colors.green[100]!
                                            : Colors.purple[100]!,
                                        _isSystemPaid(system)
                                            ? Colors.green[50]!
                                            : Colors.purple[50]!,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: _isSystemPaid(system)
                                          ? Colors.green[200]!
                                          : Colors.purple[200]!,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _isSystemPaid(system)
                                            ? Icons.paid
                                            : Icons.check_circle,
                                        size: 14,
                                        color: _isSystemPaid(system)
                                            ? Colors.green[700]
                                            : Colors.purple[700],
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        system.type?.name ?? 'غير محدد',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: _isSystemPaid(system)
                                              ? Colors.green[700]
                                              : Colors.purple[700],
                                        ),
                                      ),
                                      if (system.type?.price != null)
                                        Text(
                                          ' (${system.type!.price} ج.م)',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: _isSystemPaid(system)
                                                ? Colors.green[600]
                                                : Colors.purple[600],
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),

                  const SizedBox(height: 20),

                  // Notes Section
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.note_alt,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'الملاحظات',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Note Input Field
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: TextField(
                      controller: _noteController,
                      maxLines: 3,
                      textDirection: TextDirection.rtl,
                      decoration: InputDecoration(
                        hintText: 'أضف ملاحظة للعميل...',
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Save Note Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSavingNote ? null : _saveNote,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: _isSavingNote
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.save, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'حفظ الملاحظة',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Search Field Widget
class ModernSearchField extends StatelessWidget {
  const ModernSearchField({
    super.key,
    required this.controller,
    this.onChanged,
  });

  final TextEditingController controller;
  final Function(String)? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,
        style: const TextStyle(
          color: Color(0xFF1E293B),
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: "ابحث عن عميل (الاسم، رقم الهاتف)",
          hintStyle: TextStyle(
            color: Color(0xFFBDBDBD),
            fontSize: 14,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              FontAwesomeIcons.magnifyingGlass,
              color: Colors.white,
              size: 18,
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}
