import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';

class Company {
  final String name;
  final String taxNumber;
  final String ownerName;

  Company({
    required this.name,
    required this.taxNumber,
    required this.ownerName,
  });
}

class PhoneData {
  final String phoneNumber;
  final String? clientName;
  final String? nationalId;

  PhoneData({
    required this.phoneNumber,
    this.clientName,
    this.nationalId,
  });

  factory PhoneData.fromJson(Map<String, dynamic> json) {
    return PhoneData(
      phoneNumber: json['phone_number'] ?? '',
      clientName: json['name'],
      nationalId: json['national_id'],
    );
  }
}

class LetterOfWaiver extends StatefulWidget {
  const LetterOfWaiver({super.key});

  @override
  State<LetterOfWaiver> createState() => _LetterOfWaiverState();
}

class _LetterOfWaiverState extends State<LetterOfWaiver> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _recipientNameController =
      TextEditingController();
  final TextEditingController _nationalIdController = TextEditingController();
  final TextEditingController _waivedPhoneController = TextEditingController();
  bool _isLoading = false;

  // Autocomplete variables
  List<PhoneData> _phonesSuggestions = [];
  bool _isSearching = false;
  Timer? _debounce;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  final FocusNode _phoneNumberFocusNode = FocusNode();

  final List<Company> _companies = [
    Company(
      name: " محمد السيد عبد المجيد",
      taxNumber: "477-466-478",
      ownerName: "محمد السيد عبد المجيد",
    ),
    Company(
      name: "مواهب حسن علي محمد",
      taxNumber: "799-499-418",
      ownerName: "مواهب حسن علي محمد",
    ),
  ];

  int _selectedCompanyIndex = 0;

  @override
  void initState() {
    super.initState();
    _phoneNumberController.addListener(_onPhoneNumberChanged);
    _phoneNumberFocusNode.addListener(() {
      if (!_phoneNumberFocusNode.hasFocus) {
        _hideOverlay();
      }
    });
  }

  @override
  void dispose() {
    _phoneNumberController.removeListener(_onPhoneNumberChanged);
    _phoneNumberController.dispose();
    _recipientNameController.dispose();
    _nationalIdController.dispose();
    _waivedPhoneController.dispose();
    _phoneNumberFocusNode.dispose();
    _debounce?.cancel();
    _hideOverlay();
    super.dispose();
  }

  void _onPhoneNumberChanged() {
    // Don't update _waivedPhoneController here to avoid triggering listeners
    // We'll update it only when selecting from dropdown

    if (_debounce?.isActive ?? false) _debounce!.cancel();

    final query = _phoneNumberController.text.trim();
    if (query.isEmpty) {
      _hideOverlay();
      setState(() {
        _phonesSuggestions = [];
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () {
      _searchPhones(query);
    });
  }

  Future<void> _searchPhones(String query) async {
    if (query.isEmpty) return;

    debugPrint('=== DEBUG: Searching for: $query ===');
    setState(() => _isSearching = true);

    try {
      final response = await Supabase.instance.client
          .from('phone')
          .select('phone_number, client:client_id(name, national_id)')
          .ilike('phone_number', '%$query%')
          .limit(10);

      debugPrint('Response from Supabase: $response');

      final List<PhoneData> phones = [];
      for (var item in response) {
        debugPrint('Processing item: $item');
        final clientData = item['client'];
        debugPrint('Client data: $clientData');

        final phoneData = PhoneData(
          phoneNumber: item['phone_number'] ?? '',
          clientName: clientData != null ? clientData['name'] : null,
          nationalId: clientData != null ? clientData['national_id'] : null,
        );

        debugPrint(
            'Created PhoneData: phone=${phoneData.phoneNumber}, name=${phoneData.clientName}, id=${phoneData.nationalId}');
        phones.add(phoneData);
      }

      debugPrint('Total phones found: ${phones.length}');

      if (mounted) {
        setState(() {
          _phonesSuggestions = phones;
          _isSearching = false;
        });

        if (phones.isNotEmpty && _phoneNumberFocusNode.hasFocus) {
          _showOverlay();
        } else {
          _hideOverlay();
        }
      }
    } catch (e) {
      debugPrint('ERROR in _searchPhones: $e');
      if (mounted) {
        setState(() => _isSearching = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في البحث: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _selectPhone(PhoneData phoneData) {
    debugPrint('=== DEBUG: _selectPhone called ===');
    debugPrint('Phone Number: ${phoneData.phoneNumber}');
    debugPrint('Client Name: ${phoneData.clientName}');
    debugPrint('National ID: ${phoneData.nationalId}');

    // Hide overlay and remove focus first
    _hideOverlay();
    FocusScope.of(context).unfocus();

    // Update all fields in setState
    setState(() {
      // Update phone number fields
      _phoneNumberController.text = phoneData.phoneNumber;
      _waivedPhoneController.text = phoneData.phoneNumber;

      // Update client name if available
      if (phoneData.clientName != null && phoneData.clientName!.isNotEmpty) {
        _recipientNameController.text = phoneData.clientName!;
        debugPrint('✓ Set recipient name: ${phoneData.clientName}');
      } else {
        _recipientNameController.clear();
        debugPrint('✗ Client name is null or empty');
      }

      // Update national ID if available
      if (phoneData.nationalId != null && phoneData.nationalId!.isNotEmpty) {
        _nationalIdController.text = phoneData.nationalId!;
        debugPrint('✓ Set national ID: ${phoneData.nationalId}');
      } else {
        _nationalIdController.clear();
        debugPrint('✗ National ID is null or empty');
      }
    });

    debugPrint('=== DEBUG: _selectPhone completed ===');
  }

  void _showOverlay() {
    _hideOverlay();

    debugPrint('=== DEBUG: _showOverlay called ===');
    debugPrint('Suggestions count: ${_phonesSuggestions.length}');

    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      debugPrint('ERROR: RenderBox is null');
      return;
    }

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: MediaQuery.of(context).size.width > 800
            ? 900 - 56 - 40 // maxWidth - padding
            : MediaQuery.of(context).size.width - 40 - 56,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 75),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 300),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue[200]!, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: _phonesSuggestions.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'لا توجد نتائج',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      shrinkWrap: true,
                      itemCount: _phonesSuggestions.length,
                      itemBuilder: (context, index) {
                        final phone = _phonesSuggestions[index];
                        return InkWell(
                          onTap: () {
                            debugPrint(
                                '=== Tapped on phone: ${phone.phoneNumber} ===');
                            _selectPhone(phone);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.blue[50]?.withValues(alpha: 0.5),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.blue[100],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.phone_android_rounded,
                                        color: Colors.blue[700],
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        phone.phoneNumber,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue[900],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (phone.clientName != null) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.person_rounded,
                                          color: Colors.grey[600], size: 16),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          phone.clientName!,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                if (phone.nationalId != null) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.credit_card_rounded,
                                          color: Colors.grey[600], size: 16),
                                      const SizedBox(width: 6),
                                      Text(
                                        phone.nationalId!,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    debugPrint('=== DEBUG: Overlay inserted ===');
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWideScreen = size.width > 800;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            const Color(0xFF1A237E), // Deep indigo
            const Color(0xFF283593),
            const Color(0xFF3949AB),
            Colors.indigo[300]!,
          ],
          stops: const [0.0, 0.3, 0.6, 1.0],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: Container(
            constraints:
                BoxConstraints(maxWidth: isWideScreen ? 900 : double.infinity),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isWideScreen ? 40 : 20,
                vertical: 30,
              ),
              child: Column(
                children: [
                  // Modern Header with Animation
                  _buildModernHeader(),
                  const SizedBox(height: 20),

                  // Main Content Card
                  _buildMainContentCard(isWideScreen),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Icon with gradient background
        
          // Title
          Text(
            'خطاب تنازل',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Colors.indigo[900],
              letterSpacing: 0.5,
            ),
          ),
          // Subtitle
          Text(
            'إنشاء خطاب تنازل رسمي بسهولة وسرعة',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMainContentCard(bool isWideScreen) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 40,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Column(
          children: [
            // Company Selection Section with gradient header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.indigo[50]!, Colors.purple[50]!],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.indigo[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.business,
                            color: Colors.indigo[700], size: 24),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'معلومات الشركة',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo[900],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildModernCompanySelector(),
                  const SizedBox(height: 16),
                  _buildModernCompanyInfoCard(),
                ],
              ),
            ),

            // Form Section
            Padding(
              padding: const EdgeInsets.all(28.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.purple[100],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.edit_document,
                              color: Colors.purple[700], size: 24),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'بيانات التنازل',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo[900],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildPhoneAutocompleteField(),
                    const SizedBox(height: 20),
                    _buildModernFormField(
                      _recipientNameController,
                      'تفويض للسيد/السيدة',
                      Icons.person_rounded,
                      Colors.green,
                    ),
                    const SizedBox(height: 20),
                    _buildModernFormField(
                      _nationalIdController,
                      'بطاقة رقم قومي',
                      Icons.credit_card_rounded,
                      Colors.orange,
                    ),
                    const SizedBox(height: 20),
                    _buildModernFormField(
                      _waivedPhoneController,
                      'للتنازل عن خط رقم',
                      Icons.phone_forwarded_rounded,
                      Colors.purple,
                    ),
                    const SizedBox(height: 36),
                    _buildModernSubmitButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernCompanySelector() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        border: Border.all(color: Colors.indigo[200]!, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedCompanyIndex,
          isExpanded: true,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              color: Colors.indigo[700], size: 28),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.indigo[900],
          ),
          items: [
            DropdownMenuItem(
              value: 0,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.indigo[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child:
                        Icon(Icons.store, color: Colors.indigo[700], size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(_companies[0].name)),
                ],
              ),
            ),
            DropdownMenuItem(
              value: 1,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.purple[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child:
                        Icon(Icons.store, color: Colors.purple[700], size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(_companies[1].name)),
                ],
              ),
            ),
          ],
          onChanged: (value) {
            if (value != null) setState(() => _selectedCompanyIndex = value);
          },
        ),
      ),
    );
  }

  Widget _buildModernCompanyInfoCard() {
    Company selectedCompany = _companies[_selectedCompanyIndex];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Colors.indigo[50]!.withValues(alpha: 0.3)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.indigo[100]!, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoRow(
            Icons.business_rounded,
            'اسم الشركة',
            selectedCompany.name,
            Colors.indigo,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.person_rounded,
            'المالك',
            selectedCompany.ownerName,
            Colors.purple,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.receipt_long_rounded,
            'رقم ضريبي',
            selectedCompany.taxNumber.split('-').reversed.join('-'),
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneAutocompleteField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Autocomplete<PhoneData>(
        optionsBuilder: (TextEditingValue textEditingValue) async {
          if (textEditingValue.text.isEmpty) {
            return const Iterable<PhoneData>.empty();
          }

          debugPrint('=== Autocomplete searching for: ${textEditingValue.text} ===');

          try {
            final response = await Supabase.instance.client
                .from('phone')
                .select('phone_number, client:client_id(name, national_id)')
                .ilike('phone_number', '%${textEditingValue.text}%')
                .limit(10);

            debugPrint('Response: $response');

            final List<PhoneData> phones = [];
            for (var item in response) {
              final clientData = item['client'];
              phones.add(PhoneData(
                phoneNumber: item['phone_number'] ?? '',
                clientName: clientData != null ? clientData['name'] : null,
                nationalId:
                    clientData != null ? clientData['national_id'] : null,
              ));
            }

            debugPrint('Found ${phones.length} phones');
            return phones;
          } catch (e) {
            debugPrint('ERROR: $e');
            return const Iterable<PhoneData>.empty();
          }
        },
        displayStringForOption: (PhoneData option) => option.phoneNumber,
        onSelected: (PhoneData selection) {
          debugPrint('=== Selected: ${selection.phoneNumber} ===');
          setState(() {
            _phoneNumberController.text = selection.phoneNumber;
            _waivedPhoneController.text = selection.phoneNumber;

            if (selection.clientName != null &&
                selection.clientName!.isNotEmpty) {
              _recipientNameController.text = selection.clientName!;
              debugPrint('✓ Set name: ${selection.clientName}');
            }

            if (selection.nationalId != null &&
                selection.nationalId!.isNotEmpty) {
              _nationalIdController.text = selection.nationalId!;
              debugPrint('✓ Set ID: ${selection.nationalId}');
            }
          });
        },
        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
          // Initialize with current value only once
          if (controller.text.isEmpty && _phoneNumberController.text.isNotEmpty) {
            controller.text = _phoneNumberController.text;
          }

          return TextFormField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            onChanged: (value) {
              // Update other controllers when user types
              _phoneNumberController.text = value;
              _waivedPhoneController.text = value;
            },
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[900],
            ),
            decoration: InputDecoration(
              labelText: 'المالك للخط رقم',
              labelStyle: TextStyle(
                color: Colors.blue[700],
                fontWeight: FontWeight.w500,
              ),
              prefixIcon: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.phone_android_rounded,
                    color: Colors.blue[700], size: 22),
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.blue[200]!, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.blue[200]!, width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.blue[600]!, width: 2.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.red, width: 2.5),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            ),
            validator: (value) =>
                value?.isEmpty == true ? 'برجاء إدخال رقم الهاتف' : null,
          );
        },
        optionsViewBuilder: (context, onSelected, options) {
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                constraints:
                    const BoxConstraints(maxHeight: 300, maxWidth: 400),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue[200]!, width: 2),
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final phone = options.elementAt(index);
                    return InkWell(
                      onTap: () => onSelected(phone),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.blue[50]?.withValues(alpha: 0.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.phone_android_rounded,
                                    color: Colors.blue[700],
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    phone.phoneNumber,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[900],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (phone.clientName != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.person_rounded,
                                      color: Colors.grey[600], size: 16),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      phone.clientName!,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (phone.nationalId != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.credit_card_rounded,
                                      color: Colors.grey[600], size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    phone.nationalId!,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(
      IconData icon, String label, String value, MaterialColor color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color[100],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color[700], size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[900],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModernFormField(
    TextEditingController controller,
    String label,
    IconData icon,
    MaterialColor color, {
    FocusNode? focusNode,
    bool isSearching = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.grey[900],
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: color[700],
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color[700], size: 22),
          ),
          suffixIcon: isSearching
              ? Padding(
                  padding: const EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(color[600]!),
                    ),
                  ),
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: color[200]!, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: color[200]!, width: 2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: color[600]!, width: 2.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.red, width: 2.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        ),
        validator: (value) =>
            value?.isEmpty == true ? 'برجاء إدخال $label' : null,
      ),
    );
  }

  Widget _buildModernSubmitButton() {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            Colors.indigo[700]!,
            Colors.indigo[500]!,
            Colors.purple[400]!,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        onPressed: _isLoading
            ? null
            : () async {
                if (_formKey.currentState!.validate()) {
                  setState(() => _isLoading = true);
                  try {
                    await _generatePDF();
                  } finally {
                    if (mounted) {
                      setState(() => _isLoading = false);
                    }
                  }
                }
              },
        child: _isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'جاري الإنشاء...',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.picture_as_pdf_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'إنشاء خطاب التنازل',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  String convertToArabicNumbers(String input) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    for (int i = 0; i < english.length; i++) {
      input = input.replaceAll(english[i], arabic[i]);
    }
    return input;
  }

  String fixArabicText(String text) {
    String normalized = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    normalized = normalized.replaceAll('ی', 'ي').replaceAll('ک', 'ك');
    return normalized;
  }

  Future<void> _generatePDF() async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.cairoRegular();
    final fontBold = await PdfGoogleFonts.cairoBold();
    Company selectedCompany = _companies[_selectedCompanyIndex];

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Padding(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 25, vertical: 30),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  // Header
                  pw.Align(
                    alignment: pw.Alignment.centerRight,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.only(bottom: 8),
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(
                            bottom: pw.BorderSide(
                                width: 2, color: PdfColors.black)),
                      ),
                      child: pw.Text(
                        'السادة / شركـة فودافـون',
                        style: pw.TextStyle(font: fontBold, fontSize: 20),
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Center(
                      child: pw.Text('تحية طيبه وبعد ،،،',
                          style: pw.TextStyle(font: font, fontSize: 15))),
                  pw.SizedBox(height: 20),

                  // Body
                  pw.RichText(
                    textDirection: pw.TextDirection.rtl,
                    text: pw.TextSpan(
                      style:
                          pw.TextStyle(font: font, fontSize: 14, height: 1.5),
                      children: [
                        const pw.TextSpan(
                            text: 'يرجي التكرم الإحاطة بالعلم بأننا شركة : '),
                        pw.TextSpan(
                            text: fixArabicText(selectedCompany.name),
                            style: pw.TextStyle(font: fontBold)),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.RichText(
                    textDirection: pw.TextDirection.rtl,
                    text: pw.TextSpan(
                      style:
                          pw.TextStyle(font: font, fontSize: 14, height: 1.5),
                      children: [
                        const pw.TextSpan(text: 'المشهرة بسجل ضريبي رقم : '),
                        pw.TextSpan(
                            text: convertToArabicNumbers(
                                selectedCompany.taxNumber),
                            style: pw.TextStyle(font: fontBold)),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.RichText(
                    textDirection: pw.TextDirection.rtl,
                    text: pw.TextSpan(
                      style:
                          pw.TextStyle(font: font, fontSize: 14, height: 1.5),
                      children: [
                        const pw.TextSpan(text: 'و المالكـة للخــط رقم : '),
                        pw.TextSpan(
                            text: convertToArabicNumbers(
                                _phoneNumberController.text),
                            style: pw.TextStyle(font: fontBold)),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.RichText(
                    textDirection: pw.TextDirection.rtl,
                    text: pw.TextSpan(
                      style:
                          pw.TextStyle(font: font, fontSize: 14, height: 1.5),
                      children: [
                        const pw.TextSpan(
                            text: 'بأننا قد فوضنا السيد / السيدة : '),
                        pw.TextSpan(
                            text: fixArabicText(_recipientNameController.text),
                            style: pw.TextStyle(font: fontBold)),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.RichText(
                    textDirection: pw.TextDirection.rtl,
                    text: pw.TextSpan(
                      style:
                          pw.TextStyle(font: font, fontSize: 14, height: 1.5),
                      children: [
                        const pw.TextSpan(text: 'بطاقة رقم قومي : '),
                        pw.TextSpan(
                            text: convertToArabicNumbers(
                                _nationalIdController.text),
                            style: pw.TextStyle(font: fontBold)),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.RichText(
                    textDirection: pw.TextDirection.rtl,
                    text: pw.TextSpan(
                      style:
                          pw.TextStyle(font: font, fontSize: 14, height: 1.5),
                      children: [
                        const pw.TextSpan(text: 'للتنازل عن الخط رقم : '),
                        pw.TextSpan(
                            text: convertToArabicNumbers(
                                _waivedPhoneController.text),
                            style: pw.TextStyle(font: fontBold)),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 20),

                  // Declaration
                  pw.Text(
                    'لنفسه و كمـا تقرر الشركة بأنها قـد قامت بسداد جميع المستحقات المتعلقة بالخط المذكور عاليه قبل تاريخ هذا الإقرار كما نقر بموافقتنا علي الأعمال السابق ذكرها وأنه لا يجوز لنا الرجوع في اى عمـل مــن الأعمال المتضمنة في هذا الإقرار.',
                    style: pw.TextStyle(font: font, fontSize: 13, height: 1.6),
                    textAlign: pw.TextAlign.justify,
                  ),
                  pw.SizedBox(height: 30),

                  // Signatures
                  pw.Text('إسم المفوض الأصلي :',
                      style: pw.TextStyle(font: fontBold, fontSize: 14),
                      textAlign: pw.TextAlign.right),
                  pw.SizedBox(height: 15),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('توقيع المفوض بموجب هذا الإقرار ،،،',
                                style: pw.TextStyle(font: font, fontSize: 12)),
                            pw.SizedBox(height: 20),
                            // pw.Container(
                            //     height: 1,
                            //     width: 120,
                            //     color: PdfColors.grey600),
                          ],
                        ),
                      ),
                      pw.SizedBox(width: 20),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.RichText(
                              textDirection: pw.TextDirection.rtl,
                              text: pw.TextSpan(
                                style: pw.TextStyle(font: font, fontSize: 12),
                                children: [
                                  const pw.TextSpan(text: 'التوقيع : '),
                                  pw.TextSpan(
                                      text: 'إسلام محمد عبد الرسول النني',
                                      style: pw.TextStyle(font: fontBold)),
                                ],
                              ),
                            ),
                            pw.SizedBox(height: 20),
                            // pw.Container(
                            //     height: 1,
                            //     width: 120,
                            //     color: PdfColors.grey600),
                          ],
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 20),
                  pw.RichText(
                    textDirection: pw.TextDirection.rtl,
                    text: pw.TextSpan(
                      style: pw.TextStyle(font: font, fontSize: 13),
                      children: [
                        const pw.TextSpan(text: 'التاريخ :    '),
                        pw.TextSpan(
                            text:
                                '${convertToArabicNumbers(DateTime.now().year.toString())}/      /    ',
                            style: pw.TextStyle(font: fontBold)),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 25),
                  pw.Align(
                    alignment: pw.Alignment.centerRight,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        border:
                            pw.Border.all(color: PdfColors.grey600, width: 1.5),
                        borderRadius:
                            const pw.BorderRadius.all(pw.Radius.circular(6)),
                      ),
                      child: pw.Text('خاتم الشركه المفوضة',
                          style: pw.TextStyle(font: fontBold, fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    final Uint8List pdfData = await pdf.save();
    final dateStr = DateFormat('yyyy_MM_dd').format(DateTime.now());

    if (kIsWeb) {
      await Printing.sharePdf(
          bytes: pdfData,
          filename: 'خطاب_تنازل_${selectedCompany.name}_$dateStr.pdf');
    } else {
      final directory = await getApplicationDocumentsDirectory();
      final String filePath =
          '${directory.path}/خطاب_تنازل_${selectedCompany.name}_$dateStr.pdf';
      final File file = File(filePath);
      await file.writeAsBytes(pdfData);
      await OpenFile.open(filePath);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'تم إنشاء خطاب التنازل لشركة ${selectedCompany.name} بنجاح'),
              backgroundColor: Colors.green),
        );
      }
    }
  }
}
