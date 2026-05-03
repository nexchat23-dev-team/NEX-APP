import 'dart:async';

/// Compile-time environment values for future AI integration.
/// Use flutter build or flutter run with --dart-define flags:
///   --dart-define=NEX_AI_MODEL=your-model-name
///   --dart-define=NEX_AI_API_KEY=your-api-key
const String kNexAiModel = String.fromEnvironment('NEX_AI_MODEL', defaultValue: 'local-nex-reels-model');
const String kNexAiApiKey = String.fromEnvironment('NEX_AI_API_KEY', defaultValue: '');

class AIService {
  AIService._();
  static final AIService instance = AIService._();

  String get modelName => kNexAiModel;
  bool get hasApiKey => kNexAiApiKey.isNotEmpty;

  Future<String> generateCaption(String prompt) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return 'NEX AI caption for "$prompt": Keep it sharp, catchy, and community-ready.';
  }

  Future<String> suggestHashtags(String prompt) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return '#NEXReels #MadeOnNEX #AIStory #FlutterVibes';
  }

  Future<String> explainReelStyle(String prompt) async {
    await Future.delayed(const Duration(milliseconds: 700));
    return 'Use fast cuts, trending music, and bold visuals. NEX-Reels helps creators share bite-sized videos with AI-powered caption and hashtag suggestions.';
  }

  Future<String> getIntegrationStatus() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return hasApiKey
        ? 'AI environment ready. Model: $modelName'
        : 'AI environment placeholder active. Add NEX_AI_API_KEY with --dart-define when ready.';
  }
}
