import 'package:flutter/material.dart';
import '../main.dart';
import '../services/ai_service.dart';

class VideoPostScreen extends StatefulWidget {
  static const routeName = '/video-post';
  const VideoPostScreen({super.key});

  @override
  State<VideoPostScreen> createState() => _VideoPostScreenState();
}

class _VideoPostScreenState extends State<VideoPostScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _isAiWorking = false;
  String _captionSuggestion = '';
  String _hashtagSuggestion = '';

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _generateCaption() async {
    setState(() {
      _isAiWorking = true;
      _captionSuggestion = '';
    });

    final prompt = _descriptionController.text.isNotEmpty
        ? _descriptionController.text
        : 'Create a short NEX-Reels caption.';
    final caption = await AIService.instance.generateCaption(prompt);

    setState(() {
      _captionSuggestion = caption;
      _isAiWorking = false;
    });
  }

  Future<void> _suggestHashtags() async {
    setState(() {
      _isAiWorking = true;
      _hashtagSuggestion = '';
    });

    final prompt = _titleController.text.isNotEmpty
        ? _titleController.text
        : 'Generate trending reel hashtags for NEX-Reels.';
    final hashtags = await AIService.instance.suggestHashtags(prompt);

    setState(() {
      _hashtagSuggestion = hashtags;
      _isAiWorking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkBackground,
      appBar: AppBar(
        title: const Text('NEX-Reels Post', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: kSurfaceColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Video Title',
                labelStyle: TextStyle(color: Colors.white70),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TextField(
                controller: _descriptionController,
                maxLines: null,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Description / Scene',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isAiWorking ? null : _generateCaption,
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('AI Caption'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kNeonBlue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isAiWorking ? null : _suggestHashtags,
                    icon: const Icon(Icons.tag),
                    label: const Text('AI Hashtags'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kNeonGreen,
                      foregroundColor: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isAiWorking)
              const LinearProgressIndicator(color: kNeonBlue)
            else ...[
              if (_captionSuggestion.isNotEmpty) ...[
                _SuggestionCard(
                  title: 'Suggested Caption',
                  content: _captionSuggestion,
                ),
                const SizedBox(height: 12),
              ],
              if (_hashtagSuggestion.isNotEmpty) ...[
                _SuggestionCard(
                  title: 'Suggested Hashtags',
                  content: _hashtagSuggestion,
                ),
              ],
            ],
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.check),
              label: const Text('Save Draft'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryGreen,
                foregroundColor: Colors.black,
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  final String title;
  final String content;

  const _SuggestionCard({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111B25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kNeonBlue.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: kNeonGreen, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}
