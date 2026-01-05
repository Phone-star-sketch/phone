# Design Document: تحسين أداء صفحة قائمة العملاء

## Overview

هذا التصميم يهدف لتحسين أداء صفحة قائمة العملاء من خلال:
1. تقليل تكلفة Realtime updates
2. إزالة Animation controllers الزائدة
3. تحسين Widget rebuilds
4. تحسين أداء البحث
5. تحسين ListView performance

## Architecture

### Current Architecture (المشاكل)

```
AllClientsPage (StatefulWidget)
├── AnimationController (page-level)
├── Obx() → rebuilds everything
│   ├── Header (rebuilds unnecessarily)
│   └── ListView
│       └── ModernClientCard (440 cards)
│           ├── AnimationController (per card!) ❌
│           ├── GetBuilder (no id) ❌
│           └── Complex nested widgets
│
AccountClientInfo (Controller)
├── RxList<Client> clinets (with full nested data) ❌
├── Realtime stream (fetches all nested data every 5s) ❌
└── Search (filters entire list on every keystroke) ❌
```

### New Architecture (الحل)

```
AllClientsPage (StatefulWidget)
├── AnimationController (header only)
├── Separated sections with targeted rebuilds
│   ├── Header (const, no rebuilds)
│   ├── Toolbar (GetBuilder with id: 'toolbar')
│   └── ClientListView (GetBuilder with id: 'client-list')
│       └── ListView.builder (optimized)
│           └── ClientCard (StatelessWidget)
│               ├── RepaintBoundary
│               ├── const decorations
│               └── GetBuilder with id: 'client-${client.id}'
│
AccountClientInfo (Controller)
├── RxList<Client> clinets (basic data only)
├── Map<int, Client> _fullDataCache (lazy-loaded)
├── Realtime stream (basic data, throttled 10s)
├── Debounced search (300ms)
└── Indexed search cache
```

## Components and Interfaces

### 1. Optimized Controller

```dart
class AccountClientInfo extends GetxController {
  // Basic client data (always loaded)
  RxList<Client> clinets = <Client>[].obs;
  
  // Full data cache (lazy-loaded on demand)
  final Map<int, Client> _fullDataCache = {};
  
  // Search optimization
  final Map<String, List<Client>> _searchCache = {};
  Timer? _searchCacheCleanup;
  
  // Realtime optimization
  Timer? _realtimeThrottle;
  DateTime _lastRealtimeUpdate = DateTime.now();
  static const Duration _realtimeThrottleDuration = Duration(seconds: 10);
  
  // Fetch full client data on demand
  Future<Client> getFullClientData(int clientId) async {
    if (_fullDataCache.containsKey(clientId)) {
      return _fullDataCache[clientId]!;
    }
    
    final fullClient = await BackendServices.instance.clientRepository
        .read(clientId);
    
    _fullDataCache[clientId] = fullClient;
    
    // Limit cache size
    if (_fullDataCache.length > 50) {
      final oldestKey = _fullDataCache.keys.first;
      _fullDataCache.remove(oldestKey);
    }
    
    return fullClient;
  }
  
  // Optimized search with caching
  List<Client> searchClients(String query) {
    if (query.isEmpty) return clinets;
    
    final normalizedQuery = normalizeArabic(query);
    
    // Check cache
    if (_searchCache.containsKey(normalizedQuery)) {
      return _searchCache[normalizedQuery]!;
    }
    
    // Perform search
    final results = clinets.where((client) {
      final normalizedName = normalizeArabic(client.name ?? '');
      final phone = client.numbers?.isNotEmpty == true 
          ? client.numbers![0].phoneNumber ?? ''
          : '';
      
      return normalizedName.contains(normalizedQuery) ||
             phone.contains(normalizedQuery);
    }).toList();
    
    // Cache results
    _searchCache[normalizedQuery] = results;
    
    // Schedule cache cleanup
    _scheduleCacheCleanup();
    
    return results;
  }
  
  void _scheduleCacheCleanup() {
    _searchCacheCleanup?.cancel();
    _searchCacheCleanup = Timer(const Duration(minutes: 5), () {
      _searchCache.clear();
    });
  }
  
  // Optimized realtime subscription
  void setupRealtimeSubscription() {
    final repository = BackendServices.instance.clientRepository 
        as SupabaseClientRepository;
    
    _clientSubscription = repository
        .getBasicRealtimeClients(currentAccount)
        .listen((updatedClients) {
          final now = DateTime.now();
          
          // Throttle updates
          if (now.difference(_lastRealtimeUpdate) < _realtimeThrottleDuration) {
            return;
          }
          
          _lastRealtimeUpdate = now;
          clinets.value = updatedClients;
          
          // Clear caches on update
          _searchCache.clear();
          
          // Update specific cards only
          update(['client-list']);
        });
  }
}
```

### 2. Optimized Repository

```dart
class SupabaseClientRepository {
  // New method: fetch basic data only
  Future<List<Client>> getBasicClientsByAccount(Account account) async {
    final values = await _client
        .from(clientTableName)
        .select("id, name, total_cash, account_id, expire_date")
        .eq("account_id", account.id)
        .order('name', ascending: true);
    
    return values.map((e) => Client.fromJson(e)).toList();
  }
  
  // New method: basic realtime stream
  Stream<List<Client>> getBasicRealtimeClients(Account account) {
    return _client
        .from(clientTableName)
        .stream(primaryKey: ['id'])
        .eq('account_id', account.id)
        .order('name')
        .map((list) => list.map((e) => Client.fromJson(e)).toList());
  }
  
  // Existing method: full data for single client
  @override
  Future<Client> read(Object id) async {
    final data = await _client
        .from(clientTableName)
        .select("*, phone(* ,system(* , system_type(*))), log(*)")
        .eq('id', id)
        .single();
    
    return Client.fromJson(data);
  }
}
```

### 3. Optimized Page Widget

```dart
class AllClientsPage extends StatefulWidget {
  const AllClientsPage({super.key});

  @override
  _AllClientsPageState createState() => _AllClientsPageState();
}

class _AllClientsPageState extends State<AllClientsPage>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  final controller = Get.find<AccountClientInfo>();
  late AnimationController _headerAnimationController;
  
  @override
  void initState() {
    super.initState();
    // Single animation for header only
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _headerAnimationController.forward();
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Container(
      key: const PageStorageKey<String>('allClientsPage'),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
        ),
      ),
      child: Column(
        children: [
          // Animated Header (once)
          FadeTransition(
            opacity: _headerAnimationController,
            child: const _ClientPageHeader(),
          ),
          
          // Toolbar (targeted rebuild)
          GetBuilder<AccountClientInfo>(
            id: 'toolbar',
            builder: (ctrl) => _ClientToolbar(controller: ctrl),
          ),
          
          // Client List (targeted rebuild)
          Expanded(
            child: GetBuilder<AccountClientInfo>(
              id: 'client-list',
              builder: (ctrl) {
                if (ctrl.isLoading.value) {
                  return const _LoadingView();
                }
                
                if (Loaders.to.paymentIsLoading.value) {
                  return ModernPaymentLoadingWidget();
                }
                
                final filteredClients = ctrl.searchClients(ctrl.query.value);
                
                return _OptimizedClientListView(
                  clients: filteredClients,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
```

### 4. Optimized Client Card

```dart
class _OptimizedClientCard extends StatelessWidget {
  const _OptimizedClientCard({
    required this.client,
    required this.index,
  });

  final Client client;
  final int index;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GetBuilder<AccountClientInfo>(
        id: 'client-${client.id}',
        builder: (controller) {
          final isSelected = controller.clientPrintAdded.contains(client);
          
          return _ClientCardContent(
            client: client,
            index: index,
            isSelected: isSelected,
            onTap: () => _handleTap(context, controller),
            onCopy: () => _handleCopy(client),
            onEdit: () => _handleEdit(context, client),
            onDelete: () => _handleDelete(context, controller, client),
          );
        },
      ),
    );
  }
  
  void _handleTap(BuildContext context, AccountClientInfo controller) async {
    if (controller.enableMulipleClientPrint.value) {
      _toggleSelection(controller);
    } else {
      // Fetch full data before showing details
      final fullClient = await controller.getFullClientData(client.id!);
      showClientInfoSheet(context, fullClient);
    }
  }
  
  void _toggleSelection(AccountClientInfo controller) {
    if (controller.clientPrintAdded.contains(client)) {
      controller.clientPrintAdded.remove(client);
    } else {
      controller.clientPrintAdded.add(client);
    }
    // Update only this card
    controller.update(['client-${client.id}']);
  }
}

class _ClientCardContent extends StatelessWidget {
  const _ClientCardContent({
    required this.client,
    required this.index,
    required this.isSelected,
    required this.onTap,
    required this.onCopy,
    required this.onEdit,
    required this.onDelete,
  });

  final Client client;
  final int index;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onCopy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  // Cached colors to avoid recalculation
  static final List<Color> _baseColors = [
    const Color(0xFF3B82F6),
    const Color(0xFF10B981),
    const Color(0xFF8B5CF6),
    const Color(0xFFF59E0B),
    const Color(0xFFEF4444),
  ];

  Color get _baseColor => _baseColors[index % _baseColors.length];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        border: Border.all(
          color: isSelected ? const Color(0xFF3B82F6) : Colors.grey[200]!,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? const Color(0xFF3B82F6).withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.06),
            blurRadius: isSelected ? 16 : 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Section
                Row(
                  children: [
                    // Avatar
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_baseColor, _baseColor.withValues(alpha: 0.7)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Name & Phone
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            client.name ?? 'غير محدد',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Color(0xFF1E293B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.phone_rounded,
                                size: 12,
                                color: Color(0xFF64748B),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  client.getFormattedPhoneNumber(),
                                  style: const TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                // Divider
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(height: 1, color: Color(0xFFE2E8F0)),
                ),
                
                // Bottom Section
                Row(
                  children: [
                    // Money Status
                    Expanded(child: _MoneyStatusChip(client: client)),
                    const SizedBox(width: 8),
                    
                    // Action Buttons
                    _ActionButton(
                      icon: Icons.content_copy_rounded,
                      color: const Color(0xFF10B981),
                      onPressed: onCopy,
                    ),
                    const SizedBox(width: 4),
                    _ActionButton(
                      icon: Icons.edit_rounded,
                      color: const Color(0xFF8B5CF6),
                      onPressed: onEdit,
                    ),
                    const SizedBox(width: 4),
                    _ActionButton(
                      icon: Icons.delete_rounded,
                      color: const Color(0xFFEF4444),
                      onPressed: onDelete,
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
}
```

### 5. Optimized ListView

```dart
class _OptimizedClientListView extends StatelessWidget {
  const _OptimizedClientListView({
    required this.clients,
  });

  final List<Client> clients;

  @override
  Widget build(BuildContext context) {
    if (clients.isEmpty) {
      return const _EmptyView();
    }

    return ListView.builder(
      itemCount: clients.length,
      physics: const BouncingScrollPhysics(),
      // Performance optimizations
      cacheExtent: 800,
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: true,
      // Provide item extent for better performance
      itemExtentBuilder: (index, dimensions) => 140.0,
      // Separator
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _OptimizedClientCard(
            client: clients[index],
            index: index,
          ),
        );
      },
    );
  }
}
```

## Data Models

### Client Model (Modified)

```dart
class Client extends Model {
  // Basic fields (always loaded)
  String? name;
  double totalCash;
  int? accountId;
  DateTime? expireDate;
  
  // Lazy-loaded fields (null until fetched)
  List<PhoneNumber>? numbers;
  List<Log>? logs;
  List<System>? systems;
  
  // Flag to track if full data is loaded
  bool _isFullDataLoaded = false;
  
  bool get isFullDataLoaded => _isFullDataLoaded;
  
  // Factory for basic data
  factory Client.basic(Map<String, dynamic> json) {
    return Client(
      id: json['id'],
      name: json['name'],
      totalCash: json['total_cash'] ?? 0.0,
      accountId: json['account_id'],
      expireDate: json['expire_date'] != null 
          ? DateTime.parse(json['expire_date']) 
          : null,
    ).._isFullDataLoaded = false;
  }
  
  // Factory for full data
  factory Client.full(Map<String, dynamic> json) {
    final client = Client.fromJson(json);
    client._isFullDataLoaded = true;
    return client;
  }
}
```

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Realtime Throttling
*For any* sequence of realtime updates within 10 seconds, only the last update should be applied to the UI
**Validates: Requirements 1.3, 1.5**

### Property 2: Cache Size Limit
*For any* number of full client data fetches, the cache size should never exceed 50 items
**Validates: Requirements 6.5**

### Property 3: Search Debouncing
*For any* sequence of search inputs within 300ms, only the last input should trigger a search operation
**Validates: Requirements 4.1**

### Property 4: Targeted Rebuilds
*For any* client selection change, only the affected card widget should rebuild, not the entire list
**Validates: Requirements 3.2**

### Property 5: Basic Data Loading
*For any* initial page load, only basic client data (id, name, total_cash, account_id) should be fetched, not nested relations
**Validates: Requirements 1.1, 7.2**

### Property 6: Lazy Loading Full Data
*For any* client details view, full nested data should be fetched only when the user opens that specific client
**Validates: Requirements 1.2, 10.2**

### Property 7: Animation Performance
*For any* list scroll, animations should only be applied to visible cards, not all cards
**Validates: Requirements 2.2**

### Property 8: Search Cache Cleanup
*For any* search cache, unused entries should be cleared after 5 minutes
**Validates: Requirements 6.4**

### Property 9: ListView Optimization
*For any* list with more than 100 items, ListView.builder should use itemExtent or prototypeItem for better performance
**Validates: Requirements 5.1**

### Property 10: Memory Cleanup
*For any* controller disposal, all timers, streams, and subscriptions should be properly cancelled
**Validates: Requirements 6.1, 6.2**

## Error Handling

### Network Errors
- Show retry button with clear error message
- Cache last successful data for offline viewing
- Timeout after 20 seconds with appropriate message

### Realtime Connection Errors
- Gracefully degrade to manual refresh
- Show connection status indicator
- Auto-reconnect with exponential backoff

### Search Errors
- Never crash on invalid input
- Handle Arabic text normalization errors
- Clear cache on errors

### Memory Errors
- Implement cache eviction strategy
- Monitor memory usage in debug mode
- Clear caches when memory pressure is high

## Testing Strategy

### Unit Tests
- Test search debouncing logic
- Test cache size limiting
- Test realtime throttling
- Test Arabic text normalization
- Test client data factories (basic vs full)

### Property-Based Tests
- Property 1: Realtime throttling (generate rapid updates, verify only last applied)
- Property 2: Cache size limit (generate many fetches, verify max 50 items)
- Property 3: Search debouncing (generate rapid inputs, verify single search)
- Property 4: Targeted rebuilds (track rebuild counts per widget)
- Property 5: Basic data loading (verify no nested data in initial fetch)

### Performance Tests
- Measure initial load time (target: < 2 seconds)
- Measure scroll FPS (target: 60 FPS)
- Measure search response time (target: < 100ms)
- Measure memory usage (target: < 200MB for 500 clients)
- Measure rebuild counts (target: < 10 rebuilds per interaction)

### Integration Tests
- Test full user flow: load → search → select → view details
- Test realtime updates during user interaction
- Test bulk operations with realtime paused
- Test offline mode with cached data

## Performance Targets

| Metric | Current | Target | Improvement |
|--------|---------|--------|-------------|
| Initial Load | ~5s | <2s | 60% faster |
| Scroll FPS | ~30 FPS | 60 FPS | 2x smoother |
| Search Time | ~500ms | <100ms | 5x faster |
| Memory Usage | ~400MB | <200MB | 50% less |
| Rebuilds per action | ~440 | <10 | 98% less |
| Realtime Update Cost | High | Low | 80% less |

## Implementation Notes

1. **Phase 1**: Optimize data loading (basic vs full)
2. **Phase 2**: Remove animation controllers from cards
3. **Phase 3**: Implement targeted rebuilds with GetBuilder ids
4. **Phase 4**: Optimize search with caching
5. **Phase 5**: Optimize ListView with proper configuration
6. **Phase 6**: Add performance monitoring

## Migration Strategy

1. Keep old code in place initially
2. Add new optimized methods alongside
3. Test thoroughly with performance metrics
4. Switch to new implementation
5. Remove old code after verification
6. Monitor production performance
