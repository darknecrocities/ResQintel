import 'dart:convert';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;

class GeminiAssistantPage extends StatefulWidget {
  const GeminiAssistantPage({super.key});

  @override
  State<GeminiAssistantPage> createState() => _GeminiAssistantPageState();
}

class _GeminiAssistantPageState extends State<GeminiAssistantPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_Message> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _addSystemMessage(
      "👋 Hello! I'm Arron your virtual assistant for emergencies. Ask anything (e.g., earthquake safety tips).",
    );
  }

  void _addSystemMessage(String text) {
    setState(() {
      _messages.add(_Message(text: text, isUser: false));
    });
  }

  Future<void> _sendMessage(String text) async {
    setState(() {
      _messages.add(_Message(text: text, isUser: true));
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      final response = await http.post(
        Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro:generateContent?key=AIzaSyCh5jyqWZU6VJ9gOGjSnHghpn8P5FgPwp0',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": text},
              ],
            },
          ],
          "safetySettings": [
            {
              "category": "HARM_CATEGORY_HATE_SPEECH",
              "threshold": "BLOCK_NONE",
            },
            {
              "category": "HARM_CATEGORY_SEXUALLY_EXPLICIT",
              "threshold": "BLOCK_NONE",
            },
            {
              "category": "HARM_CATEGORY_DANGEROUS_CONTENT",
              "threshold": "BLOCK_NONE",
            },
            {"category": "HARM_CATEGORY_HARASSMENT", "threshold": "BLOCK_NONE"},
          ],
        }),
      );

      debugPrint("Status Code: ${response.statusCode}");
      debugPrint("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final candidates = data["candidates"];

        if (candidates != null &&
            candidates.isNotEmpty &&
            candidates[0]["content"] != null &&
            candidates[0]["content"]["parts"] != null) {
          final content = candidates[0]["content"]["parts"];
          final aiResponse = content.map((e) => e["text"]).join("\n");

          setState(() {
            _messages.add(_Message(text: aiResponse.trim(), isUser: false));
          });
        } else {
          setState(() {
            _messages.add(
              _Message(text: "⚠️ No valid response.", isUser: false),
            );
          });
        }
      } else {
        setState(() {
          _messages.add(
            _Message(
              text: "⚠️ Error ${response.statusCode}: ${response.reasonPhrase}",
              isUser: false,
            ),
          );
        });
      }
    } catch (e) {
      setState(() {
        _messages.add(
          _Message(text: "❌ Exception occurred: $e", isUser: false),
        );
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final viewInsets = MediaQuery.of(context).viewInsets;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: isDark ? Colors.grey[900] : Colors.red.shade700,
        title: RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  offset: Offset(1, 1),
                  blurRadius: 2,
                  color: Colors.black45,
                ),
              ],
            ),
            children: [
              TextSpan(
                text: '🧠 ',
                style: TextStyle(color: isDark ? Colors.white : Colors.white),
              ),
              TextSpan(
                text: 'ResQintel ',
                style: TextStyle(
                  color: Colors.red.shade300,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 1.2,
                ),
              ),
              TextSpan(
                text: 'AI Assistant',
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isLoading && index == _messages.length) {
                  return const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: _TypingIndicator(),
                    ),
                  );
                }

                final msg = _messages[index];
                return Align(
                  alignment: msg.isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Row(
                    mainAxisAlignment: msg.isUser
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.start,
                    children: [
                      if (!msg.isUser)
                        const CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.red,
                          child: Icon(
                            Icons.smart_toy,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      if (!msg.isUser) const SizedBox(width: 8),
                      Flexible(
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: msg.isUser
                                ? Colors.red.shade100
                                : (isDark
                                      ? Colors.grey.shade800
                                      : Colors.grey.shade200),
                            borderRadius: BorderRadius.only(
                              topLeft: msg.isUser
                                  ? const Radius.circular(16)
                                  : Radius.zero,
                              topRight: msg.isUser
                                  ? Radius.zero
                                  : const Radius.circular(16),
                              bottomLeft: const Radius.circular(16),
                              bottomRight: const Radius.circular(16),
                            ),
                          ),
                          child: MarkdownBody(
                            data: msg.text,
                            styleSheet: MarkdownStyleSheet(
                              p: TextStyle(
                                color: msg.isUser
                                    ? Colors.red.shade800
                                    : (isDark ? Colors.white : Colors.black87),
                                fontSize: 16,
                              ),
                              listBullet: TextStyle(
                                color: msg.isUser
                                    ? Colors.red.shade800
                                    : (isDark ? Colors.white : Colors.black87),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              bottom: viewInsets.bottom > 0 ? viewInsets.bottom : 16,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: isDark ? Colors.grey[900] : Colors.grey.shade100,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 5,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      decoration: InputDecoration(
                        hintText: "How can I help you?",
                        border: InputBorder.none,
                        hintStyle: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.red),
                    onPressed: () {
                      final text = _controller.text.trim();
                      if (text.isNotEmpty) {
                        _controller.clear();
                        _sendMessage(text);
                      }
                    },
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

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 12,
          backgroundColor: Colors.redAccent,
          child: Icon(Icons.smart_toy, size: 14, color: Colors.white),
        ),
        const SizedBox(width: 12),
        DefaultTextStyle(
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black54,
            fontStyle: FontStyle.italic,
          ),
          child: AnimatedTextKit(
            animatedTexts: [
              TyperAnimatedText("Typing...", speed: Duration(milliseconds: 80)),
            ],
            isRepeatingAnimation: true,
            totalRepeatCount: 3,
          ),
        ),
      ],
    );
  }
}

class _Message {
  final String text;
  final bool isUser;

  _Message({required this.text, required this.isUser});
}
