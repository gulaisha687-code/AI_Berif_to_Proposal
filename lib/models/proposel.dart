class TaskItem {
  final String name;
  final String description;
  final double hours;

  TaskItem({
    required this.name,
    required this.description,
    required this.hours,
  });
  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'hours': hours,
  };
  factory TaskItem.fromJson(Map<String, dynamic> j) => TaskItem(
    name: j['name'] as String,
    description: (j['description'] ?? '') as String,
    hours: (j['hours'] as num).toDouble(),

  );
}

class Milestone {
  final String name;
  final int week;

  Milestone({required this.name, required this.week});
  Map<String, dynamic> toJson() => {
    'name': name,
    'week': week,
  };
  factory Milestone.fromJson(Map<String, dynamic> j) => Milestone(
    name: j['name'] as String,
    week: (j['week'] as num).toInt(),
  );
}

class Proposal {
  final bool isProjectBrief;
  final String rejectionReason;
  final String projectTitle;
  final String summary;
  final List<TaskItem> tasks;
  final List<Milestone> milestones;
  final List<String> assumptions;
  final List<String> questionsForClient;

  Proposal({
    required this.isProjectBrief,
    required this.rejectionReason,
    required this.projectTitle,
    required this.summary,
    required this.tasks,
    required this.milestones,
    required this.assumptions,
    required this.questionsForClient,
  });

  // Calculated in code, not trusted from the AI.
  double get totalHours => tasks.fold(0.0, (sum, t) => sum + t.hours);
  Map<String, dynamic> toJson() => {
    'is_project_brief': isProjectBrief,
    'rejection_reason': rejectionReason,
    'project_title': projectTitle,
    'summary': summary,
    'tasks': tasks.map((t) => t.toJson()).toList(),
    'milestones': milestones.map((m) => m.toJson()).toList(),
    'assumptions': assumptions,
    'questions_for_client': questionsForClient,
  };
  factory Proposal.fromJson(Map<String, dynamic> j) => Proposal(
    isProjectBrief: (j['is_project_brief'] ?? true) as bool,
    rejectionReason: (j['rejection_reason'] ?? '') as String,
    projectTitle: (j['project_title'] ?? '') as String,
    summary: (j['summary'] ?? '') as String,
    tasks: (j['tasks'] as List? ?? [])
        .map((e) => TaskItem.fromJson(e as Map<String, dynamic>))
        .toList(),
    milestones: (j['milestones'] as List? ?? [])
        .map((e) => Milestone.fromJson(e as Map<String, dynamic>))
        .toList(),
    assumptions:
    (j['assumptions'] as List? ?? []).map((e) => e.toString()).toList(),
    questionsForClient: (j['questions_for_client'] as List? ?? [])
        .map((e) => e.toString())
        .toList(),
  );
  List<Milestone> get sortedMilestones =>
      [...milestones]..sort((a, b) => a.week.compareTo(b.week));
  String toPlainText({double? hourlyRate, String currency = ''}) {
    final b = StringBuffer();
    b.writeln(projectTitle);
    b.writeln();
    b.writeln(summary);
    b.writeln();
    b.writeln('SCOPE & ESTIMATE');
    for (final t in tasks) {
      b.writeln('- ${t.name} (${t.hours.toStringAsFixed(0)} h)');
    }
    b.writeln('Total: ${totalHours.toStringAsFixed(0)} hours');
    if (hourlyRate != null && hourlyRate > 0) {
      final price = (totalHours * hourlyRate).toStringAsFixed(0);
      b.writeln('Estimated price: $currency$price');
    }
    if (milestones.isNotEmpty) {
      b.writeln();
      b.writeln('TIMELINE');
      for (final m in sortedMilestones) {
        b.writeln('- Week ${m.week}: ${m.name}');
      }
    }
    if (assumptions.isNotEmpty) {
      b.writeln();
      b.writeln('ASSUMPTIONS');
      for (final a in assumptions) {
        b.writeln('- $a');
      }
    }
    if (questionsForClient.isNotEmpty) {
      b.writeln();
      b.writeln('QUESTIONS TO CONFIRM');
      for (final q in questionsForClient) {
        b.writeln('- $q');
      }
    }
    return b.toString();
  }
}