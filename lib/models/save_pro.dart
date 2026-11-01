import 'proposel.dart';

// A proposal plus the extra info we need to store it in history.
class SavedProposal {
  final String id;
  final DateTime createdAt;
  final String brief;
  final Proposal proposal;
  final String detail;

  SavedProposal({
    required this.id,
    required this.createdAt,
    required this.brief,
    required this.proposal,
    this.detail = '',

  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'created_at': createdAt.toIso8601String(),
    'brief': brief,
    'proposal': proposal.toJson(),
    'detail': detail,
  };

  factory SavedProposal.fromJson(Map<String, dynamic> j) => SavedProposal(
    id: j['id'] as String,
    createdAt: DateTime.parse(j['created_at'] as String),
    brief: j['brief'] as String,
    proposal: Proposal.fromJson(j['proposal'] as Map<String, dynamic>),
    detail: (j['detail'] ?? '') as String,
  );
}