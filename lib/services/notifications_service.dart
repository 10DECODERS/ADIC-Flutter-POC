import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NotificationService {
  static const String hubName = 'adicpoc-hub';
  static const String connectionString = 'Endpoint=sb://adicpoc.servicebus.windows.net/;SharedAccessKeyName=DefaultListenSharedAccessSignature;SharedAccessKey=QYpbk6RhwCMX650V8zcaV/khHatKUp/ttukzOL/PfhE='; // Listen connection string

  Future<void> registerDevice() async {
    try {
      // Firebase initialize pannu
      await Firebase.initializeApp();

      // FCM token edu
      String? token = await FirebaseMessaging.instance.getToken();
      if (token == null) {
        print('FCM token kedaikala');
        return;
      }

      // Azure Notification Hub-la register pannu
      final url = 'https://MyAppNamespace.servicebus.windows.net/$hubName/installations/$token?api-version=2015-01';
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': _generateSasToken(connectionString, url),
        'x-ms-version': '2015-01',
      };
      final body = jsonEncode({
        'installationId': token,
        'platform': 'fcmv1',
        'pushChannel': token,
        'tags': ['all_users'], // Optional: targeting-uku tags
      });

      final response = await http.put(Uri.parse(url), headers: headers, body: body);
      if (response.statusCode == 200) {
        print('Device Azure-la register aayiduchu');
      } else {
        print('Registration fail: ${response.body}');
      }
    } catch (e) {
      print('Error registering device: $e');
    }
  }

  // SAS token generate pannu (temporary, backend use pannu for safety)
  String _generateSasToken(String connectionString, String url) {
    return 'your-sas-token'; // Actual SAS token kodu
  }
}