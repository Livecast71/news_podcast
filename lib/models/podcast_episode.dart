class PodcastEpisode {
  final int id;
  final String title;
  final String? intro;
  final String? teaserContent;
  final List<PodcastAudio> audios;
  final String? imageUrl;
  final String publicationDate;
  final String? shareUrl;

  const PodcastEpisode({
    required this.id,
    required this.title,
    this.intro,
    this.teaserContent,
    required this.audios,
    this.imageUrl,
    required this.publicationDate,
    this.shareUrl,
  });

  factory PodcastEpisode.fromJson(Map<String, dynamic> json) {
    final audiosJson = json['audios'] as List<dynamic>? ?? [];
    return PodcastEpisode(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      intro: json['intro'] as String?,
      teaserContent: json['teaserContent'] as String?,
      audios: audiosJson
          .map((a) => PodcastAudio.fromJson(a as Map<String, dynamic>))
          .toList(),
      imageUrl: json['img'] as String?,
      publicationDate: json['publicationDate'] as String? ?? '',
      shareUrl: json['shareUrl'] as String?,
    );
  }

  String get description => teaserContent ?? intro ?? '';
}

class PodcastAudio {
  final String title;
  final String sourceUrl;
  final int duration; // in milliseconds
  final String filename;

  const PodcastAudio({
    required this.title,
    required this.sourceUrl,
    required this.duration,
    required this.filename,
  });

  factory PodcastAudio.fromJson(Map<String, dynamic> json) {
    return PodcastAudio(
      title: json['title'] as String? ?? '',
      sourceUrl: json['sourceUrl'] as String? ?? '',
      duration: json['duration'] as int? ?? 0,
      filename: json['filename'] as String? ?? '',
    );
  }

  String get durationFormatted {
    final seconds = duration ~/ 1000;
    final minutes = seconds ~/ 60;
    final hours = minutes ~/ 60;
    if (hours > 0) {
      return '${hours}:${(minutes % 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
    }
    return '${minutes}:${(seconds % 60).toString().padLeft(2, '0')}';
  }
}

class PodcastProgram {
  final int id;
  final String title;
  final String intro;
  final String? logoUrl;
  final String? signatureUrl;
  final String broadcastSchedule;
  final String? programColor;

  const PodcastProgram({
    required this.id,
    required this.title,
    required this.intro,
    this.logoUrl,
    this.signatureUrl,
    this.broadcastSchedule = '',
    this.programColor,
  });

  factory PodcastProgram.fromJson(Map<String, dynamic> json) {
    final logoPic = json['logoPicture'] as Map<String, dynamic>?;
    final sigPic = json['signaturePicture'] as Map<String, dynamic>?;
    
    return PodcastProgram(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      intro: json['intro'] as String? ?? '',
      logoUrl: logoPic != null
          ? 'https://bnr-external-prod.imgix.net/${logoPic['path'] as String?}'
          : null,
      signatureUrl: sigPic != null
          ? 'https://bnr-external-prod.imgix.net/${sigPic['path'] as String?}'
          : null,
      broadcastSchedule: json['broadcastSchedule'] as String? ?? '',
      programColor: json['programColor'] as String?,
    );
  }
}

