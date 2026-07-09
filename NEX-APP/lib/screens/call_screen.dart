import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../services/call_service.dart';
import '../services/permissions_service.dart';
import '../utils/constants.dart';

class CallScreen extends StatefulWidget {
  const CallScreen({
    super.key,
    required this.receiverId,
    required this.receiverName,
    required this.isVideo,
  });

  final String receiverId;
  final String receiverName;
  final bool isVideo;

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final CallService _callService = CallService();
  final PermissionsService _permissionsService = PermissionsService();
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  String? _callId;
  bool _isPreparing = true;
  bool _isMuted = false;
  bool _isVideoEnabled = true;
  bool _isEnding = false;
  String _statusText = 'Preparing your call...';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeCall());
  }

  @override
  void dispose() {
    _stopMedia();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    _peerConnection?.close();
    super.dispose();
  }

  Future<void> _initializeCall() async {
    try {
      await _localRenderer.initialize();
      await _remoteRenderer.initialize();

      final micGranted = await _permissionsService.requestMicrophonePermission();
      final cameraGranted = widget.isVideo ? await _permissionsService.requestCameraPermission() : true;

      if (!mounted) return;

      if (!micGranted || (widget.isVideo && !cameraGranted)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Microphone and camera permissions are required for calls.')));
        if (mounted) Navigator.pop(context);
        return;
      }

      await _startLocalMedia();
      await _createActiveCall();

      if (!mounted) return;

      setState(() => _isPreparing = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isPreparing = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Unable to start call: $e')));
      Navigator.pop(context);
    }
  }

  Future<void> _startLocalMedia() async {
    final constraints = <String, dynamic>{
      'audio': true,
      'video': widget.isVideo ? {'facingMode': 'user'} : false,
    };

    _localStream = await Helper.openCamera(constraints);
    _localRenderer.srcObject = _localStream;

    _peerConnection = await _createPeerConnection();

    for (final track in _localStream!.getTracks()) {
      await _peerConnection!.addTrack(track, _localStream!);
    }

    if (mounted) setState(() {});
  }

  Future<RTCPeerConnection> _createPeerConnection() async {
    final config = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
      'sdpSemantics': 'unified-plan',
    };

    final pc = await createPeerConnection(config, {});

    pc.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        _remoteRenderer.srcObject = event.streams.first;
        if (mounted) setState(() {});
      }
    };

    pc.onIceCandidate = (candidate) async {
      await _callService.addIceCandidate(_callId!, candidate.toMap());
    };

    pc.onConnectionState = (state) {
      if (!mounted) return;
      setState(() => _statusText = _connectionLabel(state));
    };

    return pc;
  }

  Future<void> _createActiveCall() async {
    _callId = await _callService.initiateCall(receiverId: widget.receiverId, isVideo: widget.isVideo);

    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);
    await _callService.setSDP(_callId!, 'offer', offer.sdp ?? '');
    await _callService.updateCallStatus(_callId!, 'active');

    _peerConnection!.onIceCandidate = (candidate) async {
      await _callService.addIceCandidate(_callId!, candidate.toMap());
    };

    _listenForRemoteSignals();

    if (!mounted) return;

    setState(() => _statusText = 'Calling ${widget.receiverName}...');
  }

  void _listenForRemoteSignals() {
    if (_callId == null) return;

    _callService.getSDP(_callId!).listen((rows) async {
      if (!mounted) return;

      final answerRows = rows.where((row) {
        final type = row['type']?.toString();
        return type == 'answer';
      }).toList();

      if (answerRows.isEmpty || _peerConnection == null) return;

      final remoteSdp = answerRows.first['sdp']?.toString();
      if (remoteSdp == null || remoteSdp.isEmpty) return;

      await _peerConnection!.setRemoteDescription(RTCSessionDescription(remoteSdp, 'answer'));
      if (!mounted) return;
      setState(() => _statusText = 'Connected with ${widget.receiverName}');
    });

    _callService.getIceCandidates(_callId!).listen((rows) async {
      if (_peerConnection == null) return;

      for (final row in rows) {
        final candidate = row['candidate'] as Map<String, dynamic>?;
        if (candidate == null) continue;

        await _peerConnection!.addCandidate(
          RTCIceCandidate(candidate['candidate'] as String, candidate['sdpMid'] as String? ?? '', candidate['sdpMLineIndex'] as int? ?? 0),
        );
      }
    });
  }

  Future<void> _toggleMic() async {
    if (_localStream == null) return;

    final audioTracks = _localStream!.getAudioTracks();
    if (audioTracks.isEmpty) return;

    final track = audioTracks.first;
    _isMuted = !_isMuted;
    track.enabled = !_isMuted;

    if (mounted) setState(() {});
  }

  Future<void> _toggleVideo() async {
    if (_localStream == null) return;

    final videoTracks = _localStream!.getVideoTracks();
    if (videoTracks.isEmpty) return;

    final track = videoTracks.first;
    _isVideoEnabled = !_isVideoEnabled;
    track.enabled = _isVideoEnabled;

    if (mounted) setState(() {});
  }

  Future<void> _endCall() async {
    if (_isEnding) return;

    _isEnding = true;

    try {
      if (_callId != null) {
        await _callService.endCall(_callId!);
      }
    } finally {
      _stopMedia();
      if (mounted) Navigator.pop(context);
    }
  }

  void _stopMedia() {
    _localStream?.getTracks().forEach((track) => track.stop());
    _localStream = null;
    _peerConnection?.close();
    _peerConnection = null;
  }

  String _connectionLabel(RTCPeerConnectionState state) {
    switch (state) {
      case RTCPeerConnectionState.RTCPeerConnectionStateNew:
        return 'Connecting...';
      case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
        return 'Connected';
      case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
        return 'Connection failed';
      case RTCPeerConnectionState.RTCPeerConnectionStateClosed:
        return 'Call ended';
      case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
        return 'Disconnected';
      default:
        return 'Connecting...';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF08101E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1222),
        title: Text(widget.receiverName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        leading: IconButton(onPressed: _endCall, icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70)),
      ),
      body: Stack(
        children: [
          if (_remoteRenderer.srcObject != null)
            Positioned.fill(child: RTCVideoView(_remoteRenderer, mirror: false))
          else
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [const Color(0xFF140E2D), kNeonPurple.withValues(alpha: 0.3)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(radius: 54, backgroundColor: Colors.white.withValues(alpha: 0.12), child: Icon(widget.isVideo ? Icons.videocam : Icons.call, size: 40, color: Colors.white70)),
                    const SizedBox(height: 20),
                    Text(widget.receiverName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text(_statusText, style: const TextStyle(color: Colors.white54, fontSize: 13)),
                  ],
                ),
              ),
            ),
          if (widget.isVideo && _localRenderer.srcObject != null)
            Positioned(right: 16, top: 16, width: 140, height: 200, child: ClipRRect(borderRadius: BorderRadius.circular(18), child: RTCVideoView(_localRenderer, mirror: true))),
          Positioned(
            left: 0,
            right: 0,
            bottom: 28,
            child: Column(
              children: [
                if (_isPreparing)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: CircularProgressIndicator(color: kNeonGreen),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _controlButton(
                      icon: _isMuted ? Icons.mic_off : Icons.mic,
                      color: _isMuted ? Colors.redAccent : kNeonGreen,
                      onPressed: _toggleMic,
                    ),
                    if (widget.isVideo) const SizedBox(width: 16),
                    if (widget.isVideo)
                      _controlButton(
                        icon: _isVideoEnabled
                            ? Icons.videocam
                            : Icons.videocam_off,
                        color: _isVideoEnabled ? kNeonBlue : Colors.redAccent,
                        onPressed: _toggleVideo,
                      ),
                    const SizedBox(width: 16),
                    _controlButton(
                      icon: Icons.call_end,
                      color: Colors.redAccent,
                      onPressed: _endCall,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  _statusText,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _controlButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: color, size: 28),
      ),
    );
  }
}
