import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:adic_poc/models/chat_message.dart';
import 'package:adic_poc/services/api_key_service.dart';

enum AIAction { viewStaff, searchStaff, addStaff, editStaff, none }

class AIResponse {
  final String message;
  final AIAction? action;
  final dynamic data;

  AIResponse({required this.message, this.action, this.data});
}

class AIService {
  // You would add your own OpenAI API Key in a production app
  // For security purposes, this should be stored securely, not directly in code
  static const String _apiEndpoint =
      'https://api.openai.com/v1/chat/completions';

  // Use ApiKeyService to get the key from secure storage
  final ApiKeyService _apiKeyService = ApiKeyService();

  // Model to use - free tier typically offers access to older models
  String get _model => 'gpt-3.5-turbo';

  Future<AIResponse> processStaffQuery(
    String query,
    List<ChatMessage> history,
  ) async {
    try {
      // Get the API key from secure storage
      final apiKey = await _apiKeyService.getApiKey();

      // Check if API key is available
      if (apiKey == null || apiKey.isEmpty) {
        return AIResponse(
          message:
              "I'm currently offline because no OpenAI API key is set. "
              "Please set your API key in the settings to use this feature.",
          action: null,
        );
      }

      final List<Map<String, dynamic>> messages = [
        {
          'role': 'system',
          'content':
              '''You are an AI assistant that helps manage staff information.
You can help add new staff members, search for existing staff, view staff details, or suggest edits.
When the user asks to perform a specific action, respond with both a natural language reply and a structured action command.
For adding staff, extract name, position, department, email and phone if available.
For searching, identify the search term clearly.''',
        },
      ];

      // Add conversation history (limited to last 10 messages for context)
      final relevantHistory =
          history.length > 10 ? history.sublist(history.length - 10) : history;

      for (final msg in relevantHistory) {
        messages.add({
          'role': msg.isUser ? 'user' : 'assistant',
          'content': msg.text,
        });
      }

      // Add the current query
      messages.add({'role': 'user', 'content': query});

      // In a production app, you would make this API call through a secure backend
      // to avoid exposing your API key in client code
      final response = await http.post(
        Uri.parse(_apiEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': _model,
          'messages': messages,
          'temperature': 0.7,
          'max_tokens': 1000,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String;

        // For demo purposes, we're handling simple actions with basic parsing
        // In a production app, this would be more robust
        return _parseResponse(content);
      } else {
        // Handle errors more gracefully in production
        debugPrint('Error: ${response.statusCode} - ${response.body}');

        // Check for API key issues
        if (response.statusCode == 401) {
          return AIResponse(
            message:
                "Your OpenAI API key appears to be invalid. Please check your API key in settings.",
            action: null,
          );
        }

        // Offline fallback response when API unavailable
        return AIResponse(
          message:
              "I'm currently offline but can help with basic staff management. "
              "For complex tasks, please try again when your internet connection is restored.",
          action: null,
        );
      }
    } catch (e) {
      debugPrint('Exception in AI service: $e');
      return AIResponse(
        message:
            "I encountered a technical issue. Let me try a simpler approach.",
        action: null,
      );
    }
  }

  // Basic response parser - in a real app, this would be more sophisticated
  AIResponse _parseResponse(String content) {
    // Simple parsing method for demo purposes
    final lowerContent = content.toLowerCase();

    // Check for view all staff intent
    if (lowerContent.contains('list all staff') ||
        lowerContent.contains('show all staff') ||
        lowerContent.contains('view all staff')) {
      return AIResponse(message: content, action: AIAction.viewStaff);
    }

    // Check for search intent
    if (lowerContent.contains('search for') ||
        lowerContent.contains('find staff')) {
      // Extract search term (basic implementation)
      final searchTerm = _extractSearchTerm(content);
      if (searchTerm != null) {
        return AIResponse(
          message: content,
          action: AIAction.searchStaff,
          data: searchTerm,
        );
      }
    }

    // Check for add staff intent
    if (lowerContent.contains('add staff') ||
        lowerContent.contains('create staff') ||
        lowerContent.contains('new staff')) {
      // Extract staff information (basic implementation)
      final staffData = _extractStaffData(content);
      if (staffData.isNotEmpty) {
        return AIResponse(
          message: content,
          action: AIAction.addStaff,
          data: staffData,
        );
      }
    }

    // Check for edit intent
    if (lowerContent.contains('edit staff') ||
        lowerContent.contains('update staff') ||
        lowerContent.contains('change staff') ||
        (lowerContent.contains('update') &&
            (lowerContent.contains('phone') ||
                lowerContent.contains('email') ||
                lowerContent.contains('position') ||
                lowerContent.contains('department')))) {
      // Extract staff ID and update data
      final staffId = _extractStaffId(content);
      final updateData = _extractStaffData(content);

      if (staffId != null) {
        return AIResponse(
          message: content,
          action: AIAction.editStaff,
          data: {'staffId': staffId, 'updateData': updateData},
        );
      }

      return AIResponse(
        message:
            content +
            "\n\nI need to know which staff member to update. Could you provide their ID or email?",
        action: null,
      );
    }

    // Default case - just a regular response
    return AIResponse(message: content, action: null);
  }

  String? _extractSearchTerm(String content) {
    // Very basic extraction logic for demo
    final searchPatterns = [
      RegExp(r'search for [""]?([^""]+)[""]?', caseSensitive: false),
      RegExp(r'find staff .*?[""]?([^""]+)[""]?', caseSensitive: false),
      RegExp(r'looking for [""]?([^""]+)[""]?', caseSensitive: false),
    ];

    for (final pattern in searchPatterns) {
      final match = pattern.firstMatch(content.toLowerCase());
      if (match != null && match.groupCount >= 1) {
        return match.group(1)?.trim();
      }
    }

    // Fallback: if we can't extract, use a generic term
    return content
        .replaceAll(
          RegExp(r'(search|find|look).*for', caseSensitive: false),
          '',
        )
        .trim();
  }

  Map<String, dynamic> _extractStaffData(String content) {
    final data = <String, dynamic>{};

    // Extract name
    final nameMatch = RegExp(
      r'name[: ]+(.*?)[\.,]',
      caseSensitive: false,
    ).firstMatch(content);
    if (nameMatch != null) {
      data['name'] = nameMatch.group(1)?.trim();
    }

    // Extract position
    final positionMatch = RegExp(
      r'position[: ]+(.*?)[\.,]',
      caseSensitive: false,
    ).firstMatch(content);
    if (positionMatch != null) {
      data['position'] = positionMatch.group(1)?.trim();
    }

    // Extract department
    final deptMatch = RegExp(
      r'department[: ]+(.*?)[\.,]',
      caseSensitive: false,
    ).firstMatch(content);
    if (deptMatch != null) {
      data['department'] = deptMatch.group(1)?.trim();
    }

    // Extract email
    final emailMatch = RegExp(
      r'email[: ]+(.*?)[\.,]',
      caseSensitive: false,
    ).firstMatch(content);
    if (emailMatch != null) {
      data['email'] = emailMatch.group(1)?.trim();
    } else {
      // Alternative email extraction (looser pattern)
      final altEmailMatch = RegExp(
        r'(\S+@\S+\.\S+)',
        caseSensitive: false,
      ).firstMatch(content);
      if (altEmailMatch != null) {
        data['email'] = altEmailMatch.group(1)?.trim();
      }
    }

    // Extract phone
    final phoneMatch = RegExp(
      r'phone[: ]+(.*?)[\.,]',
      caseSensitive: false,
    ).firstMatch(content);
    if (phoneMatch != null) {
      data['phone'] = phoneMatch.group(1)?.trim();
    } else {
      // Alternative phone extraction (common formats)
      final altPhoneMatch = RegExp(
        r'(\+?\d{1,3}[ -]?\(?\d{3}\)?[ -]?\d{3}[ -]?\d{4})',
        caseSensitive: false,
      ).firstMatch(content);
      if (altPhoneMatch != null) {
        data['phone'] = altPhoneMatch.group(1)?.trim();
      } else {
        // Check for "change X's phone to Y" pattern
        final updatePhoneMatch = RegExp(
          r'(?:change|update|set).*?phone.*?to[: ]+([0-9+ -]{7,})',
          caseSensitive: false,
        ).firstMatch(content);
        if (updatePhoneMatch != null) {
          data['phone'] = updatePhoneMatch.group(1)?.trim();
        }
      }
    }

    // Look for specific update patterns
    final updatePatterns = [
      RegExp(
        r'update (?:the )?(.*?) to (?:have |be )?(.*?)[\.,]',
        caseSensitive: false,
      ),
      RegExp(
        r'change (?:the )?(.*?) to (?:have |be )?(.*?)[\.,]',
        caseSensitive: false,
      ),
      RegExp(
        r'set (?:the )?(.*?) to (?:have |be )?(.*?)[\.,]',
        caseSensitive: false,
      ),
    ];

    for (final pattern in updatePatterns) {
      final matches = pattern.allMatches(content);
      for (final match in matches) {
        if (match.groupCount >= 2) {
          final field = match.group(1)?.trim().toLowerCase();
          final value = match.group(2)?.trim();

          if (field != null && value != null) {
            if (field.contains('phone') ||
                field == 'phone number' ||
                field == 'mobile' ||
                field == 'cell') {
              data['phone'] = value;
            } else if (field.contains('email') ||
                field == 'mail' ||
                field == 'e-mail') {
              data['email'] = value;
            } else if (field.contains('position') ||
                field == 'role' ||
                field == 'job' ||
                field == 'title') {
              data['position'] = value;
            } else if (field.contains('department') ||
                field == 'dept' ||
                field == 'team') {
              data['department'] = value;
            } else if (field.contains('name')) {
              data['name'] = value;
            }
          }
        }
      }
    }

    return data;
  }

  // Add this new method to extract staff ID
  int? _extractStaffId(String content) {
    // Try to extract a numeric ID
    final idMatch = RegExp(
      r'staff (id|ID|Id)? ?[#:]? ?(\d+)',
      caseSensitive: false,
    ).firstMatch(content);
    if (idMatch != null && idMatch.groupCount >= 2) {
      return int.tryParse(idMatch.group(2)!);
    }

    // Try to extract by staff name pattern
    final namePattern = RegExp(
      r'(?:update|change|edit|modify) (.*?) (?:phone|email|position|department)',
      caseSensitive: false,
    );
    final nameMatch = namePattern.firstMatch(content);
    if (nameMatch != null && nameMatch.groupCount >= 1) {
      final staffName = nameMatch.group(1)?.trim();
      // Note: We can't directly get ID by name here, but we could
      // implement a method to lookup by name and return the ID
      // This would require database access in the AI service
      // For now, we'll rely on client code to handle this
      return null;
    }

    return null;
  }
}
