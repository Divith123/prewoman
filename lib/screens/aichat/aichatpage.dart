import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

/// A sample AIChatPage with improved Markdown display:
/// 1. Uses flutter_markdown for more attractive rendering of Markdown.
/// 2. Stores and loads chat history via [SharedPreferences].
/// 3. Pressing the Enter key sends the message (multi-line entry is not supported).
/// 4. Removes theme toggling for a simpler, consistent design.
class AIChatPage extends StatefulWidget {
  const AIChatPage({Key? key}) : super(key: key);

  @override
  AIChatPageState createState() => AIChatPageState();
}

class AIChatPageState extends State<AIChatPage> with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  GenerativeModel? _model;
  ChatSession? _chatSession;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    final apiKey = Platform.environment['GEMINI_API_KEY'];
    if (apiKey == null) {
      debugPrint('No GEMINI_API_KEY environment variable found');
      return;
    }
    _initializeModel(apiKey).then((_) => _loadChatHistory());
  }

  /// Initialize generative model and create new chat session.
  Future<void> _initializeModel(String apiKey) async {
    _model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 1,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 8192,
        responseMimeType: 'text/plain',
      ),
    );
    _chatSession = _model?.startChat(history: []);
  }

  /// Load persisted chat history from local storage.
  Future<void> _loadChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final storedMessages = prefs.getStringList('chat_history') ?? [];
    for (final msgData in storedMessages) {
      final parts = msgData.split('||');
      if (parts.length == 2) {
        final isUser = parts[0] == 'user';
        final text = parts[1];
        final message = ChatMessage(
          text: text,
          isUser: isUser,
          animationController: AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 300),
          ),
        );
        setState(() {
          _messages.add(message);
        });
        message.animationController.forward();
      }
    }
  }

  /// Save current list of messages to local storage.
  Future<void> _saveChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final messageList = _messages
        .map((msg) => (msg.isUser ? 'user' : 'bot') + '||' + msg.text)
        .toList();
    await prefs.setStringList('chat_history', messageList);
  }

  /// Sends the user message and receives AI response.
  Future<void> _sendMessage() async {
    if (_controller.text.isEmpty || _chatSession == null) return;
    final userMessage = _controller.text.trim();
    _controller.clear();

    final message = ChatMessage(
      text: userMessage,
      isUser: true,
      animationController: AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300),
      ),
    );

    setState(() {
      _messages.add(message);
      _isTyping = true;
    });
    message.animationController.forward();
    _scrollToBottom();
    await _saveChatHistory();

    try {
      final response =
          await _chatSession!.sendMessage(Content.text(userMessage));
      final botMessage = ChatMessage(
        text: response.text ?? 'Error generating response.',
        isUser: false,
        animationController: AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 300),
        ),
      );

      setState(() {
        _messages.add(botMessage);
        _isTyping = false;
      });
      botMessage.animationController.forward();
      _scrollToBottom();
      await _saveChatHistory();
    } catch (e) {
      setState(() => _isTyping = false);
      debugPrint('Error sending message: $e');
    }
  }

  /// Start a new chat session, clearing messages.
  void _startNewChat() {
    setState(() {
      _messages.clear();
      _chatSession = _model?.startChat(history: []);
    });
    _saveChatHistory();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Builds each indiviual chat bubble using Markdown rendering.
  Widget _buildMessageBubble(ChatMessage message) {
    final bubbleColor = message.isUser ? Colors.blue[700] : Colors.grey[300];
    final textColor = message.isUser ? Colors.white : Colors.black;

    return SizeTransition(
      sizeFactor: CurvedAnimation(
        parent: message.animationController,
        curve: Curves.easeOut,
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        child: Row(
          mainAxisAlignment:
              message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!message.isUser) _buildAvatar(message.isUser),
            Flexible(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: MarkdownBody(
                  data: message.text,
                  selectable: true,
                  styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context))
                      .copyWith(
                    p: TextStyle(color: textColor),
                    codeblockDecoration: BoxDecoration(
                      color: message.isUser
                          ? Colors.blue[800]
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    code: TextStyle(
                      color:
                          message.isUser ? Colors.white : Colors.blueGrey[800],
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
            ),
            if (message.isUser) _buildAvatar(message.isUser),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(bool isUser) {
    return Container(
      margin: const EdgeInsets.only(top: 4, left: 6, right: 6),
      child: CircleAvatar(
        radius: 16,
        backgroundColor: isUser ? Colors.blueAccent : Colors.grey[500],
        child: Icon(
          isUser ? Icons.person : Icons.android,
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }

  /// Builds a simple typing indicator.
  Widget _buildTypingIndicator() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [TypingIndicator()],
      ),
    );
  }

  /// Builds the text input area with a send button, and pressing Enter sends.
  Widget _buildInputArea() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(8),
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[300]!),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.add, color: Colors.black),
              tooltip: 'New Chat',
              onPressed: _startNewChat,
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: 'Type your message...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                style: const TextStyle(fontSize: 16),
                maxLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send, color: Colors.black),
              onPressed: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (final msg in _messages) {
      msg.animationController.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  /// Main build with a standard appBar and chat messages list.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Chat', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 2,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(8),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < _messages.length) {
                  return _buildMessageBubble(_messages[index]);
                }
                return _buildTypingIndicator();
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final AnimationController animationController;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.animationController,
  });
}

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({Key? key}) : super(key: key);

  @override
  TypingIndicatorState createState() => TypingIndicatorState();
}

class TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _dotsAnimationController;

  @override
  void initState() {
    super.initState();
    _dotsAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat();
  }

  @override
  void dispose() {
    _dotsAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _dotsAnimationController,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Opacity(
                opacity: _calculateOpacity(index),
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  double _calculateOpacity(int index) {
    final double progress = _dotsAnimationController.value * 2;
    return (progress - index * 0.3).clamp(0.2, 1.0);
  }
}