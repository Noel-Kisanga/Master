import 'package:flutter/material.dart';
import 'package:scheduler_app/event.dart';
import 'package:table_calendar/table_calendar.dart';
import 'event_storage.dart';


class EventDetails extends StatefulWidget {
  final DateTime selectedDay;
  final Map<DateTime, List<Event>> events;

  const EventDetails({
    super.key, 
    required this.selectedDay,
    required this.events,
  });

  @override
  State<EventDetails> createState() => _EventDetailsState();
}

class _EventDetailsState extends State<EventDetails> {

  late final ValueNotifier<List<Event>> _selectedEvents;
  TimeOfDay? startTime;
  TimeOfDay? endTime;

  // TextEditingControllers for managing input fields
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _guestController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedEvents = ValueNotifier(_getEventsForDay(widget.selectedDay));
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    _locationController.dispose();
    _guestController.dispose();
    super.dispose();
  }

  List<Event> _getEventsForDay(DateTime day) {
    final normalizedDay = normalizeDate(day);
    return widget.events[normalizedDay] ?? [];
  }

  /// Clears the text fields in the dialog.
  void clearControllers() {
    _titleController.clear();
    _descriptionController.clear();
    _notesController.clear();
    _locationController.clear();
    _guestController.clear();
    setState(() {
      startTime = null;
      endTime = null;
    });
  }

  /// Shows the add event dialog
  Future<void> _showAddEventDialog() async {
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Event'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title Field
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Title is required';
                      }
                      return null;
                    },
                  ),
                  // Description Field
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                  // Notes Field
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(labelText: 'Notes'),
                  ),
                  // Location Field
                  TextFormField(
                    controller: _locationController,
                    decoration: const InputDecoration(labelText: 'Location'),
                  ),
                  TextFormField(
                    controller: _guestController,
                    decoration: const InputDecoration(labelText: 'Attendants'),
                  ),
                  const SizedBox(height: 16),
                  // Time Pickers
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
          ),
          actions: [
            TextButton(
              onPressed: () {
                clearControllers();
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  _addEvent();
                  await EventStorage.saveEvents(widget.events); // Assuming you have a method to save events
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  /// Adds a new event to the events map
  void _addEvent() {
    try{
      final newEvent = Event(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        notes: _notesController.text.trim(),
        location: _locationController.text.trim(),
        guests: _guestController.text.trim(),
        startTime: startTime,
        endTime: endTime,
      );

      final normalizedDay = normalizeDate(widget.selectedDay);

      setState(() {
        if (widget.events.containsKey(normalizedDay)) {
          widget.events[normalizedDay]!.add(newEvent);
        } else {
          widget.events[normalizedDay] = [newEvent];
        }
        _selectedEvents.value = widget.events[normalizedDay]!;
      });

      clearControllers();
    } catch (e, stackTrace){
      print('Error adding event: $e');
      print('StackTrace: $stackTrace');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddEventDialog,
            tooltip: 'Add Event',
          ),
        ],
      ),
      body: ValueListenableBuilder<List<Event>>(
        valueListenable: _selectedEvents,
        builder: (context, events, _) {
          if (events.isEmpty) {
            return const Center(
              child: Text('No events for this day.'),
            );
          }
          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Description: ${event.description}'),
                      Text('Notes: ${event.notes}'),
                      Text('Location: ${event.location}'),
                      Text('Attendants: ${event.guests}'),
                      if (event.startTime != null && event.endTime != null)
                        Text(
                          'Time: ${event.startTime!.format(context)} - ${event.endTime!.format(context)}',
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
