enum FeedbackType {
  suggestion,
  complaint,
  general,
}

extension FeedbackTypeX on FeedbackType {
  String get label {
    switch (this) {
      case FeedbackType.suggestion:
        return 'Suggestion';
      case FeedbackType.complaint:
        return 'Complaint';
      case FeedbackType.general:
        return 'General Feedback';
    }
  }
}

class FeedbackModel {
  final String name;
  final String email;
  final FeedbackType type;
  final String content;
  final DateTime submittedAt;

  const FeedbackModel({
    required this.name,
    required this.email,
    required this.type,
    required this.content,
    required this.submittedAt,
  });
}
