import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/device_model.dart';
import '../utils/constants.dart';

/// Service for managing device registration and user-device associations
class DeviceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // Register a new device in the system
  Future<void> registerDevice({
    required String deviceId,
    required String name,
    String? assignedUserId,
    String? patientId,
  }) async {
    try {
      final deviceMetadata = {
        'deviceId': deviceId,
        'name': name,
        'assignedUserId': assignedUserId,
        'patientId': patientId,
        'registeredAt': DateTime.now().toIso8601String(),
        'lastSeen': DateTime.now().toIso8601String(),
        'status': DeviceStatus.active.name,
        'hardwareInfo': {
          'model': 'MXChip AZ3166',
          'firmwareVersion': '1.0',
        },
      };

      // Store device metadata in Realtime Database
      await _database
          .child(AppConstants.devicesCollection)
          .child(deviceId)
          .child('metadata')
          .set(deviceMetadata);

      // Also store in Firestore for easier querying
      await _firestore
          .collection('devices')
          .doc(deviceId)
          .set(deviceMetadata);
    } catch (e) {
      throw 'Error registering device: ${e.toString()}';
    }
  }

  // Assign device to a user
  Future<void> assignDeviceToUser({
    required String deviceId,
    required String userId,
    String? patientId,
  }) async {
    try {
      // Update device metadata
      await _database
          .child(AppConstants.devicesCollection)
          .child(deviceId)
          .child('metadata')
          .update({
        'assignedUserId': userId,
        'patientId': patientId,
        'lastSeen': DateTime.now().toIso8601String(),
        'status': DeviceStatus.active.name,
      });

      // Update Firestore
      await _firestore
          .collection('devices')
          .doc(deviceId)
          .update({
        'assignedUserId': userId,
        'patientId': patientId,
        'lastSeen': DateTime.now().toIso8601String(),
        'status': DeviceStatus.active.name,
      });

      // Update user document to include device
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({
        'assignedDeviceId': deviceId,
      });
    } catch (e) {
      throw 'Error assigning device: ${e.toString()}';
    }
  }

  // Get device metadata
  Future<DeviceModel?> getDevice(String deviceId) async {
    try {
      // Try Firestore first (faster)
      final doc = await _firestore
          .collection('devices')
          .doc(deviceId)
          .get();

      if (doc.exists && doc.data() != null) {
        return DeviceModel.fromJson(doc.data()!);
      }

      // Fallback to Realtime Database
      final snapshot = await _database
          .child(AppConstants.devicesCollection)
          .child(deviceId)
          .child('metadata')
          .get();

      if (snapshot.exists && snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        return DeviceModel.fromJson(data);
      }

      return null;
    } catch (e) {
      throw 'Error fetching device: ${e.toString()}';
    }
  }

  // Get all available devices (not assigned)
  Stream<List<DeviceModel>> getAvailableDevices() {
    return _firestore
        .collection('devices')
        .where('assignedUserId', isNull: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DeviceModel.fromJson(doc.data()))
            .toList());
  }

  // Get devices assigned to a user
  Stream<List<DeviceModel>> getUserDevices(String userId) {
    return _firestore
        .collection('devices')
        .where('assignedUserId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DeviceModel.fromJson(doc.data()))
            .toList());
  }

  // Get device assigned to user
  Future<DeviceModel?> getUserAssignedDevice(String userId) async {
    try {
      final userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();

      if (!userDoc.exists || userDoc.data() == null) return null;

      final assignedDeviceId = userDoc.data()?['assignedDeviceId'];
      if (assignedDeviceId == null) return null;

      return getDevice(assignedDeviceId);
    } catch (e) {
      throw 'Error fetching user device: ${e.toString()}';
    }
  }

  // Update device last seen timestamp
  Future<void> updateDeviceLastSeen(String deviceId) async {
    try {
      final now = DateTime.now().toIso8601String();
      
      await _database
          .child(AppConstants.devicesCollection)
          .child(deviceId)
          .child('metadata')
          .update({
        'lastSeen': now,
        'status': DeviceStatus.active.name,
      });

      await _firestore
          .collection('devices')
          .doc(deviceId)
          .update({
        'lastSeen': now,
        'status': DeviceStatus.active.name,
      });
    } catch (e) {
      // Silent fail for last seen updates
      debugPrint('Error updating device last seen: $e');
    }
  }

  // Check if device exists and is active
  Future<bool> isDeviceActive(String deviceId) async {
    try {
      final device = await getDevice(deviceId);
      if (device == null) return false;

      // Check if device has sent data recently (within last 5 minutes)
      if (device.lastSeen != null) {
        final timeSinceLastSeen = DateTime.now().difference(device.lastSeen!);
        return timeSinceLastSeen.inMinutes < 5;
      }

      return false;
    } catch (e) {
      return false;
    }
  }
}

