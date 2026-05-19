import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';
import '../services/status_service.dart';
import 'status_viewer_screen.dart';

class MyStatusesScreen extends StatefulWidget {
  static const routeName = '/my-statuses';
  const MyStatusesScreen({super.key});

  @override
  State<MyStatusesScreen> createState() => _MyStatusesScreenState();
}

class _MyStatusesScreenState extends State<MyStatusesScreen> {
  final StatusService _statusService = StatusService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF0A111F),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: kNeonPurple, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'MY_BROADCASTS',
          style: TextStyle(
              fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 16),
        ),
        actions: [
          IconButton(
            onPressed: () => _showAddStatusDialog(context),
            icon: const Icon(Icons.add_box_rounded, color: kNeonPurple),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _statusService.getMyStatuses(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(
                    color: kNeonPurple, strokeWidth: 2));
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('DATA_LINK_FAILURE',
                  style: TextStyle(
                      color: Colors.redAccent, fontWeight: FontWeight.bold)),
            );
          }

          final statuses = snapshot.data?.docs ?? [];
          if (statuses.isEmpty) return _buildEmptyState();

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: statuses.length,
            itemBuilder: (context, index) {
              final statusDoc = statuses[index];
              final statusData = statusDoc.data() as Map<String, dynamic>;
              final statusId = statusDoc.id;
              final text = statusData['text'] as String?;
              final mediaType =
                  (statusData['mediaType'] as String? ?? 'text').toUpperCase();
              final createdAt = statusData['createdAt'] as Timestamp?;
              final views = statusData['views'] as int? ?? 0;
              final timeText = createdAt != null
                  ? _formatTime(createdAt.toDate())
                  : 'INITIALIZING...';

              return Dismissible(
                key: Key(statusId),
                direction: DismissDirection.endToStart,
                background: Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 24),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.delete_sweep_rounded,
                      color: Colors.redAccent),
                ),
                confirmDismiss: (direction) => _confirmDelete(),
                onDismissed: (direction) => _deleteStatus(statusId),
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1E36).withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: kNeonPurple.withValues(alpha: 0.2)),
                    boxShadow: [
                      BoxShadow(
                          color: kNeonPurple.withValues(alpha: 0.05),
                          blurRadius: 10),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status Header
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          color: kNeonPurple.withValues(alpha: 0.05),
                          child: Row(
                            children: [
                              _getMediaTypeIcon(mediaType.toLowerCase()),
                              const SizedBox(width: 10),
                              Text(
                                mediaType,
                                style: const TextStyle(
                                    color: kNeonPurple,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1),
                              ),
                              const Spacer(),
                              Text(
                                timeText.toUpperCase(),
                                style: const TextStyle(
                                    color: Colors.white24,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        // Status Content
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            text ?? 'NO_DATA_LOGGED',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                height: 1.5,
                                fontWeight: FontWeight.w500),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Status Analytics Bar
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          child: Row(
                            children: [
                              _buildStatItem(
                                  Icons.visibility_outlined, '$views VIEWS'),
                              const SizedBox(width: 16),
                              _buildReactionCounter(statusId),
                              const Spacer(),
                              _buildActionButton(
                                  Icons.remove_red_eye_outlined,
                                  kNeonPurple,
                                  () => _viewStatus(statusId, statusData)),
                              const SizedBox(width: 12),
                              _buildActionButton(
                                  Icons.edit_note_rounded,
                                  kNeonGreen,
                                  () => _editStatus(statusId, statusData)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // --- Pro UI Helpers ---

  Widget _buildStatItem(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.white24),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(
                color: Colors.white24,
                fontSize: 10,
                fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  Widget _getMediaTypeIcon(String type) {
    IconData icon = type == 'image'
        ? Icons.image_rounded
        : type == 'video'
            ? Icons.videocam_rounded
            : Icons.terminal_rounded;
    return Icon(icon, size: 16, color: kNeonPurple);
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: kNeonPurple.withValues(alpha: 0.05),
                shape: BoxShape.circle,
                border: Border.all(color: kNeonPurple.withValues(alpha: 0.1)),
              ),
              child: Icon(Icons.satellite_alt_rounded,
                  size: 40, color: kNeonPurple.withValues(alpha: 0.3)),
            ),
            const SizedBox(height: 32),
            const Text(
              'NO_BROADCAST_HISTORY',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2),
            ),
            const SizedBox(height: 12),
            const Text(
              'Your status log is empty. Transmit your first data packet to the NEX network.',
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: Colors.white38, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => _showAddStatusDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: kNeonPurple,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 10,
              ),
              child: const Text('INITIATE_BROADCAST',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1)),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddStatusDialog(BuildContext context) {
    final statusController = TextEditingController();
    String selectedType = 'text';
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    _showSystemDialog(
      context,
      title: 'NEW_BROADCAST',
      child: _buildStatusForm(
          statusController, selectedType, (val) => selectedType = val),
      onConfirm: () async {
        if (statusController.text.trim().isNotEmpty) {
          try {
            await _statusService.postStatus(
                text: statusController.text.trim(), mediaType: selectedType);
            if (!mounted) return;
            navigator.pop();
            messenger.showSnackBar(
              SnackBar(
                content: const Text('BROADCAST_LIVE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
                backgroundColor: kNeonPurple,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            );
          } catch (e) {
            if (!mounted) return;
            messenger.showSnackBar(
              SnackBar(
                content: const Text('TRANSMISSION_ERROR', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
                backgroundColor: Colors.redAccent,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            );
          }
        }
      },
    );
  }

  void _editStatus(String statusId, Map<String, dynamic> statusData) {
    final statusController =
        TextEditingController(text: statusData['text'] as String? ?? '');
    String selectedType = statusData['mediaType'] as String? ?? 'text';

    _showSystemDialog(
      context,
      title: 'EDIT_TRANSMISSION',
      confirmLabel: 'UPDATE',
      child: _buildStatusForm(
          statusController, selectedType, (val) => selectedType = val),
      onConfirm: () async {
        if (statusController.text.trim().isNotEmpty) {
          final navigator = Navigator.of(context);
          final messenger = ScaffoldMessenger.of(context);
          try {
            await _statusService.updateStatus(statusId,
                text: statusController.text.trim(), mediaType: selectedType);
            if (!mounted) return;
            navigator.pop();
            messenger.showSnackBar(
              SnackBar(
                content: const Text('DATA_MODIFIED', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
                backgroundColor: kNeonPurple,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            );
          } catch (e) {
            if (!mounted) return;
            messenger.showSnackBar(
              SnackBar(
                content: const Text('REWRITE_FAILED', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
                backgroundColor: Colors.redAccent,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            );
          }
        }
      },
    );
  }

  void _viewStatus(String statusId, Map<String, dynamic> statusData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StatusViewerScreen(statusId: statusId, statusData: statusData),
      ),
    );
  }

  // --- Pro System UI Helpers ---

  void _showSystemDialog(BuildContext context,
      {required String title,
      required Widget child,
      required VoidCallback onConfirm,
      String confirmLabel = 'POST'}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0D1E36),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Colors.white10)),
        title: Text(title,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 14,
                letterSpacing: 1)),
        content: child,
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  const Text('ABORT', style: TextStyle(color: Colors.white24))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kNeonPurple),
            onPressed: onConfirm,
            child: Text(confirmLabel,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusForm(TextEditingController controller, String type,
      Function(String) onTypeChange) {
    return StatefulBuilder(
      builder: (context, setDialogState) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: controller,
            maxLines: 3,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Input data sequence...',
              hintStyle: const TextStyle(color: Colors.white24),
              filled: true,
              fillColor: const Color(0xFF070B14),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          _buildTypeSelector(type, (val) {
            onTypeChange(val);
            setDialogState(() {});
          }),
        ],
      ),
    );
  }

  Widget _buildTypeSelector(String current, Function(String) onSelect) {
    final types = ['text', 'image', 'video'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: types.map((t) {
        final isSelected = current == t;
        return GestureDetector(
          onTap: () => onSelect(t),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? kNeonPurple.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: isSelected ? kNeonPurple : Colors.white10),
            ),
            child: Text(t.toUpperCase(),
                style: TextStyle(
                    color: isSelected ? kNeonPurple : Colors.white24,
                    fontSize: 10,
                    fontWeight: FontWeight.bold)),
          ),
        );
      }).toList(),
    );
  }
  // --- FINAL UTILITIES FOR MY_STATUSES ---

  void _deleteStatus(String statusId) async {
    try {
      await _statusService.deleteStatus(statusId);
      if (!mounted) return;
      _showSystemSnackBar(context, 'DATA_PURGED', isError: true);
    } catch (e) {
      if (!mounted) return;
      _showSystemSnackBar(context, 'PURGE_FAILED: $e', isError: true);
    }
  }

  Future<bool?> _confirmDelete() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0D1E36),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.white10),
        ),
        title: const Text('PURGE_CONFIRMATION',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 14,
                letterSpacing: 1)),
        content: const Text(
            'This will permanently delete this status update from the NEX network.',
            style: TextStyle(color: Colors.white54, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ABORT',
                style: TextStyle(
                    color: Colors.white24, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('PURGE',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
    if (diff.inDays == 1) {
      return 'YESTERDAY';
    }
    return '${date.day}/${date.month}/${date.year}';
  }

  // Reactive Stream for Status Reactions
  Widget _buildReactionCounter(String statusId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _statusService.getStatusReactions(statusId),
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;
        return _buildStatItem(
            Icons.favorite_border_rounded, '$count REACTIONS');
      },
    );
  }

  void _showSystemSnackBar(BuildContext context, String message,
      {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: const TextStyle(
                fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
        backgroundColor: isError ? Colors.redAccent : kNeonPurple,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
} // Final closure of _MyStatusesScreenState
