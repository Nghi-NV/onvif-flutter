class RecordInfo {
  final String recordingToken;
  final String startTime;
  final String endTime;
  final String source;
  final String description;
  final List<TrackInfo> tracks;
  final bool isEstimated;

  RecordInfo({
    required this.recordingToken,
    required this.startTime,
    required this.endTime,
    required this.source,
    required this.description,
    required this.tracks,
    required this.isEstimated,
  });

  factory RecordInfo.fromJson(Map<String, dynamic> json) {
    print('json::${json}');
    return RecordInfo(
      recordingToken: json['RecordingToken'],
      startTime: json['StartTime'],
      endTime: json['EndTime'],
      source: json['Source'],
      description: json['Description'],
      tracks: [],
      // tracks: json['Tracks'] != null
      //     ? (json['Tracks'] as List).map((e) => TrackInfo.fromJson(e)).toList()
      //     : [],
      isEstimated: json['IsEstimated'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'RecordingToken': recordingToken,
      'StartTime': startTime,
      'EndTime': endTime,
      'Source': source,
      'Description': description,
      'Tracks': tracks.map((e) => e.toJson()).toList(),
      'IsEstimated': isEstimated,
    };
  }

  @override
  String toString() {
    return 'RecordInfo(recordingToken: $recordingToken, startTime: $startTime, endTime: $endTime, source: $source, description: $description, tracks: $tracks, isEstimated: $isEstimated)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RecordInfo &&
        other.recordingToken == recordingToken &&
        other.startTime == startTime &&
        other.endTime == endTime &&
        other.source == source &&
        other.description == description &&
        other.tracks == tracks &&
        other.isEstimated == isEstimated;
  }

  @override
  int get hashCode =>
      recordingToken.hashCode ^
      startTime.hashCode ^
      endTime.hashCode ^
      source.hashCode ^
      description.hashCode ^
      tracks.hashCode ^
      isEstimated.hashCode;
}

class TrackInfo {
  final String trackToken;
  final String trackType;
  final String description;

  TrackInfo({
    required this.trackToken,
    required this.trackType,
    required this.description,
  });

  factory TrackInfo.fromJson(Map<String, dynamic> json) {
    return TrackInfo(
      trackToken: json['TrackToken'],
      trackType: json['TrackType'],
      description: json['Description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'TrackToken': trackToken,
      'TrackType': trackType,
      'Description': description,
    };
  }

  @override
  String toString() {
    return 'TrackInfo(trackToken: $trackToken, trackType: $trackType, description: $description)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TrackInfo &&
        other.trackToken == trackToken &&
        other.trackType == trackType &&
        other.description == description;
  }

  @override
  int get hashCode =>
      trackToken.hashCode ^ trackType.hashCode ^ description.hashCode;
}
