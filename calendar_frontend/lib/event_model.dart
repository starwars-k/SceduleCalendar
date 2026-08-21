class DailyEvent{
  final int? id;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final String eventType;
  final bool isAllDay;
  final bool isRepeating;
  final String? repeatType;
  final bool? endOn;
  final DateTime? repeatEndOn;
  final String? seriesId;

  DailyEvent({
    this.id, 
    required this.title, 
    required this.description, 
    required this.startTime, 
    required this.endTime, 
    required this.eventType,
    required this.repeatType,
    required this.isAllDay,
    required this.isRepeating,
    this.repeatEndOn,
    this.endOn,
    this.seriesId,
  });

  factory DailyEvent.fromJson(Map<String, dynamic> json){
    return DailyEvent(
      id: json['id'] is int ? json['id'] : (int.tryParse(json['id']?.toString() ?? '0') ?? 0),
      title: json['title'] ?? 'No Title',
      description: json['description']?.toString() ?? '',
      startTime: json['startTime'] != null 
        ? DateTime.parse(json['startTime'].toString()) 
        : DateTime.now(),
      endTime: json['endTime'] != null 
        ? DateTime.parse(json['endTime'].toString()) 
        : DateTime.now(),
      eventType: json['eventType']?.toString() ?? 'Unknown',
      isAllDay: json['isAllDay'] ?? false,
      isRepeating: json['isRepeating'] ?? false,
      repeatType: json['repeatType']?.toString(),
      repeatEndOn: json['repeatEndOn'] != null
        ? DateTime.parse(json['repeatEndOn'].toString())
        : null,
      endOn: json['endOn'] ?? false,
      seriesId: json['seriesId']?.toString(), 
    );
  }
}