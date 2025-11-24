// Device Management Endpoints for Backend
// Add these endpoints to your server.js

const express = require('express');
const router = express.Router();

// Register a new device
router.post('/devices/register', async (req, res) => {
    try {
        const { deviceId, name, assignedUserId, patientId } = req.body;

        if (!deviceId || !name) {
            return res.status(400).json({
                success: false,
                error: 'deviceId and name are required'
            });
        }

        const deviceMetadata = {
            deviceId,
            name,
            assignedUserId: assignedUserId || null,
            patientId: patientId || null,
            registeredAt: new Date().toISOString(),
            lastSeen: new Date().toISOString(),
            status: 'active',
            hardwareInfo: {
                model: 'MXChip AZ3166',
                firmwareVersion: '1.0'
            }
        };

        // Store in Realtime Database
        const metadataPath = `/devices/${deviceId}/metadata.json`;
        let metadataUrl = `${FIREBASE_URL}${metadataPath}`;
        
        if (authToken) {
            metadataUrl += `?auth=${authToken}`;
        }

        if (adminInitialized && admin) {
            await admin.database().ref(`devices/${deviceId}/metadata`).set(deviceMetadata);
        } else {
            await axios({
                method: 'PUT',
                url: metadataUrl,
                data: deviceMetadata,
                headers: { 'Content-Type': 'application/json' }
            });
        }

        res.json({
            success: true,
            message: 'Device registered successfully',
            deviceId,
            metadata: deviceMetadata
        });
    } catch (error) {
        console.error('Error registering device:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to register device',
            details: error.message
        });
    }
});

// Assign device to user
router.post('/devices/:deviceId/assign', async (req, res) => {
    try {
        const { deviceId } = req.params;
        const { userId, patientId } = req.body;

        if (!userId) {
            return res.status(400).json({
                success: false,
                error: 'userId is required'
            });
        }

        // Update device metadata
        const updates = {
            assignedUserId: userId,
            patientId: patientId || null,
            lastSeen: new Date().toISOString(),
            status: 'active'
        };

        const metadataPath = `/devices/${deviceId}/metadata.json`;
        let metadataUrl = `${FIREBASE_URL}${metadataPath}`;
        
        if (authToken) {
            metadataUrl += `?auth=${authToken}`;
        }

        if (adminInitialized && admin) {
            await admin.database().ref(`devices/${deviceId}/metadata`).update(updates);
        } else {
            await axios({
                method: 'PATCH',
                url: metadataUrl,
                data: updates,
                headers: { 'Content-Type': 'application/json' }
            });
        }

        res.json({
            success: true,
            message: 'Device assigned successfully',
            deviceId,
            userId
        });
    } catch (error) {
        console.error('Error assigning device:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to assign device',
            details: error.message
        });
    }
});

// Get device metadata
router.get('/devices/:deviceId', async (req, res) => {
    try {
        const { deviceId } = req.params;

        const metadataPath = `/devices/${deviceId}/metadata.json`;
        let metadataUrl = `${FIREBASE_URL}${metadataPath}`;
        
        if (authToken) {
            metadataUrl += `?auth=${authToken}`;
        }

        let metadata;
        if (adminInitialized && admin) {
            const snapshot = await admin.database().ref(`devices/${deviceId}/metadata`).once('value');
            metadata = snapshot.val();
        } else {
            const response = await axios.get(metadataUrl);
            metadata = response.data;
        }

        if (!metadata) {
            return res.status(404).json({
                success: false,
                error: 'Device not found'
            });
        }

        res.json({
            success: true,
            device: metadata
        });
    } catch (error) {
        console.error('Error fetching device:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to fetch device',
            details: error.message
        });
    }
});

module.exports = router;

