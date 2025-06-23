import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'event.dart';

class EventStorage {
  static Future<void> saveEvents(Map<DateTime, List<Event>> events) async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> data = {};
    events.forEach((date, eventList) {
      final key = date.toIso8601String();
      data[key] = eventList.map((e) => e.toJson()).toList();
    });
    await prefs.setString('events', jsonEncode(data));
  }

  static Future<Map<DateTime, List<Event>>> loadEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('events');
    if (jsonString == null) return {};
    final Map<String, dynamic> data = jsonDecode(jsonString);
    final Map<DateTime, List<Event>> events = {};
    data.forEach((key, value) {
      final date = DateTime.parse(key);
      final eventList = (value as List).map((e) => Event.fromJson(e)).toList();
      events[date] = eventList.cast<Event>();
    });
    return events;
  }
}