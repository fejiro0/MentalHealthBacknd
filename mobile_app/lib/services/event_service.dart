import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';

class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Save event to Firestore
  Future<void> saveEvent(EventModel event) async {
    try {
      await _firestore
          .collection('events')
          .doc(event.id)
          .set(event.toJson());
    } catch (e) {
      throw 'Error saving event: ${e.toString()}';
    }
  }

  // Get events for a user
  Stream<List<EventModel>> getEvents(String userId, {int limit = 50}) {
    return _firestore
        .collection('events')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EventModel.fromFirestore(doc))
            .toList());
  }

  // Delete an event
  Future<void> deleteEvent(String eventId) async {
    try {
      await _firestore.collection('events').doc(eventId).delete();
    } catch (e) {
      throw 'Error deleting event: ${e.toString()}';
    }
  }

  // Create event ID
  String generateEventId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}

