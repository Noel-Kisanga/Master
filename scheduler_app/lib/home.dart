import 'package:flutter/material.dart';
import 'package:scheduler_app/event.dart';
import 'package:scheduler_app/takephoto.dart';
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
  CalendarFormat _calendarFormat = CalendarFormat.month; // Default calendar format
  Map<DateTime, List<Event>> events = {}; // Stores the events by date
  RangeSelectionMode _rangeSelectionMode = RangeSelectionMode.toggledOff; // Range selection mode for calendar
  DateTime _focusedDay = DateTime.now(); // Currently focused day in the calendar
  DateTime? _selectedDay; // Currently selected day
  DateTime? _rangeStart; // Start of the selected range
  DateTime? _rangeEnd; // End of the selected range

  @override
  void initState() {
    super.initState();

    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!)); // Initialize selected events for the day
    loadPreviousEvents(); // Load previously saved events
  }

  @override
  void dispose() {
    _selectedEvents.dispose(); // Dispose of the ValueNotifier to free resources
    super.dispose();
  }

  /// Fetches the events for the specified day.
  List<Event> _getEventsForDay(DateTime day) {
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
        _rangeStart = null;
        _rangeEnd = null;
        _rangeSelectionMode = RangeSelectionMode.toggledOff; // Disable range selection
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

  /// Clears the text fields in the dialog.
  void clearController() {
    _titleController.clear();
    _descriptionController.clear();
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
                firstDay: DateTime.utc(2000, 12, 31), // Start date of the calendar
                lastDay: DateTime.utc(2030, 01, 01), // End date of the calendar
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                rangeStartDay: _rangeStart,
                rangeEndDay: _rangeEnd,
                calendarFormat: _calendarFormat,
                rangeSelectionMode: _rangeSelectionMode,
                eventLoader: _getEventsForDay, // Load events for the currently displayed day
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
                      children: value
                          .map((e) => Card(
                              color: Colors.white,
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 14),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Icon(
                                          Icons.check_box,
                                          color: Theme.of(context)
                                              .buttonTheme
                                              .colorScheme!
                                              .secondary,
                                        ),
                                        SizedBox(
                                          child: Column(
                                            children: [
                                              SizedBox(
                                                child: Column(
                                                  children: [
                                                    Text(
                                                      maxLines: 1,
                                                      style: const TextStyle(
                                                          fontWeight: FontWeight.w500,
                                                          fontSize: 16),
                                                      e.title,
                                                    ),
                                                    Padding(
                                                      padding: const EdgeInsets.all(8.0),
                                                      child: Text.rich(
                                                        TextSpan(
                                                          children: [
                                                            TextSpan(
                                                              style: const TextStyle(
                                                                  color: Colors.blue),
                                                              text: '${_selectedDay!.hour}: ${_selectedDay!.minute}: ',
                                                            ),
                                                            TextSpan(
                                                              text: e.description,
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(Icons.share),
                                      ],
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 10),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          textBtn(context, 'Search ride', () {}),
                                          textBtn(context, 'Cancel Event', () {
                                            setState(() {
                                              _selectedEvents.value.clear();
                                              _getEventsForDay;
                                            });
                                          }),
                                        ],
                                      ),
                                    ),
                                  ],
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
              onPressed: () {},
              child: const Text('Choose from Gallery'),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => _dialogWidget(context))
                );
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

  /// Displays a dialog for the user to input event details.
  /// 
  AlertDialog _dialogWidget(BuildContext context) {
    return AlertDialog.adaptive(
      scrollable: true,
      title: const Text('Event name'),
      content: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(helperText: 'Title'),
            ),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(helperText: 'ride'),
            ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
            onPressed: () {
              // Add the new event to the events map
              events.addAll({
                _selectedDay!: [
                  ..._selectedEvents.value,
                  Event(
                      title: _titleController.text,
                      description: _descriptionController.text)
                ]
              });
              _selectedEvents.value = _getEventsForDay(_selectedDay!); // Update the events for the selected day
              clearController(); // Clear the input fields
              Navigator.pop(context); // Close the dialog
            },
            child: const Text('Submit'))
      ],
    );
  }

  /// Loads previously saved events (currently hardcoded).
  void loadPreviousEvents() {
    events = {
      _selectedDay!: [Event(title: '', description: '')],
      _selectedDay!: [Event(title: '', description: '')]
    };
  }

  // Future method to load saved events from persistent storage (commented out)
  // _checkOnboardingCompleted() async {
  // SharedPreferences prefs = await SharedPreferences.getInstance();
  // return prefs.getStringList('key');
  //}
}
