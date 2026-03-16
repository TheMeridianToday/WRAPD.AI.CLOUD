// Speaker Profile Model
// Handles speaker identification, voice profiles, and metadata

import 'package:hive/hive.dart';

part 'speaker_profile_model.g.dart';

@HiveType(typeId: 20)
enum SpeakerGender {
  @HiveField(0)
  male,
  @HiveField(1)
  female,
  @HiveField(2)
  nonBinary
}

@HiveType(typeId: 21)
class VoiceProfile {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String name;
  
  @HiveField(2)
  DateTime createdAt;
  
  @HiveField(3)
  DateTime updatedAt;
  
  @HiveField(4)
  SpeakerGender gender;
  
  @HiveField(5)
  List<double> voiceFeatures; // Embedding vector for voice recognition
  
  @HiveField(6)
  Map<String, dynamic> voiceStatistics; // Pitch, frequency, etc.
  
  @HiveField(7)
  int usageCount;
  
  @HiveField(8)
  String colorTag; // Visual identification color
  
  VoiceProfile({
    required this.id,
    required this.name,
    required this.gender,
    this.voiceFeatures = const [],
    this.voiceStatistics = const {},
    this.usageCount = 0,
    this.colorTag = '#4CAF50', // Default green
  }) : createdAt = DateTime.now(), updatedAt = DateTime.now();
  
  // Update voice features and statistics
  void updateVoiceProfile(List<double> newFeatures, Map<String, dynamic> newStats) {
    voiceFeatures = newFeatures;
    voiceStatistics = newStats;
    updatedAt = DateTime.now();
    usageCount++;
  }
  
  // Get speaker display name
  String get displayName => name.isEmpty ? 'Speaker $id' : name;
  
  VoiceProfile copyWith({
    String? id,
    String? name,
    SpeakerGender? gender,
    List<double>? voiceFeatures,
    Map<String, dynamic>? voiceStatistics,
    int? usageCount,
    String? colorTag,
  }) {
    final profile = VoiceProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      voiceFeatures: voiceFeatures ?? this.voiceFeatures,
      voiceStatistics: voiceStatistics ?? this.voiceStatistics,
      usageCount: usageCount ?? this.usageCount,
      colorTag: colorTag ?? this.colorTag,
    );
    profile.createdAt = this.createdAt;
    profile.updatedAt = DateTime.now();
    return profile;
  }
  
  // JSON serialization
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'gender': gender.name,
    'voiceFeatures': voiceFeatures,
    'voiceStatistics': voiceStatistics,
    'usageCount': usageCount,
    'colorTag': colorTag,
  };
  
  factory VoiceProfile.fromJson(Map<String, dynamic> json) => VoiceProfile(
    id: json['id'] as String,
    name: json['name'] as String,
    gender: SpeakerGender.values.firstWhere(
      (e) => e.name == (json['gender'] as String),
      orElse: () => SpeakerGender.nonBinary
    ),
    voiceFeatures: (json['voiceFeatures'] as Iterable<dynamic>?)?.map((e) => (e as num).toDouble()).toList() ?? [],
    voiceStatistics: Map<String, dynamic>.from(json['voiceStatistics'] as Map? ?? {}),
    usageCount: (json['usageCount'] as num?)?.toInt() ?? 0,
    colorTag: (json['colorTag'] as String?) ?? '#4CAF50',
  );
}

// Speaker diarization result
class SpeakerDiarizationResult {
  final String speakerId;
  final String speakerName;
  final Duration startTime;
  final Duration endTime;
  final double confidence;
  final String segmentId;
  
  SpeakerDiarizationResult({
    required this.speakerId,
    required this.speakerName,
    required this.startTime,
    required this.endTime,
    required this.confidence,
    this.segmentId = '',
  });
  
  Duration get duration => endTime - startTime;
}
