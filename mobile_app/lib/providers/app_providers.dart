import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import '../services/baseline_service.dart';
import '../services/notification_service.dart';

class AppProviders {
  static List<SingleChildWidget> providers = [
    Provider(create: (_) => AuthService()),
    Provider(create: (_) => FirebaseService()),
    Provider(create: (_) => BaselineService()),
    Provider(create: (_) => NotificationService()),
  ];
}

