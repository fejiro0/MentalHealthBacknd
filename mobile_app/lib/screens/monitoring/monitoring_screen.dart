import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/firebase_service.dart';
import '../../models/user_model.dart';
import '../../models/sensor_data_model.dart';
import '../../models/emotional_state_model.dart';
import '../../utils/constants.dart';
import '../../widgets/sensor_charts_widget.dart';
import 'package:intl/intl.dart';

class MonitoringScreen extends StatefulWidget {
  const MonitoringScreen({super.key});

  @override
  State<MonitoringScreen> createState() => _MonitoringScreenState();
}

class _MonitoringScreenState extends State<MonitoringScreen> with SingleTickerProviderStateMixin {
  UserModel? _currentUser;
  SensorDataModel? _currentSensorData;
  EmotionalStateResult? _currentEmotionalState;
  List<EmotionalStateResult> _emotionalStateHistory = [];
  List<SensorDataModel> _sensorDataHistory = []; // For charts
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Defer heavy loading until after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = await authService.getCurrentUserModel();

      if (mounted) {
        setState(() {
          _currentUser = user;
          _isLoading = false;
        });
        // Setup monitoring after user is loaded (don't block navigation)
        Future.microtask(() => _setupRealtimeMonitoring());
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _setupRealtimeMonitoring() {
    if (_currentUser == null) {
      debugPrint('⚠️ MonitoringScreen: Cannot setup monitoring - user is null');
      return;
    }
    
    debugPrint('🔄 MonitoringScreen: Setting up realtime monitoring for user: ${_currentUser!.uid}');

    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);

    // Get user's assigned device ID or use default
    final deviceId =
        _currentUser!.assignedDeviceId ?? AppConstants.defaultDeviceId;

    // Listen to sensor data from user's assigned device
    firebaseService.getCurrentSensorData(deviceId).listen((sensorData) {
      if (mounted && sensorData != null) {
        setState(() {
          _currentSensorData = sensorData;
          // Add to history for charts (keep last 100 readings)
          _sensorDataHistory.add(sensorData);
          if (_sensorDataHistory.length > 100) {
            _sensorDataHistory.removeAt(0);
          }
        });
      }
    });

    // Also load historical sensor data for charts
    firebaseService.getHistoricalSensorData(deviceId, limit: 50).listen((historicalData) {
      if (mounted && historicalData.isNotEmpty) {
        setState(() {
          _sensorDataHistory = historicalData.reversed.toList();
        });
      }
    });

    // Listen to emotional state
    firebaseService.getCurrentEmotionalState(_currentUser!.uid).listen((state) {
      if (mounted && state != null) {
        setState(() => _currentEmotionalState = state);
      }
    });

    // Fetch emotional state history immediately (one-time)
    firebaseService.fetchEmotionalStateHistory(_currentUser!.uid, limit: 20).then((history) {
      if (mounted) {
        debugPrint('📊 MonitoringScreen: Initial fetch of emotional state history');
        debugPrint('   History count: ${history.length}');
        setState(() {
          _emotionalStateHistory = history;
        });
        if (history.isNotEmpty) {
          debugPrint('✅ MonitoringScreen: Initial history loaded and displayed');
        } else {
          debugPrint('⚠️ MonitoringScreen: No initial history data found');
        }
      }
    }).catchError((error) {
      debugPrint('❌ MonitoringScreen: Error fetching initial emotional state history: $error');
    });
    
    // Also listen to emotional state history (for updates)
    debugPrint('📊 MonitoringScreen: Starting to listen to emotional state history stream for user: ${_currentUser!.uid}');
    firebaseService
        .getEmotionalStateHistory(_currentUser!.uid, limit: 20)
        .listen((history) {
      if (mounted) {
        debugPrint('📊 MonitoringScreen: Received emotional state history update from stream');
        debugPrint('   History count: ${history.length}');
        setState(() {
          _emotionalStateHistory = history;
        });
        if (history.isNotEmpty) {
          debugPrint('✅ MonitoringScreen: History updated and displayed');
        } else {
          debugPrint('⚠️ MonitoringScreen: History is empty (no data yet)');
        }
      }
    }, onError: (error) {
      debugPrint('❌ MonitoringScreen: Error listening to emotional state history stream: $error');
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        appBar: null,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Real-time Monitoring'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
            Tab(icon: Icon(Icons.show_chart), text: 'Charts'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Dashboard Tab
          RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Current Emotional State Card
                  if (_currentEmotionalState != null) ...[
                    _buildEmotionalStateCard(),
                    const SizedBox(height: 24),
                  ],
                  // Sensor Data Card
                  if (_currentSensorData != null) ...[
                    _buildSensorDataCard(),
                    const SizedBox(height: 24),
                  ],
                  // History Section
                  if (_emotionalStateHistory.isNotEmpty) ...[
                    Text(
                      'Recent History',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                    ),
                    const SizedBox(height: 16),
                    ..._emotionalStateHistory.map((state) => _buildHistoryItem(state)),
                  ] else ...[
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      color: Colors.grey[100],
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            Icon(Icons.history, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No History Yet',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'History will appear here as events occur',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[500],
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Charts Tab
          SensorChartsWidget(
            sensorDataHistory: _sensorDataHistory,
            maxDataPoints: 50,
          ),
        ],
      ),
    );
  }

  Widget _buildEmotionalStateCard() {
    final state = _currentEmotionalState!.state;
    final confidence = _currentEmotionalState!.confidence;

    Color cardColor;
    IconData icon;

    switch (state) {
      case EmotionalState.anxiety:
        cardColor = Colors.orange;
        icon = Icons.mood_bad;
        break;
      case EmotionalState.stress:
        cardColor = Colors.red;
        icon = Icons.warning;
        break;
      case EmotionalState.discomfort:
        cardColor = Colors.amber;
        icon = Icons.sick;
        break;
      case EmotionalState.normal:
        cardColor = Colors.green;
        icon = Icons.check_circle;
        break;
      case EmotionalState.unknown:
        cardColor = Colors.grey;
        icon = Icons.help;
        break;
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: cardColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: cardColor),
            ),
            const SizedBox(height: 16),
            Text(
              state.displayName,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cardColor,
                  ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${(confidence * 100).toInt()}% Confidence',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: confidence,
                minHeight: 8,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(cardColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorDataCard() {
    final data = _currentSensorData!;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sensors, color: Theme.of(context).colorScheme.primary, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Current Sensor Data',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Compact 2x2 Grid
            Row(
              children: [
                Expanded(
                  child: _buildCompactSensorMetric(
                    'Temperature',
                    '${data.temperature.toStringAsFixed(1)}°C',
                    Icons.thermostat,
                    Colors.red,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCompactSensorMetric(
                    'Humidity',
                    '${data.humidity.toStringAsFixed(1)}%',
                    Icons.water_drop,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildCompactSensorMetric(
                    'Motion',
                    data.motion.magnitude.toStringAsFixed(2),
                    Icons.accessibility_new,
                    Colors.purple,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCompactSensorMetric(
                    'Sound',
                    '${data.sound}',
                    Icons.volume_up,
                    Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactSensorMetric(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(EmotionalStateResult state) {
    Color color;
    IconData icon;

    switch (state.state) {
      case EmotionalState.anxiety:
        color = Colors.orange;
        icon = Icons.mood_bad;
        break;
      case EmotionalState.stress:
        color = Colors.red;
        icon = Icons.warning;
        break;
      case EmotionalState.discomfort:
        color = Colors.amber;
        icon = Icons.sick;
        break;
      case EmotionalState.normal:
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case EmotionalState.unknown:
        color = Colors.grey;
        icon = Icons.help;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(
          state.state.displayName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          DateFormat('MMM dd, yyyy HH:mm:ss').format(state.detectedAt),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${(state.confidence * 100).toInt()}%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 60,
              child: LinearProgressIndicator(
                value: state.confidence,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
