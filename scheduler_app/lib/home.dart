
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:scheduler_app/event.dart';
import 'package:scheduler_app/EventDetails.dart';
import 'package:scheduler_app/event_storage.dart';
import 'package:scheduler_app/gallery.dart';
import 'package:scheduler_app/takephoto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

/// The main screen widget of the app which displays the calendar and events.
class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late final ValueNotifier<List<Event>> _selectedEvents;
  Map<DateTime, List<Event>> events = {};
  CalendarFormat _calendarFormat = CalendarFormat.month; // Default calendar format
  RangeSelectionMode _rangeSelectionMode = RangeSelectionMode.toggledOff; // Range selection mode for calendar
  DateTime _focusedDay = DateTime.now(); // Currently focused day in the calendar
  DateTime? _selectedDay; // Currently selected day
  DateTime? _rangeStart; // Start of the selected range
  DateTime? _rangeEnd; // End of the selected range

  @override
  void initState(){
    super.initState();
    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!)); // Initialize selected events for the day
    _loadEvents(); // Load previously saved events
  }

  Future<void> _loadEvents() async {
    final loadedEvents = await EventStorage.loadEvents();
    setState(() {
      events = loadedEvents; // Set the loaded events to the state
      _selectedEvents.value = _getEventsForDay(_selectedDay!); // Update selected events for the initially selected day
    });
  }

  @override
  void dispose() {
    _selectedEvents.dispose(); // Dispose of the ValueNotifier to free resources
    super.dispose();
  }

  DateTime normalizeDate(DateTime date){
    return DateTime(date.year, date.month, date.day);
  }

  /// Fetches the events for the specified day.
  List<Event> _getEventsForDay(DateTime day) {
    print('Loading events for day: ${events[normalizeDate(day)]}');
    final normalizedDay = normalizeDate(day);
    return events[day] ?? []; // Return events for the day or an empty list if none exist
  }

  /// Generates a list of all days between the start and end date.
  List<DateTime> daysInRange(DateTime start, DateTime end) {
    final days = <DateTime>[];
    for (int i = 0; i <= end.difference(start).inDays; i++) {
      days.add(DateTime(start.year, start.month, start.day + i));
    }
    return days;
  }

  /// Fetches all events within a specified range of days.
  List<Event> _getEventsForRange(DateTime start, DateTime end) {
    final days = daysInRange(start, end);
    return [
      for (final day in days) ..._getEventsForDay(day),
    ];
  }

  /// Handles the logic when a day is selected in the calendar.
  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        //_rangeStart = null;
       // _rangeEnd = null;
        //_rangeSelectionMode = RangeSelectionMode.toggledOff; // Disable range selection
      });
      _selectedEvents.value = _getEventsForDay(selectedDay); // Update the selected events
    }
  }

  /// Handles the logic when a range of days is selected in the calendar.
  void _onRangeSelected(DateTime? start, DateTime? end, DateTime focusedDay) {
    setState(() {
      _selectedDay = null;
      _focusedDay = focusedDay;
      _rangeStart = start!;
      _rangeEnd = end;
      _rangeSelectionMode = RangeSelectionMode.toggledOn; // Enable range selection
    });

    // Update the selected events based on the range
    if (start != null && end != null) {
      _selectedEvents.value = _getEventsForRange(start, end);
    } else if (start != null) {
      _selectedEvents.value = _getEventsForDay(start);
    } else if (end != null) {
      _selectedEvents.value = _getEventsForDay(end);
    }
  }

  // TextEditingController for managing the title input in the dialog
  final _titleController = TextEditingController();
  // TextEditingController for managing the description input in the dialog
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();
  final _locationController = TextEditingController();

  /// Clears the text fields in the dialog.
  void clearController() {
    _titleController.clear();
    _descriptionController.clear();
    _notesController.clear();
    _locationController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                child: Text(
                  textAlign: TextAlign.center,
                  DateFormat('MMMM yyyy').format(_selectedDay!), // Display current month and year
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Calendar widget
              TableCalendar(
                headerStyle: HeaderStyle(
                  formatButtonDecoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(),
                    color: Theme.of(context).colorScheme.tertiaryContainer,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onInverseSurface,
                  ),
                ),
                firstDay: DateTime.utc(1900, 12, 31), // Start date of the calendar
                lastDay: DateTime.utc(2050, 12, 31), // End date of the calendar
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                rangeStartDay: _rangeStart,
                rangeEndDay: _rangeEnd,
                calendarFormat: _calendarFormat,
                rangeSelectionMode: _rangeSelectionMode,
                eventLoader: (day) => _getEventsForDay(day), // Load events for the currently displayed day
                startingDayOfWeek: StartingDayOfWeek.monday, // Set the starting day of the week
                calendarStyle: CalendarStyle(
                  markerDecoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).colorScheme.secondaryContainer),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  selectedDecoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.onTertiaryContainer,
                  ),
                  todayDecoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.onTertiaryContainer,
                  ),
                  outsideDaysVisible: false, // Hide the outside days
                ),
                onDaySelected: _onDaySelected, // Callback for when a day is selected
                onRangeSelected: _onRangeSelected, // Callback for when a range is selected
                onFormatChanged: (format) {
                  if (_calendarFormat != format) {
                    setState(() {
                      _calendarFormat = format; // Change calendar format (e.g., Month, Week)
                    });
                  }
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay; // Update the focused day when page changes
                },
              ),
              const SizedBox(height: 10.0),

              // Container for displaying the list of selected events
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onInverseSurface,
                ),
                child: ValueListenableBuilder(
                  builder: (context, value, _) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: (value as List)
                        .map<Widget>((e) => GestureDetector(
                          onTap: () {
                          showDialog(
                            context: context, 
                            builder: (context) => AlertDialog(
                            title: Text(e.title),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                              Text('Description: ${e.description}'),
                              Text('Notes: ${e.notes}'),
                              Text('Location: ${e.location}'),
                              Text('Guests: ${e.guests}'),
                              if (e.startTime != null && e.endTime != null)
                                Text('Time: ${e.startTime!.format(context)} - ${e.endTime!.format(context)}'),
                              ],
                            ),
                            actions: [
                              TextButton(
                                style: TextButton.styleFrom(
                                  textStyle: Theme.of(context).textTheme.labelMedium
                                ),
                                child: const Text('Edit'),
                                onPressed: () {
                                  Navigator.pop(context);
                                  _showEditEventDialog(e, _selectedDay!);
                                },
                              ),
                              TextButton(
                                style: TextButton.styleFrom(
                                  textStyle: Theme.of(context).textTheme.labelMedium
                                ),
                                onPressed: () async {
                                  final normalizedDay = normalizeDate(_selectedDay!);
                                  setState(() {
                                    events[normalizedDay]?.remove(e);
                                    if (events[normalizedDay]?.isEmpty ?? false){
                                      events.remove(normalizedDay); // Remove the day if no events left
                                    }
                                    _selectedEvents.value = _getEventsForDay(_selectedDay!); // Remove the event from the list
                                  });
                                  await EventStorage.saveEvents(events);
                                  Navigator.pop(context); // Close the dialog
                                }, 
                                child: const Text('Delete'),
                              ),
                            ],
                            ),
                          );
                          },
                          child: Card(
                          color: Colors.white,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 14),
                            decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            ),
                            child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                              e.title, 
                              style: const TextStyle(
                                fontSize: 18, 
                                fontWeight: FontWeight.bold,
                              ),
                              ),
                              const SizedBox(height: 4),
                              Text('Description: ${e.description}'),
                              Text('Notes: ${e.notes}'),
                              Text('Location: ${e.location}'),
                              Text('Attendants: ${e.guests}'),
                              if (e.startTime != null && e.endTime != null)
                              Text(
                                'Time: ${e.startTime!.format(context)} - ${e.endTime!.format(context)}',
                              ),
                            ],
                            ),
                          ),
                          ),
                        ))
                        .toList(),
                    );
                  },
                  valueListenable: _selectedEvents, // Listens for changes to the selected events
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showOptions(context),
          label: const Text('Add Events'),
          icon: const Icon(Icons.add),
        ),
      ),
    );
  }

  /// Creates a text button with the specified text and callback.
  Widget textBtn(BuildContext context, String text, VoidCallback voidCallback) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ElevatedButton(
        onPressed: () {
          voidCallback();
        },
        child: Text(
          text,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  //Displays a dialog for the user to choose events
  Future<void> _showOptions(BuildContext ctx) async {
    showDialog(
      context: ctx, 
      builder: (_){
        return SimpleDialog(
          title: const Text('How would you like to add events?'),
          children: [
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TakePhoto())
                );
              },
              child: const Text('Take a Photo'),
            ),
            SimpleDialogOption(
              onPressed: () async {
                Navigator.pop(ctx);
                Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (context) => const Gallery())
                );
              },
              child: const Text('Choose from Gallery'),
            ),
            SimpleDialogOption(
              onPressed: () async {
                Navigator.pop(ctx);
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EventDetails(
                      selectedDay: _selectedDay!, 
                      events: events,
                    ),
                  ),
                );
                setState(() { 
                  _selectedEvents.value = _getEventsForDay(_selectedDay!);// Refresh the selected events after adding a new event
                });
              },
              child: const Text('Add manually'),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(ctx);
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }


void _showEditEventDialog(Event event, DateTime eventDay) {
  final titleController = TextEditingController(text: event.title);
  final descriptionController = TextEditingController(text: event.description);
  final notesController = TextEditingController(text: event.notes);
  final locationController = TextEditingController(text: event.location);
  final guestsController = TextEditingController(text: event.guests);
  TimeOfDay? startTime = event.startTime;
  TimeOfDay? endTime = event.endTime;

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Edit Event'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(labelText: 'Notes'),
            ),
            TextField(
              controller: locationController,
              decoration: const InputDecoration(labelText: 'Location'),
            ),
            TextField(
              controller: guestsController,
              decoration: const InputDecoration(labelText: 'Guests'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final TimeOfDay? picked = await showTimePicker(
                        context: context,
                        initialTime: startTime ?? TimeOfDay.now(),
                      );
                      if (picked != null) {
                        setState(() {
                          startTime = picked;
                        });
                      }
                    },
                    child: Text(
                      startTime != null
                          ? 'Start: ${startTime!.format(context)}'
                          : 'Select Start Time',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final TimeOfDay? picked = await showTimePicker(
                        context: context,
                        initialTime: endTime ?? TimeOfDay.now(),
                      );
                      if (picked != null) {
                        setState(() {
                          endTime = picked;
                        });
                      }
                    },
                    child: Text(
                      endTime != null
                          ? 'End: ${endTime!.format(context)}'
                          : 'Select End Time',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            setState(() {
              event.title = titleController.text;
              event.description = descriptionController.text;
              event.notes = notesController.text;
              event.location = locationController.text;
              event.guests = guestsController.text;
              event.startTime = startTime;
              event.endTime = endTime;
            });
            _selectedEvents.value = _getEventsForDay(eventDay);
            await EventStorage.saveEvents(events); // Save the updated events
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}


}
