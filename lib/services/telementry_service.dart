import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class TelemetryService {
  static final TelemetryService _instance = TelemetryService._internal();
  factory TelemetryService() => _instance;

  TelemetryService._internal();

  static const String _instrumentationKey = '_INSTRUMENTATION_KEY';
  static const String _endpoint = 'https://dc.services.visualstudio.com/v2/track';

  Future<void> logEvent(String eventName, {Map<String, String>? properties}) async {
    await _sendTelemetry(
      name: "Microsoft.ApplicationInsights.Event",
      baseType: "EventData",
      baseData: {
        "ver": 2,
        "name": eventName,
        "properties": properties ?? {},
      },
    );
  }

  Future<void> logError(String errorMessage, StackTrace? stackTrace, {Map<String, String>? properties}) async {
    final combinedProps = {
      "error": errorMessage,
      if (stackTrace != null) "stackTrace": stackTrace.toString(),
      ...?properties,
    };

    await _sendTelemetry(
      name: "Microsoft.ApplicationInsights.Exception",
      baseType: "ExceptionData",
      baseData: {
        "ver": 2,
        "exceptions": [
          {
            "typeName": "FlutterError",
            "message": errorMessage,
            "hasFullStack": true,
            "stack": stackTrace?.toString() ?? '',
          }
        ],
        "properties": combinedProps,
      },
    );
  }

  Future<void> logTrace(String message, {Map<String, String>? properties}) async {
    await _sendTelemetry(
      name: "Microsoft.ApplicationInsights.Message",
      baseType: "MessageData",
      baseData: {
        "ver": 2,
        "message": message,
        "severityLevel": 1,
        "properties": properties ?? {},
      },
    );
  }

  Future<void> _sendTelemetry({
    required String name,
    required String baseType,
    required Map<String, dynamic> baseData,
  }) async {
    try {
      final payload = {
        "name": name,
        "time": DateTime.now().toUtc().toIso8601String(),
        "iKey": _instrumentationKey,
        "data": {
          "baseType": baseType,
          "baseData": baseData,
        }
      };

      await http.post(
        Uri.parse(_endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
    } catch (e) {
      if (kDebugMode) {
        print("Telemetry send failed: $e");
      }
    }
  }
}
