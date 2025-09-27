import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class DuesShowPage extends StatefulWidget {
  const DuesShowPage({Key? key}) : super(key: key);

  @override
  State<DuesShowPage> createState() => _DuesShowPageState();
}

class _DuesShowPageState extends State<DuesShowPage>
    with TickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  final _searchController = TextEditingController();

  List<Map<String, dynamic>> _allDues = [];
  List<Map<String, dynamic>> _filteredDues = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _editingId;
  bool _isSaving = false;

  // Edit controllers
  final Map<String, TextEditingController> _editControllers = {};
  final Map<String, DateTime?> _editDates = {};

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _fetchDues();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    // Dispose edit controllers
    for (final controller in _editControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _filteredDues = _allDues.where((due) {
        final name = _getStringValue(due['name']) ?? '';
        final phone = _getStringValue(due['phone']) ?? '';
        return name.toLowerCase().contains(_searchQuery) ||
            phone.toLowerCase().contains(_searchQuery);
      }).toList();
    });
  }

  Future<void> _fetchDues() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await supabase
          .from('dues')
          .select()
          .order('created_at', ascending: false);

      setState(() {
        _allDues = List<Map<String, dynamic>>.from(response);
        _filteredDues = _allDues;
        _isLoading = false;
      });

      _animationController.forward();
    } catch (error) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل البيانات: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  bool _isOverdue(dynamic endsAtValue) {
    if (endsAtValue == null) return false;

    DateTime endsAt;
    if (endsAtValue is String) {
      endsAt = DateTime.parse(endsAtValue);
    } else if (endsAtValue is int) {
      endsAt = DateTime.fromMillisecondsSinceEpoch(endsAtValue);
    } else {
      return false;
    }

    return endsAt.isBefore(DateTime.now());
  }

  Color _getStatusColor(dynamic endsAtValue) {
    if (endsAtValue == null) return Colors.grey;

    if (_isOverdue(endsAtValue)) {
      return Colors.red;
    }

    DateTime endsAt;
    if (endsAtValue is String) {
      endsAt = DateTime.parse(endsAtValue);
    } else if (endsAtValue is int) {
      endsAt = DateTime.fromMillisecondsSinceEpoch(endsAtValue);
    } else {
      return Colors.grey;
    }

    final daysLeft = endsAt.difference(DateTime.now()).inDays;

    if (daysLeft <= 7) {
      return Colors.orange;
    }
    return Colors.green;
  }

  String _getStatusText(dynamic endsAtValue) {
    if (endsAtValue == null) return 'غير محدد';

    if (_isOverdue(endsAtValue)) {
      return 'متأخر';
    }

    DateTime endsAt;
    if (endsAtValue is String) {
      endsAt = DateTime.parse(endsAtValue);
    } else if (endsAtValue is int) {
      endsAt = DateTime.fromMillisecondsSinceEpoch(endsAtValue);
    } else {
      return 'غير محدد';
    }

    final daysLeft = endsAt.difference(DateTime.now()).inDays;

    if (daysLeft <= 7) {
      return 'ينتهي قريباً';
    }
    return 'نشط';
  }

  void _startEditing(Map<String, dynamic> due) {
    final id = due['id'].toString();
    setState(() {
      _editingId = id;
    });

    // Initialize edit controllers with current values
    _editControllers['${id}_name'] = TextEditingController(
      text: _getStringValue(due['name']) ?? '',
    );
    _editControllers['${id}_phone'] = TextEditingController(
      text: _formatPhoneForDisplay(due['phone']),
    );
    _editControllers['${id}_amount'] = TextEditingController(
      text: _getAmountString(due['amount']),
    );

    // Initialize dates
    _editDates['${id}_created_at'] = due['created_at'] != null
        ? DateTime.parse(due['created_at'].toString())
        : null;
    _editDates['${id}_ends_at'] = due['ends_at'] != null
        ? DateTime.parse(due['ends_at'].toString())
        : null;
  }

  void _cancelEditing() {
    if (_editingId != null) {
      final id = _editingId!;
      // Dispose controllers
      _editControllers['${id}_name']?.dispose();
      _editControllers['${id}_phone']?.dispose();
      _editControllers['${id}_amount']?.dispose();

      // Remove from maps
      _editControllers.remove('${id}_name');
      _editControllers.remove('${id}_phone');
      _editControllers.remove('${id}_amount');
      _editDates.remove('${id}_created_at');
      _editDates.remove('${id}_ends_at');
    }

    setState(() {
      _editingId = null;
      _isSaving = false;
    });
  }

  Future<void> _saveChanges() async {
    if (_editingId == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final id = int.parse(_editingId!);
      final updates = <String, dynamic>{};

      // Get updated values
      final name = _editControllers['${_editingId}_name']?.text.trim();
      final phoneStr = _editControllers['${_editingId}_phone']?.text.trim();
      final amountText = _editControllers['${_editingId}_amount']?.text.trim();
      final createdAt = _editDates['${_editingId}_created_at'];
      final endsAt = _editDates['${_editingId}_ends_at'];

      // Validate and prepare updates
      if (name != null && name.isNotEmpty) {
        updates['name'] = name;
      }

      if (phoneStr != null && phoneStr.isNotEmpty) {
        final phoneNumber = _parsePhoneForStorage(phoneStr);
        if (phoneNumber != null) {
          updates['phone'] = phoneNumber;
        }
      }

      if (amountText != null && amountText.isNotEmpty) {
        final amount = double.tryParse(amountText);
        if (amount != null) {
          updates['amount'] = amount;
        }
      }

      if (createdAt != null) {
        updates['created_at'] = createdAt.toIso8601String();
      }

      if (endsAt != null) {
        updates['ends_at'] = endsAt.toIso8601String();
      }

      // Update in database
      await supabase.from('dues').update(updates).eq('id', id);

      // Update local data immediately
      for (int i = 0; i < _allDues.length; i++) {
        if (_allDues[i]['id'] == id) {
          _allDues[i] = {..._allDues[i], ...updates};
          break;
        }
      }

      // Update filtered dues
      for (int i = 0; i < _filteredDues.length; i++) {
        if (_filteredDues[i]['id'] == id) {
          _filteredDues[i] = {..._filteredDues[i], ...updates};
          break;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حفظ التغييرات بنجاح!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      _cancelEditing();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في حفظ التغييرات: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _selectEditDate(String dateKey, bool isEndDate) async {
    final currentDate = _editDates[dateKey] ?? DateTime.now();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF6366F1),
              brightness: Brightness.light,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _editDates[dateKey] = picked;
      });
    }
  }

  Future<void> _deleteDue(Map<String, dynamic> due) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.red, size: 28),
            const SizedBox(width: 8),
            const Text(
              'تأكيد الحذف',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'هل أنت متأكد من حذف مستحق "${_getStringValue(due['name']) ?? 'غير محدد'}"؟',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'لا يمكن التراجع عن هذا الإجراء',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'إلغاء',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'حذف',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _performDelete(due);
    }
  }

  Future<void> _performDelete(Map<String, dynamic> due) async {
    try {
      final id = due['id'];

      // Delete from database
      await supabase.from('dues').delete().eq('id', id);

      // Update local data
      setState(() {
        _allDues.removeWhere((item) => item['id'] == id);
        _filteredDues.removeWhere((item) => item['id'] == id);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حذف المستحق بنجاح!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في حذف المستحق: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Add method to calculate total amount
  double _calculateTotalAmount() {
    return _filteredDues.fold<double>(0.0, (sum, due) {
      final amount = due['amount'];
      if (amount is num) {
        return sum + amount.toDouble();
      }
      return sum;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667EEA),
              Color(0xFF764BA2),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'المستحقات',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: _fetchDues,
                        icon: const Icon(Icons.refresh, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),

              // Search Bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'البحث بالاسم أو رقم الهاتف...',
                    prefixIcon: Icon(Icons.search, color: Color(0xFF667EEA)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Total Price Display
              _buildTotalPriceCard(),

              const SizedBox(height: 20),

              // Content
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF667EEA),
                          ),
                        )
                      : _filteredDues.isEmpty
                          ? _buildEmptyState()
                          : _buildDuesList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTotalPriceCard() {
    final totalAmount = _calculateTotalAmount();
    final totalCount = _filteredDues.length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.white.withOpacity(0.95),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.8),
              blurRadius: 15,
              offset: const Offset(0, -2),
            ),
          ],
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Icon Container
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF667EEA),
                    Color(0xFF764BA2),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF667EEA).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.account_balance_wallet,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),

            // Total Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'إجمالي المستحقات',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        totalAmount.toStringAsFixed(0),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF667EEA),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Text(
                          'ج.م',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF667EEA),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Count Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF667EEA).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF667EEA).withOpacity(0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.group,
                    size: 16,
                    color: const Color(0xFF667EEA),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$totalCount',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF667EEA),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _searchQuery.isNotEmpty ? Icons.search_off : Icons.receipt_long,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? 'لا توجد نتائج للبحث'
                : 'لا توجد مستحقات حتى الآن',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'جرب البحث بكلمات أخرى'
                : 'ابدأ بإضافة مستحق جديد',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDuesList() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: RefreshIndicator(
        onRefresh: _fetchDues,
        color: const Color(0xFF667EEA),
        child: ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: _filteredDues.length,
          itemBuilder: (context, index) {
            final due = _filteredDues[index];
            return _buildDueCard(due, index);
          },
        ),
      ),
    );
  }

  Widget _buildDueCard(Map<String, dynamic> due, int index) {
    final statusColor = _getStatusColor(due['ends_at']);
    final statusText = _getStatusText(due['ends_at']);
    final isEditing = _editingId == due['id'].toString();
    final dueId = due['id'].toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                Colors.white,
                Colors.grey.shade50,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row with Edit/Save buttons
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                        ),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name field - Allow full width without constraints
                          isEditing
                              ? _buildEditField(
                                  controller:
                                      _editControllers['${dueId}_name']!,
                                  label: 'الاسم',
                                )
                              : Container(
                                  width: double.infinity,
                                  child: Text(
                                    _getStringValue(due['name']) ?? 'غير محدد',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                    softWrap: true,
                                    textAlign: TextAlign.start,
                                  ),
                                ),
                          const SizedBox(height: 4),
                          // Phone field
                          isEditing
                              ? _buildEditField(
                                  controller:
                                      _editControllers['${dueId}_phone']!,
                                  label: 'رقم الهاتف',
                                  keyboardType: TextInputType.phone,
                                )
                              : Text(
                                  _formatPhoneForDisplay(due['phone']),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Action buttons - Keep them in a column for better space management
                    Column(
                      children: [
                        if (!isEditing) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: statusColor.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              statusText,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 40,
                                height: 40,
                                child: IconButton(
                                  onPressed: () => _startEditing(due),
                                  icon: const Icon(Icons.edit, size: 20),
                                  color: const Color(0xFF667EEA),
                                  tooltip: 'تعديل',
                                  padding: EdgeInsets.zero,
                                ),
                              ),
                              const SizedBox(width: 4),
                              SizedBox(
                                width: 40,
                                height: 40,
                                child: IconButton(
                                  onPressed: () => _deleteDue(due),
                                  icon: const Icon(Icons.delete, size: 20),
                                  color: Colors.red,
                                  tooltip: 'حذف',
                                  padding: EdgeInsets.zero,
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          if (_isSaving)
                            const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF667EEA),
                              ),
                            )
                          else
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 40,
                                  height: 40,
                                  child: IconButton(
                                    onPressed: _saveChanges,
                                    icon: const Icon(Icons.check, size: 20),
                                    color: Colors.green,
                                    tooltip: 'حفظ',
                                    padding: EdgeInsets.zero,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                SizedBox(
                                  width: 40,
                                  height: 40,
                                  child: IconButton(
                                    onPressed: _cancelEditing,
                                    icon: const Icon(Icons.close, size: 20),
                                    color: Colors.red,
                                    tooltip: 'إلغاء',
                                    padding: EdgeInsets.zero,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Amount Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF667EEA).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: const Color(0xFF667EEA).withOpacity(0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.attach_money,
                        color: Color(0xFF667EEA),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'المبلغ:',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      const Spacer(),
                      isEditing
                          ? SizedBox(
                              width: 120,
                              child: _buildEditField(
                                controller:
                                    _editControllers['${dueId}_amount']!,
                                label: 'المبلغ',
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                              ),
                            )
                          : Text(
                              '${_getAmountString(due['amount'])} ج.م',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF667EEA),
                              ),
                            ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Dates Row
                Row(
                  children: [
                    Expanded(
                      child: _buildDateInfo(
                        'تاريخ الإنشاء',
                        isEditing
                            ? _editDates['${dueId}_created_at']
                            : due['created_at'],
                        Icons.calendar_today_outlined,
                        isEditing: isEditing,
                        onTap: isEditing
                            ? () =>
                                _selectEditDate('${dueId}_created_at', false)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDateInfo(
                        'تاريخ الانتهاء',
                        isEditing
                            ? _editDates['${dueId}_ends_at']
                            : due['ends_at'],
                        Icons.event_outlined,
                        isEndDate: true,
                        isEditing: isEditing,
                        onTap: isEditing
                            ? () => _selectEditDate('${dueId}_ends_at', true)
                            : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    TextAlign? textAlign,
  }) {
    return Container(
      height: 35,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF667EEA).withOpacity(0.3)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          textSelectionTheme: TextSelectionThemeData(
            cursorColor: Color(0xFF667EEA),
            selectionColor: Color(0xFF667EEA).withOpacity(0.3),
            selectionHandleColor: Color(0xFF667EEA),
          ),
        ),
        child: TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textAlign: textAlign ?? TextAlign.start,
          enableInteractiveSelection: true,
          showCursor: true,
          cursorColor: const Color(0xFF667EEA),
          cursorWidth: 2.0,
          selectionControls: MaterialTextSelectionControls(),
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
          ),
          decoration: InputDecoration(
            hintText: label,
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            hintStyle: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 12,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Color(0xFF667EEA),
                width: 2,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: const Color(0xFF667EEA).withOpacity(0.3),
                width: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateInfo(
    String label,
    dynamic dateValue,
    IconData icon, {
    bool isEndDate = false,
    bool isEditing = false,
    VoidCallback? onTap,
  }) {
    DateTime? date;
    if (dateValue != null) {
      try {
        if (dateValue is String) {
          date = DateTime.parse(dateValue);
        } else if (dateValue is int) {
          date = DateTime.fromMillisecondsSinceEpoch(dateValue);
        } else if (dateValue is DateTime) {
          date = dateValue;
        }
      } catch (e) {
        date = null;
      }
    }

    Color iconColor = Colors.grey.shade600;
    if (isEndDate && dateValue != null && !isEditing) {
      iconColor = _getStatusColor(dateValue);
    }

    return Container(
      decoration: BoxDecoration(
        color: isEditing ? Colors.white : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEditing
              ? const Color(0xFF667EEA).withOpacity(0.3)
              : Colors.grey.shade200,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: iconColor),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  if (isEditing) ...[
                    const Spacer(),
                    Icon(
                      Icons.edit,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                date != null
                    ? DateFormat('dd MMM yyyy', 'ar').format(date)
                    : 'غير محدد',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to safely get string values
  String? _getStringValue(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is int) {
      // For phone numbers, pad with leading zero if needed
      final phoneStr = value.toString();
      // If it's a phone number (based on length), add leading zero if missing
      if (phoneStr.length == 10 && !phoneStr.startsWith('0')) {
        return '0$phoneStr';
      }
      return phoneStr;
    }
    if (value is double) return value.toInt().toString();
    return value.toString();
  }

  // Helper method to format phone numbers for display
  String _formatPhoneForDisplay(dynamic phone) {
    if (phone == null) return 'غير محدد';

    String phoneStr = phone.toString();

    // If it's a 10-digit number without leading zero, add it
    if (phoneStr.length == 10 && !phoneStr.startsWith('0')) {
      phoneStr = '0$phoneStr';
    }

    return phoneStr;
  }

  // Helper method to convert phone for database storage
  int? _parsePhoneForStorage(String phoneStr) {
    if (phoneStr.isEmpty) return null;

    // Remove any non-digit characters
    final digitsOnly = phoneStr.replaceAll(RegExp(r'[^\d]'), '');

    // Parse as integer (this will remove leading zeros)
    return int.tryParse(digitsOnly);
  }

  // Helper method to get amount as string
  String _getAmountString(dynamic amount) {
    if (amount == null) return '0';
    if (amount is num) return amount.toString();
    return '0';
  }
}
