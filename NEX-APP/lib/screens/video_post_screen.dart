import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../services/ai_service.dart';

class VideoPostScreen extends StatefulWidget {
  static const routeName = '/video-post';
  const VideoPostScreen({super.key});

  @override
  State<VideoPostScreen> createState() => _VideoPostScreenState();
}

class _VideoPostScreenState extends State<VideoPostScreen> with TickerProviderStateMixin {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _hashtagsController = TextEditingController();
  bool _isAiWorking = false;
  String _captionSuggestion = '';
  String _hashtagSuggestion = '';
  String _selectedEffect = 'none';
  bool _allowComments = true;
  bool _allowDuets = true;
  bool _allowStitches = true;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _hashtagsController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _generateCaption() async {
    setState(() {
      _isAiWorking = true;
      _captionSuggestion = '';
    });

    final prompt = _descriptionController.text.isNotEmpty
        ? _descriptionController.text
        : 'Create a short NEX-Reels caption that goes viral.';

    // FIX: Check mounted before using AI service/context
    final caption = await AIService.instance.generateCaption(prompt);

    if (!mounted) return;
    setState(() {
      _captionSuggestion = caption;
      _isAiWorking = false;
    });
    _animController.forward(from: 0);
  }

  Future<void> _suggestHashtags() async {
    setState(() {
      _isAiWorking = true;
      _hashtagSuggestion = '';
    });

    final prompt = _titleController.text.isNotEmpty
        ? _titleController.text
        : 'Generate trending hashtags for NEX-Reels.';
    final hashtags = await AIService.instance.suggestHashtags(prompt);

    if (!mounted) return;
    setState(() {
      _hashtagSuggestion = hashtags;
      _isAiWorking = false;
    });
    _animController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color(0xFF070B14), // Deep Navy background
        appBar: AppBar(
          elevation: 0,
          backgroundColor: const Color(0xFF0A111F),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: kNeonPurple, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
              'REEL_STUDIO',
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 16)
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
          // NEX_PREVIEW_AREA
          Container(
          margin: const EdgeInsets.all(20),
          height: 240,
          decoration: BoxDecoration(
            color: const Color(0xFF0D1E36).withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: kNeonPurple.withValues(alpha: 0.2), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: kNeonPurple.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.video_library_rounded, size: 50, color: kNeonPurple.withValues(alpha: 0.4)),
                      const SizedBox(height: 16),
                      const Text(
                        'TRANSMIT_MEDIA',
                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Supported: MP4, MOV (Max 60s)',
                        style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.6)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Row(
                      children: [
                        _buildMediaButton(Icons.videocam_rounded, 'CAMERA', kNeonBlue, () {}),
                        const SizedBox(width: 12),
                        _buildMediaButton(Icons.collections_rounded, 'GALLERY', kNeonGreen, () {}),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // SYSTEM_INPUT_IDENTITY
        _buildInputHeader('CONTENT_IDENTITY'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _buildStudioTextField(
            controller: _titleController,
            hint: 'Node title for NEX-Reel...',
            icon: Icons.subtitles_rounded,
            color: kNeonPurple,
          ),
        ),
        const SizedBox(height: 16),

        // DESCRIPTION_BLOCK
        _buildInputHeader('CONTENT_DESCRIPTION'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _buildStudioTextField(
            controller: _descriptionController,
            hint: 'Describe your data node payload...',
            icon: Icons.description_rounded,
            color: kNeonGreen,
            maxLines: 4,
            maxLength: 500,
          ),
        ),
        const SizedBox(height: 16),

              // HASHTAG_BLOCK
              _buildInputHeader('METADATA_TAGS'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildStudioTextField(
                  controller: _hashtagsController,
                  hint: '#TRENDING #NEX_REEL #ALGO',
                  icon: Icons.tag_rounded,
                  color: kNeonBlue,
                  maxLength: 30,
                ),
              ),
              const SizedBox(height: 24),

              // AI_CORE_ASSISTANT_PANEL
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1E36).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: kNeonBlue.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: kNeonBlue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.psychology_rounded, color: kNeonBlue, size: 18),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                              'NEURAL_ASSIST_v1',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.5)
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _buildAIActionButton(
                              onPressed: _isAiWorking ? null : _generateCaption,
                              icon: Icons.auto_awesome_rounded,
                              label: 'GENERATE_CAPTION',
                              color: kNeonBlue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildAIActionButton(
                              onPressed: _isAiWorking ? null : _suggestHashtags,
                              icon: Icons.analytics_rounded,
                              label: 'SUGGEST_TAGS',
                              color: kNeonGreen,
                              darkText: true,
                            ),
                          ),
                        ],
                      ),
                      if (_isAiWorking) ...[
                        const SizedBox(height: 20),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            backgroundColor: Colors.white.withValues(alpha: 0.05),
                            color: kNeonBlue,
                            minHeight: 2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Center(
                          child: Text(
                              'SYNCHRONIZING_AI_MODEL...',
                              style: TextStyle(color: Colors.white24, fontSize: 8, fontWeight: FontWeight.bold)
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // AI_SUGGESTION_NODES
              if (_captionSuggestion.isNotEmpty)
            _buildSuggestionNode('CAPTION_PROPOSAL', _captionSuggestion, () {
          _descriptionController.text = _captionSuggestion;
        }),
                if (_hashtagSuggestion.isNotEmpty)
                  _buildSuggestionNode('METADATA_SUGGESTION', _hashtagSuggestion, () {
                    _hashtagsController.text = _hashtagSuggestion;
                  }),

                // CREATIVE_EFFECTS_PROTOCOL
                _buildInputHeader('VISUAL_FILTERS'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D1E36).withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['none', 'quantum', 'neon', 'cold', 'thermal'].map((effect) {
                          final bool isSelected = _selectedEffect == effect;
                          return Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: ChoiceChip(
                              showCheckmark: false,
                              label: Text(effect.toUpperCase()),
                              selected: isSelected,
                              onSelected: (selected) => setState(() => _selectedEffect = effect),
                              selectedColor: kNeonPurple,
                              backgroundColor: Colors.white.withValues(alpha: 0.05),
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : Colors.white38,
                                fontWeight: FontWeight.w900,
                                fontSize: 10,
                                letterSpacing: 1,
                              ),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              side: BorderSide(color: isSelected ? kNeonPurple : Colors.white10),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // PRIVACY_PERMISSIONS_GRID
                _buildInputHeader('TRANSMISSION_SETTINGS'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D1E36).withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                    ),
                    child: Column(
                      children: [
                        _buildPrivacyToggle('ENABLE_COMMENTS', _allowComments, (val) => setState(() => _allowComments = val)),
                        _buildPrivacyToggle('ENABLE_DUETS', _allowDuets, (val) => setState(() => _allowDuets = val)),
                        _buildPrivacyToggle('ALLOW_STITCHING', _allowStitches, (val) => setState(() => _allowStitches = val)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // FINAL_TRANSMIT_ACTIONS
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      _buildPrimaryActionButton(
                        label: 'TRANSMIT TO NEX_REELS',
                        icon: Icons.broadcast_on_personal_rounded,
                        color: kNeonPurple,
                        onPressed: () {},
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildSecondaryActionButton(
                              label: 'SAVE_DRAFT',
                              icon: Icons.save_as_rounded,
                              color: kNeonGreen,
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSecondaryActionButton(
                              label: 'ABORT',
                              icon: Icons.close_rounded,
                              color: Colors.redAccent,
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
              ],
          ),
        ),
    );
  }

  // --- Pro Studio UI Helpers ---

  Widget _buildInputHeader(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      child: Text(
        label,
        style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2),
      ),
    );
  }

  Widget _buildPrivacyToggle(String label, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: kNeonPurple,
              activeTrackColor: kNeonPurple.withValues(alpha: 0.2),
              inactiveThumbColor: Colors.white24,
              inactiveTrackColor: Colors.white.withValues(alpha: 0.05),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryActionButton({required String label, required IconData icon, required Color color, required VoidCallback onPressed}) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20, color: Colors.black),
        label: Text(label, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 13)),
        style: ElevatedButton.styleFrom(backgroundColor: color, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
      ),
    );
  }

  Widget _buildSecondaryActionButton({required String label, required IconData icon, required Color color, required VoidCallback onPressed}) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1)),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.4), width: 1.5),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildSuggestionNode(String title, String content, VoidCallback onUse) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kNeonBlue.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kNeonBlue.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: kNeonBlue, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
            const SizedBox(height: 8),
            Text(content, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4)),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: onUse,
              child: const Text('APPLY_DATA', style: TextStyle(color: kNeonBlue, fontSize: 10, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
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
  final VoidCallback onUse;

  const _SuggestionCard({
    required this.title,
    required this.content,
    required this.onUse,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kNeonBlue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kNeonBlue.withValues(alpha: 0.2), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.psychology_rounded, color: kNeonBlue, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    title.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: onUse,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: kNeonBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: kNeonBlue.withValues(alpha: 0.3)),
                  ),
                  child: const Text(
                    'APPLY_NODE',
                    style: TextStyle(
                      color: kNeonBlue,
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            content,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// --- MISSING HELPERS TO ENSURE COMPILATION ---

extension _VideoPostHelpers on _VideoPostScreenState {
  Widget _buildMediaButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return Expanded(
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18, color: color == kNeonGreen ? Colors.black : Colors.white),
        label: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 11,
            letterSpacing: 1,
            color: color == kNeonGreen ? Colors.black : Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withValues(alpha: 0.9),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildStudioTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Color color,
    int maxLines = 1,
    int? maxLength,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1E36).withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        maxLength: maxLength,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white12),
          prefixIcon: Icon(icon, color: color, size: 20),
          counterStyle: const TextStyle(color: Colors.white24, fontSize: 10),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildAIActionButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required Color color,
    bool darkText = false,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 10,
          letterSpacing: 0.5,
          color: darkText ? Colors.black : Colors.white,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: darkText ? Colors.black : Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        shadowColor: color.withValues(alpha: 0.3),
      ),
    );
  }
}

