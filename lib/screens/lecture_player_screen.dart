import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/lecture_model.dart';
import '../providers/lecture_provider.dart';
import '../theme/app_theme.dart';

class LecturePlayerScreen extends StatefulWidget {
  final LectureModel lecture;
  const LecturePlayerScreen({super.key, required this.lecture});

  @override
  State<LecturePlayerScreen> createState() => _LecturePlayerScreenState();
}

class _LecturePlayerScreenState extends State<LecturePlayerScreen> {
  late YoutubePlayerController _controller;
  bool _isFullScreen = false;
  final _noteController = TextEditingController();
  String _noteText = '';

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.lecture.videoId,
      flags: YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        startAt: widget.lecture.lastPositionSeconds,
      ),
    );

    _controller.addListener(() {
      if (_controller.value.isPlaying) {
        final pos = _controller.value.position.inSeconds;
        if (pos > widget.lecture.watchedSeconds) {
          context.read<LectureProvider>().updateProgress(widget.lecture.id, pos, pos);
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
        progressIndicatorColor: NHRColors.sage,
        progressColors: const ProgressBarColors(
          playedColor: NHRColors.sage,
          handleColor: NHRColors.charcoal,
        ),
        onReady: () {},
        onEnded: (_) {
          context.read<LectureProvider>().updateProgress(
            widget.lecture.id,
            widget.lecture.totalDurationSeconds,
            widget.lecture.totalDurationSeconds,
          );
        },
      ),
      onEnterFullScreen: () {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        setState(() => _isFullScreen = true);
      },
      onExitFullScreen: () {
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
        setState(() => _isFullScreen = false);
      },
      builder: (context, player) {
        return Scaffold(
          backgroundColor: NHRColors.milk,
          appBar: _isFullScreen ? null : AppBar(
            backgroundColor: NHRColors.milk,
            surfaceTintColor: Colors.transparent,
            title: Text(widget.lecture.title, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: NHRColors.charcoal)),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: NHRColors.charcoal),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Column(children: [
            player,
            if (!_isFullScreen)
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _buildProgress(),
                    const SizedBox(height: 28),
                    _buildQuickNote(),
                    const SizedBox(height: 28),
                    _buildNotes(),
                  ]),
                ),
              ),
          ]),
        );
      },
    );
  }

  // ── Progress Section ──
  Widget _buildProgress() {
    final pct = widget.lecture.progressPercent.clamp(0.0, 1.0);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('PROGRESS', style: GoogleFonts.inter(
          fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2, color: NHRColors.dusty)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: NHRColors.sage.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(widget.lecture.progressText, style: GoogleFonts.poppins(
            fontSize: 13, fontWeight: FontWeight.w700, color: NHRColors.sage)),
        ),
      ]),
      const SizedBox(height: 12),
      ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: LinearProgressIndicator(
          value: pct, minHeight: 5,
          backgroundColor: NHRColors.fog,
          valueColor: AlwaysStoppedAnimation(NHRColors.sage),
        ),
      ),
      const SizedBox(height: 8),
      Text(widget.lecture.remainingText, style: GoogleFonts.inter(fontSize: 12, color: NHRColors.dusty)),
    ]);
  }

  // ── Quick Note Section ──
  Widget _buildQuickNote() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('QUICK NOTE', style: GoogleFonts.inter(
        fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2, color: NHRColors.dusty)),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: NHRColors.milkDeep,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: NHRColors.fog),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          TextField(
            controller: _noteController,
            maxLines: 3,
            style: GoogleFonts.inter(fontSize: 14, color: NHRColors.charcoal),
            decoration: InputDecoration(
              hintText: 'Jot down your thoughts...',
              hintStyle: GoogleFonts.inter(fontSize: 13, color: NHRColors.textMuted),
              filled: false,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (v) => _noteText = v,
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: _saveNote,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: NHRColors.charcoal,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.bookmark_add_outlined, size: 16, color: NHRColors.milk),
                  const SizedBox(width: 6),
                  Text('Save at current time', style: GoogleFonts.inter(
                    fontSize: 12, fontWeight: FontWeight.w600, color: NHRColors.milk)),
                ]),
              ),
            ),
          ),
        ]),
      ),
    ]);
  }

  void _saveNote() {
    if (_noteText.trim().isEmpty) return;
    final pos = _controller.value.position.inSeconds;
    context.read<LectureProvider>().addNote(widget.lecture.id, pos, _noteText.trim());
    _noteController.clear();
    _noteText = '';
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Note saved', style: GoogleFonts.inter(color: NHRColors.milk, fontWeight: FontWeight.w500)),
      backgroundColor: NHRColors.charcoal,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 2),
    ));
  }

  // ── Bookmarked Notes Section ──
  Widget _buildNotes() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('BOOKMARKS', style: GoogleFonts.inter(
          fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2, color: NHRColors.dusty)),
        Text('${widget.lecture.notes.length}', style: GoogleFonts.inter(
          fontSize: 12, fontWeight: FontWeight.w600, color: NHRColors.dusty)),
      ]),
      const SizedBox(height: 14),
      if (widget.lecture.notes.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Center(child: Column(children: [
            Icon(Icons.bookmark_outline_rounded, size: 32, color: NHRColors.fog),
            const SizedBox(height: 8),
            Text('No bookmarks yet', style: GoogleFonts.inter(fontSize: 12, color: NHRColors.textMuted)),
            const SizedBox(height: 4),
            Text('Save a note above to bookmark a moment', style: GoogleFonts.inter(fontSize: 11, color: NHRColors.textMuted)),
          ])),
        )
      else
        ...widget.lecture.notes.map((note) => _noteItem(note)),
    ]);
  }

  Widget _noteItem(dynamic note) {
    final min = note.timestampSeconds ~/ 60;
    final sec = note.timestampSeconds % 60;
    final ts = '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Timestamp chip — tappable to seek
        GestureDetector(
          onTap: () => _controller.seekTo(Duration(seconds: note.timestampSeconds)),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: NHRColors.slate.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.play_arrow_rounded, size: 14, color: NHRColors.slate),
              const SizedBox(width: 4),
              Text(ts, style: GoogleFonts.inter(
                fontSize: 11, fontWeight: FontWeight.w700, color: NHRColors.slate)),
            ]),
          ),
        ),
        const SizedBox(width: 12),
        // Content
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(note.content, style: GoogleFonts.inter(fontSize: 13, color: NHRColors.charcoal, height: 1.4)),
        ])),
        // Delete
        GestureDetector(
          onTap: () {
            context.read<LectureProvider>().deleteNote(widget.lecture.id, note.id);
            setState(() {});
          },
          child: Padding(
            padding: const EdgeInsets.only(left: 8, top: 2),
            child: Icon(Icons.close_rounded, size: 16, color: NHRColors.textMuted),
          ),
        ),
      ]),
    );
  }
}
