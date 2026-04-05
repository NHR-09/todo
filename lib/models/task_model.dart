enum TaskPriority { high, medium, low }
enum TaskCategory { study, lecture, personal, project }

class TaskModel {
  final String id;
  String title;
  String description;
  TaskPriority priority;
  TaskCategory category;
  bool completed;
  DateTime createdAt;
  DateTime? dueDate;
  DateTime? completedAt;
  int xpValue;

  TaskModel({
    required this.id,
    required this.title,
    this.description = '',
    this.priority = TaskPriority.medium,
    this.category = TaskCategory.study,
    this.completed = false,
    required this.createdAt,
    this.dueDate,
    this.completedAt,
    this.xpValue = 20,
  });

  int get calculatedXP {
    switch (priority) {
      case TaskPriority.high:
        return 50;
      case TaskPriority.medium:
        return 25;
      case TaskPriority.low:
        return 10;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'priority': priority.index,
      'category': category.index,
      'completed': completed ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'xpValue': xpValue,
    };
  }

  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      id: map['id'] as String,
      title: map['title'] as String,
      description: (map['description'] as String?) ?? '',
      priority: TaskPriority.values[map['priority'] as int],
      category: TaskCategory.values[map['category'] as int],
      completed: (map['completed'] as int) == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
      dueDate: map['dueDate'] != null
          ? DateTime.parse(map['dueDate'] as String)
          : null,
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'] as String)
          : null,
      xpValue: (map['xpValue'] as int?) ?? 20,
    );
  }
}
