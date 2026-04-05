import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../providers/task_provider.dart';
import '../models/task_model.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});
  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  TaskCategory? _filter;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    final pending = _filter == null
        ? provider.pendingTasks
        : provider.pendingTasks.where((t) => t.category == _filter).toList();
    final completed = _filter == null
        ? provider.completedTasks
        : provider.completedTasks.where((t) => t.category == _filter).toList();

    return Scaffold(
      backgroundColor: NHRColors.milk,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(context),
        child: const Icon(Icons.add_rounded),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
              child: _buildFilters(),
            ),
          ),
          if (pending.isEmpty && completed.isEmpty)
            SliverFillRemaining(
              child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.check_circle_outline, size: 48, color: NHRColors.fog),
                const SizedBox(height: 12),
                Text('No tasks yet', style: GoogleFonts.inter(color: NHRColors.dusty, fontSize: 14)),
              ])),
            )
          else ...[
            if (pending.isNotEmpty) ...[
              SliverToBoxAdapter(child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Text('${pending.length} pending', style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.5, color: NHRColors.dusty)),
              )),
              SliverList(delegate: SliverChildBuilderDelegate(
                (context, index) => _buildTaskItem(context, provider, pending[index])
                  .animate().fadeIn(delay: (60 * index).ms),
                childCount: pending.length,
              )),
            ],
            if (completed.isNotEmpty) ...[
              SliverToBoxAdapter(child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                child: Text('${completed.length} completed', style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.5, color: NHRColors.dusty)),
              )),
              SliverList(delegate: SliverChildBuilderDelegate(
                (context, index) => _buildTaskItem(context, provider, completed[index]),
                childCount: completed.length,
              )),
            ],
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _buildTaskItem(BuildContext context, TaskProvider provider, TaskModel task) {
    final priorityColor = task.priority == TaskPriority.high
        ? NHRColors.terracotta
        : task.priority == TaskPriority.medium
            ? NHRColors.slate
            : NHRColors.sage;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(children: [
        InkWell(
          onLongPress: () => provider.deleteTask(task.id),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(children: [
              // Priority dot
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(shape: BoxShape.circle, color: priorityColor),
              ),
              const SizedBox(width: 14),
              // Checkbox
              GestureDetector(
                onTap: () => provider.completeTask(task.id),
                child: Container(
                  width: 22, height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: task.completed ? NHRColors.sage : NHRColors.fog,
                      width: 2,
                    ),
                    color: task.completed ? NHRColors.sage : Colors.transparent,
                  ),
                  child: task.completed
                    ? const Icon(Icons.check, size: 14, color: NHRColors.milk)
                    : null,
                ),
              ),
              const SizedBox(width: 14),
              // Title
              Expanded(
                child: Text(
                  task.title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: task.completed ? NHRColors.dusty : NHRColors.charcoal,
                    decoration: task.completed ? TextDecoration.lineThrough : null,
                    decorationColor: NHRColors.dusty,
                  ),
                ),
              ),
              // Category tag
              if (task.category != TaskCategory.study)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: NHRColors.fog.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(task.category.name, style: GoogleFonts.inter(
                    fontSize: 10, fontWeight: FontWeight.w500, color: NHRColors.dusty)),
                ),
            ]),
          ),
        ),
        const Divider(height: 0),
      ]),
    );
  }

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        _filterChip('All', null),
        ...TaskCategory.values.map((c) => _filterChip(c.name[0].toUpperCase() + c.name.substring(1), c)),
      ]),
    );
  }

  Widget _filterChip(String label, TaskCategory? cat) {
    final selected = _filter == cat;
    return GestureDetector(
      onTap: () => setState(() => _filter = cat),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? NHRColors.charcoal : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? NHRColors.charcoal : NHRColors.fog),
        ),
        child: Text(label, style: GoogleFonts.inter(
          color: selected ? NHRColors.milk : NHRColors.dusty,
          fontWeight: FontWeight.w600, fontSize: 12)),
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    String title = '';
    TaskPriority priority = TaskPriority.medium;
    TaskCategory category = TaskCategory.study;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: NHRColors.milk,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('New Task', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: NHRColors.charcoal)),
            const SizedBox(height: 16),
            TextField(
              autofocus: true,
              decoration: const InputDecoration(hintText: 'What needs to be done?'),
              onChanged: (v) => title = v,
            ),
            const SizedBox(height: 16),
            Text('PRIORITY', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 2, color: NHRColors.dusty)),
            const SizedBox(height: 8),
            Row(children: [
              _priorityChip(setDialogState, 'High', priority == TaskPriority.high, () => priority = TaskPriority.high, NHRColors.terracotta),
              _priorityChip(setDialogState, 'Med', priority == TaskPriority.medium, () => priority = TaskPriority.medium, NHRColors.slate),
              _priorityChip(setDialogState, 'Low', priority == TaskPriority.low, () => priority = TaskPriority.low, NHRColors.sage),
            ]),
            const SizedBox(height: 16),
            Text('CATEGORY', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 2, color: NHRColors.dusty)),
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6, children: TaskCategory.values.map((c) => GestureDetector(
              onTap: () => setDialogState(() => category = c),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: category == c ? NHRColors.charcoal : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: category == c ? NHRColors.charcoal : NHRColors.fog),
                ),
                child: Text(c.name, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500,
                  color: category == c ? NHRColors.milk : NHRColors.dusty)),
              ),
            )).toList()),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: () {
                if (title.trim().isNotEmpty) {
                  context.read<TaskProvider>().addTask(title: title.trim(), priority: priority, category: category);
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Add Task'),
            )),
          ]),
        ),
      ),
    );
  }

  Widget _priorityChip(StateSetter ss, String label, bool selected, VoidCallback onTap, Color color) {
    return GestureDetector(
      onTap: () => ss(() => onTap()),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? color : NHRColors.fog),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? color : NHRColors.dusty)),
        ]),
      ),
    );
  }
}
