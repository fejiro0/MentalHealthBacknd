import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/baseline_service.dart';
import '../../services/firebase_service.dart';
import '../../models/user_model.dart';
import '../../models/sensor_data_model.dart';
import '../../utils/constants.dart';

class BaselineRecordingScreen extends StatefulWidget {
  const BaselineRecordingScreen({super.key});

  @override
  State<BaselineRecordingScreen> createState() => _BaselineRecordingScreenState();
}

class _BaselineRecordingScreenState extends State<BaselineRecordingScreen> {
  UserModel? _currentUser;
  SensorDataModel? _currentSensorData;
  bool _isRecording = false;
  bool _isLoading = true;
  final Map<String, bool> _hasBaseline = {};

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _checkBaselines();
    _setupSensorListener();
  }

  Future<void> _loadUserData() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = await authService.getCurrentUserModel();
      
      if (mounted) {
        setState(() {
          _currentUser = user;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _checkBaselines() async {
    if (_currentUser == null) return;

    final baselineService = Provider.of<BaselineService>(context, listen: false);
    final deviceId = _currentUser!.assignedDeviceId ?? AppConstants.defaultDeviceId;
    
    for (final condition in AppConstants.baselineConditions) {
      final hasBaseline = await baselineService.hasBaseline(
        userId: _currentUser!.uid,
        deviceId: deviceId,
        condition: condition,
      );
      
      if (mounted) {
        setState(() {
          _hasBaseline[condition] = hasBaseline;
        });
      }
    }
  }

  void _setupSensorListener() {
    final firebaseService = Provider.of<FirebaseService>(context, listen: false);
    final deviceId = _currentUser?.assignedDeviceId ?? AppConstants.defaultDeviceId;
    
    firebaseService.getCurrentSensorData(deviceId).listen((sensorData) {
      if (mounted && sensorData != null) {
        setState(() => _currentSensorData = sensorData);
      }
    });
  }

  Future<void> _recordBaseline(String condition) async {
    if (_currentUser == null || _currentSensorData == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No sensor data available. Please wait...')),
      );
      return;
    }

    setState(() => _isRecording = true);

    try {
      final baselineService = Provider.of<BaselineService>(context, listen: false);
      final deviceId = _currentUser!.assignedDeviceId ?? AppConstants.defaultDeviceId;
      
      await baselineService.recordBaseline(
        userId: _currentUser!.uid,
        deviceId: deviceId,
        condition: condition,
        sensorData: _currentSensorData!,
      );

      if (mounted) {
        setState(() {
          _hasBaseline[condition] = true;
          _isRecording = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Baseline recorded for ${condition.toUpperCase()}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRecording = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error recording baseline: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _initializeBaseline(String condition) async {
    if (_currentUser == null) return;

    setState(() => _isRecording = true);

    try {
      final baselineService = Provider.of<BaselineService>(context, listen: false);
      final deviceId = _currentUser!.assignedDeviceId ?? AppConstants.defaultDeviceId;
      
      await baselineService.initializeBaseline(
        userId: _currentUser!.uid,
        deviceId: deviceId,
        condition: condition,
      );

      if (mounted) {
        setState(() {
          _hasBaseline[condition] = true;
          _isRecording = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Baseline initialized for ${condition.toUpperCase()}'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRecording = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initializing baseline: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
        title: const Text('Record Baselines'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info Card
            Card(
              color: Colors.blue.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Record baseline values when the person is in a calm, normal state. These values will be used as a reference for detecting anxiety, stress, and discomfort.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Current Sensor Data Preview
            if (_currentSensorData != null) ...[
              _buildSensorPreview(),
              const SizedBox(height: 24),
            ],
            // Baseline Options
            Text(
              'Select Condition to Record Baseline',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ...AppConstants.baselineConditions.map((condition) => _buildBaselineCard(condition)),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorPreview() {
    final data = _currentSensorData!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sensors, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Current Sensor Readings',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildPreviewValue('Temp', '${data.temperature.toStringAsFixed(1)}°C'),
                _buildPreviewValue('Humidity', '${data.humidity.toStringAsFixed(1)}%'),
                _buildPreviewValue('Motion', '${data.motion.magnitude.toStringAsFixed(2)}'),
                _buildPreviewValue('Sound', '${data.sound}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewValue(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      ],
    );
  }

  Widget _buildBaselineCard(String condition) {
    final hasBaseline = _hasBaseline[condition] ?? false;
    final conditionName = condition[0].toUpperCase() + condition.substring(1);

    IconData icon;
    Color color;
    
    switch (condition) {
      case 'anxiety':
        icon = Icons.mood_bad;
        color = Colors.orange;
        break;
      case 'stress':
        icon = Icons.warning;
        color = Colors.red;
        break;
      case 'discomfort':
        icon = Icons.sick;
        color = Colors.amber;
        break;
      default:
        icon = Icons.help;
        color = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        conditionName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            hasBaseline ? Icons.check_circle : Icons.circle_outlined,
                            size: 16,
                            color: hasBaseline ? Colors.green : Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            hasBaseline ? 'Baseline recorded' : 'No baseline set',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: hasBaseline ? Colors.green : Colors.grey[600],
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isRecording ? null : () => _initializeBaseline(condition),
                    icon: const Icon(Icons.add),
                    label: const Text('Initialize (Zero)'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isRecording || _currentSensorData == null
                        ? null
                        : () => _recordBaseline(condition),
                    icon: const Icon(Icons.fiber_manual_record),
                    label: const Text('Record Now'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

