import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/lecture_model.dart';
import '../providers/lecture_provider.dart';
import '../theme/app_theme.dart';
import 'lecture_player_screen.dart';

class LecturesScreen extends StatefulWidget {
  const LecturesScreen({super.key});
  @override
  State<LecturesScreen> createState() => _LecturesScreenState();
}

class _LecturesScreenState extends State<LecturesScreen> {
  String _filter = 'All';
  final Set<String> _expandedCourses = {};

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LectureProvider>();
    final courses = provider.courses;
    final standalone = provider.standaloneLectures;

    // Filter-specific lists
    List<LectureModel> filteredStandalone = standalone;
    if (_filter == 'In Progress')
      filteredStandalone = standalone
          .where((l) => !l.completed && l.watchedSeconds > 0)
          .toList();
    else if (_filter == 'Completed')
      filteredStandalone = standalone.where((l) => l.completed).toList();

    return Scaffold(
      backgroundColor: NHRColors.milk,
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'playlist',
            onPressed: () => _addPlaylist(context),
            backgroundColor: NHRColors.slate,
            child: const Icon(
              Icons.playlist_add,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'lecture',
            onPressed: () => _addLecture(context),
            child: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
              child: _buildFilters(),
            ),
          ),
          // Courses section
          if (courses.isNotEmpty && _filter != 'Completed')
            ...courses.entries.map((entry) {
              final courseId = entry.key;
              final courseTitle = entry.value['title'] as String;
              final courseLecs = entry.value['lectures'] as List<LectureModel>;
              final progress = provider.courseProgress(courseId);
              final isExpanded = _expandedCourses.contains(courseId);

              return SliverToBoxAdapter(
                child: Column(
                  children: [
                    // Course header
                    InkWell(
                      onTap: () => setState(() {
                        if (isExpanded)
                          _expandedCourses.remove(courseId);
                        else
                          _expandedCourses.add(courseId);
                      }),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: NHRColors.slate.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.school_rounded,
                                  size: 18,
                                  color: NHRColors.slate,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    courseTitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: NHRColors.charcoal,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        '${progress['completed']}/${progress['total']} lectures',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: NHRColors.dusty,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            2,
                                          ),
                                          child: LinearProgressIndicator(
                                            value: progress['total'] > 0
                                                ? progress['completed'] /
                                                      progress['total']
                                                : 0.0,
                                            minHeight: 3,
                                            backgroundColor: NHRColors.fog,
                                            valueColor: AlwaysStoppedAnimation(
                                              NHRColors.sage,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${progress['percent']}%',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: NHRColors.sage,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                size: 20,
                                color: NHRColors.terracotta,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    backgroundColor: NHRColors.milk,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    title: Text(
                                      'Delete Course?',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w700,
                                        color: NHRColors.charcoal,
                                      ),
                                    ),
                                    content: Text(
                                      'This will delete all lectures in this course.',
                                      style: GoogleFonts.inter(
                                        color: NHRColors.dusty,
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: const Text(
                                          'Cancel',
                                          style: TextStyle(
                                            color: NHRColors.dusty,
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          provider.deleteCourse(courseId);
                                          Navigator.pop(ctx);
                                        },
                                        child: const Text(
                                          'Delete',
                                          style: TextStyle(
                                            color: NHRColors.terracotta,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              isExpanded
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              color: NHRColors.dusty,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (isExpanded)
                      ...courseLecs.map(
                        (lec) => _buildLectureItem(context, provider, lec),
                      ),
                    const Divider(height: 0, indent: 24, endIndent: 24),
                  ],
                ),
              );
            }),
          // Standalone lectures
          if (filteredStandalone.isEmpty && courses.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.play_circle_outline,
                      size: 48,
                      color: NHRColors.fog,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No lectures yet',
                      style: GoogleFonts.inter(color: NHRColors.dusty),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap + for a video, or playlist icon for a playlist',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: NHRColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildLectureItem(
                  context,
                  provider,
                  filteredStandalone[index],
                ).animate().fadeIn(delay: (60 * index).ms),
                childCount: filteredStandalone.length,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _buildLectureItem(
    BuildContext context,
    LectureProvider provider,
    LectureModel lec,
  ) {
    final isCompleted = lec.progressPercent >= 1.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          InkWell(
            onTap: () => _openDetail(context, provider, lec),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                children: [
                  // Thumbnail
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      'https://img.youtube.com/vi/${lec.videoId}/hqdefault.jpg',
                      width: 72,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (_, e, s) => Container(
                        width: 72,
                        height: 48,
                        decoration: BoxDecoration(
                          color: NHRColors.fog,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.play_circle_outline,
                          color: NHRColors.dusty,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lec.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: NHRColors.charcoal,
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (!isCompleted)
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(2),
                                  child: LinearProgressIndicator(
                                    value: lec.progressPercent.clamp(0.0, 1.0),
                                    minHeight: 3,
                                    backgroundColor: NHRColors.fog,
                                    valueColor: AlwaysStoppedAnimation(
                                      NHRColors.sage,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                lec.progressText,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: NHRColors.sage,
                                ),
                              ),
                            ],
                          )
                        else
                          Text(
                            'Completed',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: NHRColors.sage,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Play button
                  IconButton(
                    icon: const Icon(
                      Icons.play_arrow_rounded,
                      color: NHRColors.charcoal,
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LecturePlayerScreen(lecture: lec),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 0),
        ],
      ),
    );
  }

  void _openDetail(
    BuildContext context,
    LectureProvider provider,
    LectureModel lec,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: NHRColors.milk,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _LectureDetailSheet(lec: lec, provider: provider),
    );
  }

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: ['All', 'In Progress', 'Completed'].map((label) {
          final selected = _filter == label;
          return GestureDetector(
            onTap: () => setState(() => _filter = label),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: selected ? NHRColors.charcoal : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? NHRColors.charcoal : NHRColors.fog,
                ),
              ),
              child: Text(
                label,
                style: GoogleFonts.inter(
                  color: selected ? NHRColors.milk : NHRColors.dusty,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _addLecture(BuildContext context) {
    String url = '';
    bool isSubmitting = false;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: NHRColors.milk,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add Lecture',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: NHRColors.charcoal,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Paste a YouTube link',
                style: GoogleFonts.inter(fontSize: 12, color: NHRColors.dusty),
              ),
              const SizedBox(height: 16),
              TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'https://youtube.com/watch?v=...',
                ),
                onChanged: (v) => url = v,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (url.trim().isEmpty) return;
                          final messenger = ScaffoldMessenger.of(context);
                          final lectureProvider = ctx.read<LectureProvider>();
                          setDialogState(() => isSubmitting = true);

                          try {
                            final vid = LectureProvider.extractVideoId(
                              url.trim(),
                            );
                            if (vid == null) {
                              messenger.showSnackBar(
                                const SnackBar(content: Text('Invalid URL')),
                              );
                              setDialogState(() => isSubmitting = false);
                              return;
                            }

                            final info =
                                await LectureProvider.fetchVideoInfo(
                                  url.trim(),
                                ).timeout(
                                  const Duration(seconds: 12),
                                  onTimeout: () => null,
                                );

                            await lectureProvider.addLecture(
                              title: info?.title ?? 'Untitled',
                              url: url.trim(),
                              videoId: vid,
                              totalDurationSeconds: info?.durationSeconds ?? 0,
                            );

                            if (!ctx.mounted) return;
                            Navigator.pop(ctx);
                            messenger.showSnackBar(
                              const SnackBar(content: Text('Lecture added')),
                            );
                          } catch (e) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Could not add lecture: ${e.toString()}',
                                ),
                              ),
                            );
                          } finally {
                            if (ctx.mounted) {
                              setDialogState(() => isSubmitting = false);
                            }
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Add Lecture'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addPlaylist(BuildContext context) {
    String url = '';
    bool isSubmitting = false;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: NHRColors.milk,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Import Playlist',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: NHRColors.charcoal,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Paste a YouTube playlist link to import as a course',
                style: GoogleFonts.inter(fontSize: 12, color: NHRColors.dusty),
              ),
              const SizedBox(height: 16),
              TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'https://youtube.com/playlist?list=...',
                ),
                onChanged: (v) => url = v,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (url.trim().isEmpty) return;
                          final messenger = ScaffoldMessenger.of(context);
                          final lectureProvider = ctx.read<LectureProvider>();
                          setDialogState(() => isSubmitting = true);

                          try {
                            final playlistId =
                                LectureProvider.extractPlaylistId(url.trim());
                            if (playlistId == null) {
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Invalid playlist URL'),
                                ),
                              );
                              setDialogState(() => isSubmitting = false);
                              return;
                            }

                            final count = await lectureProvider.addPlaylist(
                              url.trim(),
                            );
                            final reason =
                                lectureProvider.lastPlaylistImportError;

                            if (!ctx.mounted) return;
                            Navigator.pop(ctx);

                            if (count > 0) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Imported $count lectures as a course',
                                  ),
                                ),
                              );
                            } else {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    reason ??
                                        'Could not import playlist. Try again.',
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Error importing playlist: ${e.toString()}',
                                ),
                              ),
                            );
                          } finally {
                            if (ctx.mounted) {
                              setDialogState(() => isSubmitting = false);
                            }
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Import Playlist'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LectureDetailSheet extends StatefulWidget {
  final LectureModel lec;
  final LectureProvider provider;
  const _LectureDetailSheet({required this.lec, required this.provider});
  @override
  State<_LectureDetailSheet> createState() => _LectureDetailSheetState();
}

class _LectureDetailSheetState extends State<_LectureDetailSheet> {
  late LectureModel lec;
  @override
  void initState() {
    super.initState();
    lec = widget.lec;
  }

  @override
  Widget build(BuildContext context) {
    final chunks = lec.generateChunks();
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (context, sc) => Padding(
        padding: const EdgeInsets.all(24),
        child: ListView(
          controller: sc,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: NHRColors.fog,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              lec.title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: NHRColors.charcoal,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              lec.remainingText,
              style: GoogleFonts.inter(fontSize: 12, color: NHRColors.dusty),
            ),
            const SizedBox(height: 16),
            // Progress
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: lec.progressPercent.clamp(0.0, 1.0),
                      minHeight: 5,
                      backgroundColor: NHRColors.fog,
                      valueColor: AlwaysStoppedAnimation(NHRColors.sage),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  lec.progressText,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: NHRColors.sage,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final uri = Uri.parse(lec.url);
                      if (await canLaunchUrl(uri))
                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                    },
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    label: const Text('YouTube'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _updateProgress(context),
                    child: const Text('Update Progress'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () {
                widget.provider.deleteLecture(lec.id);
                Navigator.pop(context);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: NHRColors.terracotta,
                side: BorderSide(
                  color: NHRColors.terracotta.withValues(alpha: 0.3),
                ),
              ),
              child: const Text('Delete Lecture'),
            ),
            // Sub-tasks
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'SUB-TASKS',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                    color: NHRColors.dusty,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.add_rounded,
                    color: NHRColors.charcoal,
                    size: 20,
                  ),
                  onPressed: () => _addSubTask(context),
                ),
              ],
            ),
            if (lec.subTasks.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 8),
                child: Text(
                  'No sub-tasks yet — tap + to add',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: NHRColors.textMuted,
                  ),
                ),
              )
            else
              ...lec.subTasks.map(
                (st) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GestureDetector(
                    onTap: () {
                      widget.provider.toggleSubTask(lec.id, st.id);
                      setState(() {});
                    },
                    onLongPress: () {
                      widget.provider.deleteSubTask(lec.id, st.id);
                      setState(() {});
                    },
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: st.completed
                                  ? NHRColors.sage
                                  : NHRColors.fog,
                              width: 2,
                            ),
                            color: st.completed
                                ? NHRColors.sage
                                : Colors.transparent,
                          ),
                          child: st.completed
                              ? const Icon(
                                  Icons.check,
                                  size: 12,
                                  color: NHRColors.milk,
                                )
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            st.title,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: st.completed
                                  ? NHRColors.dusty
                                  : NHRColors.charcoal,
                              decoration: st.completed
                                  ? TextDecoration.lineThrough
                                  : null,
                              decorationColor: NHRColors.dusty,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (chunks.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'SEGMENTS',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  color: NHRColors.dusty,
                ),
              ),
              const SizedBox(height: 10),
              ...chunks.map(
                (c) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(
                        c.completed
                            ? Icons.check_circle_rounded
                            : Icons.circle_outlined,
                        size: 18,
                        color: c.completed ? NHRColors.sage : NHRColors.fog,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${c.startSeconds ~/ 60}m – ${c.endSeconds ~/ 60}m',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: NHRColors.charcoal,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        c.completed ? 'Done' : 'Pending',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: NHRColors.dusty,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'NOTES',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                    color: NHRColors.dusty,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.add_rounded,
                    color: NHRColors.charcoal,
                    size: 20,
                  ),
                  onPressed: () => _addNote(context),
                ),
              ],
            ),
            if (lec.notes.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'No notes yet',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: NHRColors.textMuted,
                  ),
                ),
              )
            else
              ...lec.notes.map((n) {
                final m = n.timestampSeconds ~/ 60;
                final s = n.timestampSeconds % 60;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: NHRColors.slate,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          n.content,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: NHRColors.charcoal,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  void _addSubTask(BuildContext context) {
    String title = '';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: NHRColors.milk,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Add Sub-Task',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: NHRColors.charcoal,
          ),
        ),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. Review lecture notes',
          ),
          onChanged: (v) => title = v,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: NHRColors.dusty)),
          ),
          TextButton(
            onPressed: () {
              if (title.trim().isNotEmpty) {
                widget.provider.addSubTask(lec.id, title.trim());
                setState(() {});
              }
              Navigator.pop(ctx);
            },
            child: Text('Add', style: TextStyle(color: NHRColors.sage)),
          ),
        ],
      ),
    );
  }

  void _updateProgress(BuildContext context) {
    final ctrl = TextEditingController(
      text: (lec.watchedSeconds ~/ 60).toString(),
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: NHRColors.milk,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Update Progress',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: NHRColors.charcoal,
          ),
        ),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: 'Minutes watched',
            suffixText: 'min',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: NHRColors.dusty)),
          ),
          TextButton(
            onPressed: () {
              final m = int.tryParse(ctrl.text) ?? 0;
              widget.provider.updateProgress(lec.id, m * 60, m * 60);
              setState(() {});
              Navigator.pop(ctx);
            },
            child: Text('Save', style: TextStyle(color: NHRColors.sage)),
          ),
        ],
      ),
    );
  }

  void _addNote(BuildContext context) {
    String content = '', ts = '0';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: NHRColors.milk,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Add Note',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: NHRColors.charcoal,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: 'Timestamp (minutes)',
                suffixText: 'min',
              ),
              keyboardType: TextInputType.number,
              onChanged: (v) => ts = v,
            ),
            const SizedBox(height: 10),
            TextField(
              decoration: const InputDecoration(hintText: 'Your note...'),
              maxLines: 3,
              onChanged: (v) => content = v,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: NHRColors.dusty)),
          ),
          TextButton(
            onPressed: () {
              if (content.trim().isNotEmpty) {
                widget.provider.addNote(
                  lec.id,
                  (int.tryParse(ts) ?? 0) * 60,
                  content.trim(),
                );
                setState(() {});
              }
              Navigator.pop(ctx);
            },
            child: Text('Add', style: TextStyle(color: NHRColors.sage)),
          ),
        ],
      ),
    );
  }
}
