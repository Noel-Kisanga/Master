import 'package:flutter/src/material/time.dart';

class Event{
  String title;
  String description;
  String notes;
  String location;
  String guests;
  TimeOfDay? startTime;
  TimeOfDay? endTime;


  Event({
    required this.title,
    required this.description, 
    required this.notes, 
    required this.location,
    required this.guests, 
    required this.startTime, 
    required this.endTime,
  });

    Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'notes': notes,
    'location': location,
    'guests': guests,
    'startTime': startTime != null ? '${startTime!.hour}:${startTime!.minute}' : null,
    'endTime': endTime != null ? '${endTime!.hour}:${endTime!.minute}' : null,
  };

  static Event fromJson(Map<String, dynamic> json) {
    TimeOfDay? parseTime(String? time) {
      if (time == null) return null;
      final parts = time.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }
    return Event(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      notes: json['notes'] ?? '',
      location: json['location'] ?? '',
      guests: json['guests'] ?? '',
      startTime: parseTime(json['startTime']),
      endTime: parseTime(json['endTime']),
    );
  }

  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is Event &&
    runtimeType == other.runtimeType &&
    title == other.title &&
    description == other.description &&
    notes == other.notes &&
    location == other.location &&
    guests == other.guests &&
    startTime?.hour == other.startTime?.hour &&
    startTime?.minute == other.startTime?.minute &&
    endTime?.hour == other.endTime?.hour &&
    endTime?.minute == other.endTime?.minute;

@override
  int get hashCode => 
    title.hashCode ^
    description.hashCode ^
    notes.hashCode ^
    location.hashCode ^
    guests.hashCode ^
    (startTime?.hour.hashCode ?? 0) ^
    (startTime?.minute.hashCode ?? 0) ^
    (endTime?.hour.hashCode ?? 0) ^
    (endTime?.minute.hashCode ?? 0);


}