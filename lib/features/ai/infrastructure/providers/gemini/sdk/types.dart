class GeminiChatPayload {
  final String prompt;
  final String model;
  final String? systemPrompt;

  GeminiChatPayload({
    required this.prompt,
    required this.model,
    this.systemPrompt,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> body = {
      "contents": [
        {
          "parts": [
            {"text": prompt}
          ]
        }
      ]
    };

    if (systemPrompt != null && systemPrompt!.isNotEmpty) {
      body["systemInstruction"] = {
        "parts": [
          {"text": systemPrompt}
        ]
      };
    }

    return body;
  }
}

class GeminiChatResponse {
  final String text;

  GeminiChatResponse({required this.text});

  factory GeminiChatResponse.fromJson(Map<String, dynamic> json) {
    final text = json['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';
    return GeminiChatResponse(text: text);
  }
}
