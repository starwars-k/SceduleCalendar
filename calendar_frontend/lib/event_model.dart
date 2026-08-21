class DailyEvent{
  final int? id;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final String eventType;
  final String? repeatType;
  final bool isAllDay;
  DailyEvent({
    this.id, 
    required this.title, 
    required this.description, 
    required this.startTime, 
    required this.endTime, 
    required this.eventType,
    required this.repeatType,
    required this.isAllDay,
  });

  factory DailyEvent.fromJson(Map<String, dynamic> json){
    var rawStart = json['startTime'] ?? json['startTime'];
    var rawEnd = json['endTime'] ?? json['endTime'];
    var rawType = json['eventType'] ?? json['eventType'];

    return DailyEvent(
      id: json['id'] is int ? json['id'] : (int.tryParse(json['id']?.toString() ?? '0') ?? 0),
      title: json['title'] ?? 'No Title',
      description: json['description']?.toString() ?? '',
      startTime: rawStart != null 
        ? DateTime.parse(rawStart.toString()) 
        : DateTime.now(),
      endTime: rawEnd != null 
        ? DateTime.parse(rawEnd.toString()) 
        : DateTime.now(),
      eventType: rawType?.toString() ?? 'Unknown',
      repeatType: json['repeatType']?.toString(),
      isAllDay: json['isAllDay'] ?? false,
    );
  }
}