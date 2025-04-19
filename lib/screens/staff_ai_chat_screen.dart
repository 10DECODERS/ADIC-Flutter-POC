import 'package:flutter/material.dart';
import 'package:adic_poc/services/database_service.dart';
import 'package:adic_poc/models/staff.dart';
import 'package:adic_poc/services/ai_service.dart';
import 'package:adic_poc/models/chat_message.dart';
import 'package:adic_poc/services/api_key_service.dart';
import 'package:adic_poc/screens/api_key_screen.dart';

class StaffAIChatScreen extends StatefulWidget {
  const StaffAIChatScreen({Key? key}) : super(key: key);

  @override
  State<StaffAIChatScreen> createState() => _StaffAIChatScreenState();
}

class _StaffAIChatScreenState extends State<StaffAIChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final DatabaseService _dbService = DatabaseService();
  final AIService _aiService = AIService();
  final ApiKeyService _apiKeyService = ApiKeyService();
  bool _isProcessing = false;
  bool _hasApiKey = false;

  @override
  void initState() {
    super.initState();
    _checkApiKey();
    _addSystemMessage();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _checkApiKey() async {
    final hasKey = await _apiKeyService.hasApiKey();
    setState(() {
      _hasApiKey = hasKey;
    });
  }

  void _addSystemMessage() {
    setState(() {
      _messages.add(
        ChatMessage(
          text: "Hi, I'm your AI assistant for staff management. You can ask me to:\n\n"
               "• Add a new staff member\n"
               "• View staff information\n"
               "• Edit staff details\n"
               "• Search for staff members\n\n"
               "How can I help you today?",
          isUser: false,
        ),
      );
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final userMessage = _messageController.text.trim();
    _messageController.clear();

    setState(() {
      _messages.add(ChatMessage(text: userMessage, isUser: true));
      _isProcessing = true;
    });

    _scrollToBottom();

    try {
      // Process user message with AI service
      final response = await _aiService.processStaffQuery(userMessage, _messages);

      setState(() {
        _messages.add(ChatMessage(text: response.message, isUser: false));
        _isProcessing = false;
      });

      // If AI response contains an action, perform it
      if (response.action != null) {
        await _handleAIAction(response.action!, response.data);
      }
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: "Sorry, I encountered an error. Please try again.",
          isUser: false,
        ));
        _isProcessing = false;
      });
    }

    _scrollToBottom();
  }

  Future<void> _handleAIAction(AIAction action, dynamic data) async {
    switch (action) {
      case AIAction.viewStaff:
        final staffList = await _dbService.getAllStaff();
        setState(() {
          _messages.add(ChatMessage(
            text: "Here are all staff members: \n\n${_formatStaffList(staffList)}",
            isUser: false,
          ));
        });
        break;
      case AIAction.searchStaff:
        final query = data as String;
        final staffList = await _dbService.getAllStaff();
        final filteredList = staffList.where((staff) {
          return staff.name.toLowerCase().contains(query.toLowerCase()) ||
                 staff.position.toLowerCase().contains(query.toLowerCase()) ||
                 staff.department.toLowerCase().contains(query.toLowerCase());
        }).toList();
        
        setState(() {
          if (filteredList.isEmpty) {
            _messages.add(ChatMessage(
              text: "No staff members found matching '$query'.",
              isUser: false,
            ));
          } else {
            _messages.add(ChatMessage(
              text: "Staff members matching '$query': \n\n${_formatStaffList(filteredList)}",
              isUser: false,
            ));
          }
        });
        break;
      case AIAction.addStaff:
        // Navigate to add staff screen with pre-filled data
        final staffData = data as Map<String, dynamic>;
        Navigator.pushNamed(
          context, 
          '/staff/form',
          arguments: {
            'isEditing': false,
            'prefillData': staffData,
          }
        );
        break;
      case AIAction.editStaff:
        // Get the staff data and staff ID from the AI response
        final Map<String, dynamic> updateData = data['updateData'] ?? {};
        final int? staffId = data['staffId'];
        Staff? staffToUpdate;
        
        // First try to get staff by ID if available
        if (staffId != null && staffId > 0) {
          staffToUpdate = await _dbService.getStaffById(staffId);
        }
        
        // If we couldn't find by ID or ID wasn't provided, try by email if available
        if (staffToUpdate == null && updateData.containsKey('email')) {
          staffToUpdate = await _dbService.getStaffByEmail(updateData['email']);
        }
        
        // If still not found, try to identify by name (basic implementation)
        if (staffToUpdate == null && updateData.containsKey('name')) {
          final staffList = await _dbService.getAllStaff();
          for (final staff in staffList) {
            if (staff.name.toLowerCase() == updateData['name'].toString().toLowerCase()) {
              staffToUpdate = staff;
              break;
            }
          }
        }
        
        if (staffToUpdate != null) {
          // Create an updated staff object with the new data
          final updatedStaff = Staff(
            name: updateData['name'] ?? staffToUpdate.name,
            position: updateData['position'] ?? staffToUpdate.position,
            department: updateData['department'] ?? staffToUpdate.department,
            email: updateData['email'] ?? staffToUpdate.email,
            phone: updateData['phone'] ?? staffToUpdate.phone,
            joinDate: staffToUpdate.joinDate,
            syncStatus: staffToUpdate.syncStatus,
            serverId: staffToUpdate.serverId,
          );
          
          // Preserve the ID
          updatedStaff.id = staffToUpdate.id;
          
          // Save to database
          final success = await _dbService.updateStaff(updatedStaff);
          
          setState(() {
            if (success) {
              _messages.add(ChatMessage(
                text: "✅ Staff member updated successfully!",
                isUser: false,
              ));
            } else {
              _messages.add(ChatMessage(
                text: "❌ There was an error updating the staff member.",
                isUser: false,
              ));
            }
          });
        } else {
          setState(() {
            _messages.add(ChatMessage(
              text: "❌ Could not find the staff member to update. Please provide more details like their ID, full name, or email.",
              isUser: false,
            ));
          });
        }
        break;
      default:
        // No action needed
        break;
    }
    
    _scrollToBottom();
  }

  String _formatStaffList(List<Staff> staffList) {
    return staffList.map((staff) => 
      "• ${staff.name} - ${staff.position} (${staff.department})"
    ).join("\n");
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade700,
        title: const Text(
          'AI Assistant',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.key, color: Colors.white),
            tooltip: 'Set API Key',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ApiKeyScreen()),
              );
              _checkApiKey();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (!_hasApiKey)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade300),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange.shade800,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'OpenAI API Key Required',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Set your API key to enable the AI assistant',
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ApiKeyScreen()),
                      );
                      _checkApiKey();
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.orange.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    child: const Text('Set Key'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return Align(
                  alignment: message.isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: message.isUser
                          ? Colors.blue.shade600
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.8,
                    ),
                    child: Text(
                      message.text,
                      style: TextStyle(
                        color: message.isUser ? Colors.white : Colors.black87,
                        fontSize: 15,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isProcessing)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.blue.shade700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "Thinking...",
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade300,
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: Colors.blue.shade600,
                    borderRadius: BorderRadius.circular(24),
                    child: InkWell(
                      onTap: _isProcessing ? null : _sendMessage,
                      borderRadius: BorderRadius.circular(24),
                      child: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Icon(
                          Icons.send,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 