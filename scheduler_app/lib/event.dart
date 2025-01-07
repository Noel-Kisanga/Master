import 'package:flutter/src/material/time.dart';

class Event{
  late String title;
  late String description;
  late String notes;
  late String location;
  late String guests;
  TimeOfDay? startTime;
  TimeOfDay? endTime;


  Event({
    required this.title,
    required this.description, 
    required String notes, 
    required String location,
    required String guests, 
    TimeOfDay? startTime, 
    TimeOfDay? endTime,
  });



}