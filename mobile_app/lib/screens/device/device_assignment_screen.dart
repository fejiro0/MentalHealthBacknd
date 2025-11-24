import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/device_service.dart';
import '../../models/user_model.dart';
import '../../models/device_model.dart';
import '../../utils/constants.dart';
import 'package:intl/intl.dart';

/// Screen for assigning/selecting a device for the user
class DeviceAssignmentScreen extends StatefulWidget {
  const DeviceAssignmentScreen({super.key});

  @override
  State<DeviceAssignmentScreen> createState() => _DeviceAssignmentScreenState();
}

class _DeviceAssignmentScreenState extends State<DeviceAssignmentScreen> {
  UserModel? _currentUser;
  DeviceModel? _assignedDevice;
  List<DeviceModel> _availableDevices = [];
  bool _isLoading = true;
  bool _isAssigning = false;

  @override
  void initState() {
    super.initState();
    // Defer heavy loading until after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final deviceService = Provider.of<DeviceService>(context, listen: false);
      
      final user = await authService.getCurrentUserModel();
      
      if (!mounted) return;
      
      if (user != null) {
        setState(() => _currentUser = user);
        
        // Load assigned device
        if (user.assignedDeviceId != null) {
          final device = await deviceService.getDevice(user.assignedDeviceId!);
          if (!mounted) return;
          setState(() => _assignedDevice = device);
        }
        
        // Load available devices
        deviceService.getAvailableDevices().listen((devices) {
          if (mounted) {
            setState(() => _availableDevices = devices);
          }
        });
      }
      
      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading devices: $e')),
      );
    }
  }

  Future<void> _assignDevice(String deviceId) async {
    if (_currentUser == null) return;

    setState(() => _isAssigning = true);

    try {
      final deviceService = Provider.of<DeviceService>(context, listen: false);
      
      // Assign device to user
      await deviceService.assignDeviceToUser(
        deviceId: deviceId,
        userId: _currentUser!.uid,
        patientId: _currentUser!.role == 'caregiver' ? _currentUser!.patientId : null,
      );

      // Reload user data
      final authService = Provider.of<AuthService>(context, listen: false);
      final updatedUser = await authService.getCurrentUserModel();
      
      if (!mounted) return;
      
      setState(() {
        _currentUser = updatedUser;
        _isAssigning = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Device assigned successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Reload assigned device
      if (updatedUser?.assignedDeviceId != null) {
        final device = await deviceService.getDevice(updatedUser!.assignedDeviceId!);
        if (!mounted) return;
        setState(() => _assignedDevice = device);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAssigning = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error assigning device: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _registerNewDevice() async {
    final deviceIdController = TextEditingController();
    final nameController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Register New Device'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: deviceIdController,
              decoration: const InputDecoration(
                labelText: 'Device ID',
                hintText: 'e.g., MXCHIP_001',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Device Name',
                hintText: 'e.g., Patient Device 1',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Register'),
          ),
        ],
      ),
    );

    if (result == true && deviceIdController.text.isNotEmpty) {
      setState(() => _isAssigning = true);
      
      try {
        final deviceService = Provider.of<DeviceService>(context, listen: false);
        
        await deviceService.registerDevice(
          deviceId: deviceIdController.text.trim(),
          name: nameController.text.trim().isEmpty
              ? deviceIdController.text.trim()
              : nameController.text.trim(),
          assignedUserId: _currentUser?.uid,
          patientId: _currentUser?.role == 'caregiver' ? _currentUser?.patientId : null,
        );

        // Auto-assign if registering for self
        if (_currentUser != null) {
          await deviceService.assignDeviceToUser(
            deviceId: deviceIdController.text.trim(),
            userId: _currentUser!.uid,
          );
        }

        if (!mounted) return;
        
        setState(() => _isAssigning = false);
        await _loadData();
        
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Device registered and assigned!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (mounted) {
          setState(() => _isAssigning = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error registering device: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
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
        title: const Text('Device Assignment'),
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
                        _currentUser?.role == 'caregiver'
                            ? 'As a caregiver, you can assign a device to monitor a patient\'s health data.'
                            : 'Assign a device to start monitoring your health data. The device ID should match your MXChip hardware.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Currently Assigned Device
            if (_assignedDevice != null) ...[
              Text(
                'Your Assigned Device',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              _buildDeviceCard(_assignedDevice!, isAssigned: true),
              const SizedBox(height: 24),
            ],
            // Available Devices
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Available Devices',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                TextButton.icon(
                  onPressed: _registerNewDevice,
                  icon: const Icon(Icons.add),
                  label: const Text('Register New'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_availableDevices.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Icon(Icons.devices_other, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No available devices',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Register a new device to get started',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[500],
                            ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._availableDevices.map((device) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildDeviceCard(device, isAssigned: false),
                  )),
            const SizedBox(height: 24),
            // Quick Assign Section
            Text(
              'Quick Assign',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Use Default Device',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Assign the default device (${AppConstants.defaultDeviceId}) if you haven\'t set up a custom device.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _isAssigning
                          ? null
                          : () => _assignDevice(AppConstants.defaultDeviceId),
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Assign Default Device'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceCard(DeviceModel device, {required bool isAssigned}) {
    final statusColor = device.status == DeviceStatus.active
        ? Colors.green
        : device.status == DeviceStatus.inactive
            ? Colors.orange
            : Colors.grey;

    return Card(
      elevation: isAssigned ? 4 : 2,
      color: isAssigned ? Colors.green.withOpacity(0.05) : null,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.sensors, color: statusColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        device.deviceId,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                              fontFamily: 'monospace',
                            ),
                      ),
                    ],
                  ),
                ),
                if (isAssigned)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Assigned',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            if (device.lastSeen != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Last seen: ${DateFormat('MMM dd, HH:mm').format(device.lastSeen!)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ],
            if (!isAssigned) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isAssigning
                      ? null
                      : () => _assignDevice(device.deviceId),
                  icon: const Icon(Icons.link),
                  label: const Text('Assign This Device'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

