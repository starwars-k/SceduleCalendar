import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart'; // The calendar widget
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:calendar_frontend/event_model.dart'; // The event model class
import 'package:intl/intl.dart';
import 'package:calendar_frontend/EventDetailPage.dart';
import 'package:flutter/cupertino.dart';

void main() => runApp(const MaterialApp(home: CalendarPage()));

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  // This widget is the root of your application.
  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _memoController = TextEditingController();
  String _eventType = 'Task'; //Default event type
  String _repeatType = 'Daily'; // Default repeat type
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  DateTime _startTime = DateTime.now(); // Default start time at now
  DateTime _endTime = DateTime.now().add(const Duration(hours: 1));
  bool _isAllDay = false; // New variable to track if the event is all-day
  bool _showStartTimePicker = false; // New variable to track if the start time picker should be shown
  bool _showEndTimePicker = false; // New variable to track if the end time picker should be shown
  bool _isLoading = false; // New variable to track if the app is loading data
  CalendarFormat _calendarFormat = CalendarFormat.month;
  List<DailyEvent> _events = [];
  List<DailyEvent> get _selectedEvents {
    final list = _events.where((event) {
      final dayStart = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day, 0, 0, 0);
      final dayEnd = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day, 23, 59, 59);
      return event.startTime.isBefore(dayEnd) && event.endTime.isAfter(dayStart);
    }).toList();
    list.sort((a, b) => a.startTime.compareTo(b.startTime)); // Sort events by start time
    return list;
  }
  final List<String> _eventTypes = ['Task', 'Job', 'Class', 'Birthday', 'Personal'];
  final List<String> _repeatOptions = ['Daily', 'Weekly', 'Biweekly', 'Monthly', 'Yearly'];
  bool _isRepeating = false;
  bool _endOn = false;
  DateTime _repeatEndDate = DateTime.now().add(const Duration(days: 1)); // Default repeat end date

  Color _getEventColor(String type){
    switch(type){
      case 'Task':
        return Colors.blueAccent;
      case 'Job':
        return Colors.greenAccent;
      case 'Class':
        return Colors.orangeAccent;
      case 'Birthday':
        return Colors.pinkAccent;
      case 'Personal':
        return Colors.purpleAccent;
      default:
        return Colors.grey;
    }
  }
  @override
  void initState() {
    super.initState();
    _isLoading = true; // Set loading state to true
    fetchEventsFromJava();// Load datafrom backend immediately
  }

  void _showAddEventDialog(BuildContext context, DateTime initialDate, {DailyEvent? eventToEdit}){
    final bool isEditing = eventToEdit != null;
    _titleController.text = isEditing ? eventToEdit.title : '';
    _isAllDay = isEditing ? eventToEdit.isAllDay : false; // Reset all-day checkbox
    _startTime = isEditing ? eventToEdit.startTime : DateTime(initialDate.year, initialDate.month, initialDate.day, DateTime.now().hour); // Default start time at current time
    _endTime = isEditing ? eventToEdit.endTime : _startTime.add(const Duration(hours: 1)); // Default end time
    _isRepeating = isEditing ? eventToEdit.isRepeating : false; // Reset repeating checkbox
    _repeatType = isEditing && eventToEdit.repeatType != null ? eventToEdit.repeatType! : 'None'; // Reset repeat type when opening the dialog
    _repeatOptions.contains(_repeatType) ? _repeatType : 'Daily'; // Reset repeat type to default if not in list
    _endOn = isEditing ? (eventToEdit.repeatEndOn != null) : false; // Reset end on checkbox
    _repeatEndDate = isEditing && eventToEdit.repeatEndOn != null ? eventToEdit.repeatEndOn! : initialDate.add(const Duration(days: 1)); // Reset repeat end date
    _memoController.text = isEditing ? eventToEdit.description : '';
    _eventType =  isEditing ? eventToEdit.eventType : 'Task'; // Reset event type to default if not in list

    final ScrollController modalScrollController = ScrollController();
    showModalBottomSheet(
      context:context,
      isScrollControlled: true,
      showDragHandle: false,
      backgroundColor: Colors.white,
      shape : const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.95, // Set height to 80% of screen height  
            child: Scaffold(
              backgroundColor: Colors.transparent, // Make the background transparent
              appBar: AppBar(
                title: const Text("Add New Event"),
                automaticallyImplyLeading: false, // Remove the default back button
                backgroundColor: Colors.transparent, // Make the AppBar transparent
                elevation: 0, // Remove shadow
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              body: Scrollbar(
                controller: modalScrollController,
                thumbVisibility: true,
                trackVisibility: true,
                child: SingleChildScrollView(
                  controller: modalScrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 40.0, left: 20.0, right: 20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    // 1. Event Title Input
                    children: [
                      TextField(
                        controller: _titleController,
                        decoration: const InputDecoration(hintText: "Event Title"),
                      ),
                      const SizedBox(height: 10),
                      // 2. Event Date Picker
                      TextButton.icon(
                        icon: const Icon(Icons.calendar_today),
                        label: Text("Select Date: ${DateFormat('yyyy-MM-dd').format(_selectedDay)}"),
                        onPressed: () async{
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDay,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if(picked != null){
                            setDialogState(() {
                              _selectedDay = picked;
                              _startTime = DateTime(picked.year, picked.month, picked.day, _startTime.hour, _startTime.minute);
                              _endTime = DateTime(picked.year, picked.month, picked.day, _endTime.hour, _endTime.minute);
                            });
                          }
                        },
                      ),
                      // 3. All-Day Event Checkbox
                      Row(
                        children: [
                          Checkbox(
                            value: _isAllDay,
                            onChanged: (bool? value) {
                              setDialogState(() {
                                _isAllDay = value ?? false;
                              });
                            },
                          ),
                          const Text("All-Day Event"),
                        ],
                      ),
                      if(!_isAllDay)...[
                        // 4. Start Time Picker
                        ListTile(
                          title: const Text("Start Time"),
                          trailing: Text(
                            '${_startTime.hour}:${_startTime.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              fontSize: 16,
                              color: _showStartTimePicker ? Colors.blue : Colors.black,
                              fontWeight: _showStartTimePicker ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          onTap: (){ 
                            setDialogState(() {
                              _showStartTimePicker = !_showStartTimePicker;
                              if(_showStartTimePicker){
                                _showEndTimePicker = false; // Close end time picker if open
                              }
                            });
                          },
                        ),
                        if(_showStartTimePicker)
                          Container(
                            height: 200,
                            color: CupertinoColors.systemBackground.resolveFrom(context),
                            child: CupertinoDatePicker(
                              mode: CupertinoDatePickerMode.time,
                              initialDateTime: _startTime,
                              use24hFormat: true,
                              onDateTimeChanged: (DateTime newDateTime) {
                                setDialogState(() {
                                  _startTime = DateTime(
                                    _startTime.year,
                                    _startTime.month,
                                    _startTime.day,
                                    newDateTime.hour,
                                    newDateTime.minute,
                                  );
                                });
                              },
                            ),
                          ),
                          const Divider(height: 1),
                          // 5. End Time Picker
                          ListTile(
                            title: const Text("End Time"),
                            trailing: Text(
                              '${_endTime.hour}:${_endTime.minute.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                fontSize: 16,
                                color: _showEndTimePicker ? Colors.blue : Colors.black,
                                fontWeight: _showEndTimePicker ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            onTap: () => setDialogState(() {
                              _showEndTimePicker = !_showEndTimePicker;
                              if(_showEndTimePicker){
                                _showStartTimePicker = false; // Close start time picker if open
                              }
                            }),
                          ),
                          if(_showEndTimePicker)
                            Container(
                              height: 200,
                              color: CupertinoColors.systemBackground.resolveFrom(context),
                              child: CupertinoDatePicker(
                                mode: CupertinoDatePickerMode.time,
                                initialDateTime: _endTime,
                                use24hFormat: true,
                                onDateTimeChanged: (DateTime newDateTime) {
                                  setDialogState(() {
                                    _endTime = DateTime(
                                    _endTime.year,
                                    _endTime.month,
                                    _endTime.day,
                                    newDateTime.hour,
                                    newDateTime.minute,
                                  );
                                });
                              },
                            ),
                          ),
                          const Divider(height:1),
                      ],
                      // 6. Repeat Event Checkbox
                      Row(
                        children: [
                          Checkbox(
                            value: _isRepeating,
                            onChanged: (bool? value) {
                              setDialogState(() {
                                _isRepeating = value ?? false;
                                if(_isRepeating && _repeatType == 'None'){
                                  _repeatType = 'Daily';
                                }else if(!_isRepeating){
                                  _repeatType = 'None';
                                }
                              });
                            },
                          ),
                          const Text("Repeat this event"),
                        ],
                      ),
                      // 7. Repeat Type Dropdown (only visible if repeating)
                      if(_isRepeating) ...[
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: _repeatType == 'None' ? 'Daily' : _repeatType, // Default to 'Daily' if 'None'
                          decoration: const InputDecoration(
                            labelText: "How often?",
                            border: OutlineInputBorder()
                          ),
                          items: ['Daily', 'Weekly', 'Biweekly', 'Monthly', 'Yearly'].map((option) =>
                            DropdownMenuItem<String>(
                              value: option,
                              child: Text(option),
                            )).toList(),
                          onChanged: (value) => setState(() {
                            _repeatType = value!;
                          }),
                        ),
                      ],
                      // 8. End On Checkbox (only visible if repeating)
                      if(_isRepeating)...[
                        Row(
                          children:[
                            Checkbox(
                              value: _endOn,
                              onChanged: (bool? value) {
                                setDialogState(() {
                                  _endOn = value ?? false;
                                });
                              },
                            ),
                            const Text("Set an end date for repeating"),
                          ]
                        ),
                      ],
                      // 9. Repeat End Date Picker (only visible if repeating and endOn is true)
                      if(_isRepeating && _endOn) ...[
                        TextButton.icon(
                          icon: const Icon(Icons.calendar_today),
                          label: Text("The repeat finishes on: ${DateFormat('yyyy-MM-dd').format(_repeatEndDate)}"),
                          onPressed: () async{
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: _repeatEndDate,
                              firstDate: DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day),
                              lastDate: DateTime(2100),
                            );
                            if(picked != null){
                              setDialogState(() {
                                _repeatEndDate = picked;
                              });
                            }
                          },
                        ),
                      ],
                      // 10. Memo/ Description Input
                      TextField(
                        controller: _memoController,
                        decoration: const InputDecoration(
                          labelText: "Memo/ Description",
                          prefixIcon: Icon(Icons.note),
                          border: OutlineInputBorder(),
                        )
                      ),
                      const SizedBox(height: 15),
                      // 11. Event Type Dropdown
                      DropdownButtonFormField<String>(
                        initialValue: _eventType,
                        decoration: const InputDecoration(labelText: "Event Type", prefixIcon: Icon(Icons.category), border: OutlineInputBorder()),
                        items: _eventTypes.map((String type){
                          return DropdownMenuItem<String>(
                            value: type, 
                            child: Text(type),
                          );
                        }).toList(),
                        onChanged: (String? newValue){
                          setDialogState(() {
                            _eventType = newValue!;
                          });
                        },
                      ),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Cancel"),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              if(_titleController.text.isNotEmpty){
                                if(!isEditing && eventToEdit != null && eventToEdit.id != null){
                                  _updateEvent(eventToEdit.id!, _startTime, _endTime);
                                }else{
                                  _saveBatchEvents(_startTime, _endTime);
                                }
                              }else{
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Event title cannot be empty!"))
                                );
                              }
                            },
                            child: Text(isEditing ? "Update" : "Save"),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            )
          ),
        )
      )
    );
  }

  /*
  void _showEventDetailDialog(BuildContext context, DailyEvent event){
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(event.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Memo: ${event.description.isEmpty ? "" : event.description}"),
            const SizedBox(height: 20),
            Text("Start Time: ${DateFormat('yyyy-MM-dd HH:mm').format(event.startTime)}"),
            const SizedBox(height: 20),
            Text("End Time: ${DateFormat('yyyy-MM-dd HH:mm').format(event.endTime)}"),
            const SizedBox(height: 20),
            Text("Type: ${event.eventType}"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
          TextButton.icon(
            icon: const Icon(Icons.delete, color: Colors.red),
            label: const Text("Delete", style: TextStyle(color: Colors.red)),
            onPressed: (){
              if(event.id != null){
                _deleteEvent(event.id!);
                Navigator.pop(context);
              }
            }
          )
        ],
      )
    );
  }
  */

  Future<void> fetchEventsFromJava() async {
    try{
      //final response = await http.get(Uri.parse('http://localhost:8080/api/events')); 
        final response = await http.get(Uri.parse('https://calendar-backend-qhny.onrender.com/api/events')); // Use the deployed backend URL
      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        if(!mounted) return; // Check if the widget is still mounted before calling setState
        setState(() {
          _events = body.map((dynamic item) => DailyEvent.fromJson(item)).cast<DailyEvent>().toList();
        });
      }
    }catch(e){
      print("FLUTTER ERROR: $e");
    }finally{
      if(!mounted) return; // Check if the widget is still mounted before calling setState
      setState(() {
        _isLoading = false; // Set loading state to false after fetching events
      });
    }
  }

  /*
  Future<void> _sendEventToJava(String title, DateTime pickedDate) async {
    DateTime endDate = pickedDate.add(const Duration(hours: 1));
    try{
      final response = await http.post(
        Uri.parse('http://localhost:8080/api/events'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': title,
          'description': '',
          'startTime': pickedDate.toIso8601String(),
          'endTime': endDate.toIso8601String(),
          'eventType': 'Default'
        }),
      );
      if(response.statusCode == 200 || response.statusCode == 201){
        print("Event saved successfully!");
        fetchEventsFromJava(); // Refresh the event list after adding
      }else{
        print("Failed to save event. Status code: ${response.statusCode}");
      }
    }catch(e){
      print("ERROR saving event: $e");
    }
  }
  */

  Future<void> _deleteEvent(int id) async{
    // print("Attempting to delete event with ID: $id");
    try{
      final response = await http.delete(
        //Uri.parse('http://localhost:8080/api/events/$id'),
        Uri.parse('https://calendar-backend-qhny.onrender.com/api/events/$id'), // Use the deployed backend URL
      );
      if(response.statusCode == 200 || response.statusCode == 201){
        fetchEventsFromJava(); // Refresh the event list after deleting
      }else{
        print("Failed to delete event. Status code: ${response.statusCode}");
      }
    }catch(e){
      print("ERROR deleting event: $e");
    }
  }

  String _formatToBackendIso(DateTime dateTime){
    String base = dateTime.toIso8601String().split('.')[0];
    String ms = (dateTime.millisecond).toString().padLeft(3, '0');// Ensure milliseconds are always 3 digits
    return '$base.$ms';
  }

  Future<void> _saveBatchEvents(DateTime startTime, DateTime endTime) async {
    try{
      final Map<String, dynamic> eventData ={
        'title': _titleController.text,
        'description': _memoController.text,
        'startTime': _formatToBackendIso(startTime),
        'endTime': _formatToBackendIso(endTime),
        'eventType': _eventType,
        'isAllDay': _isAllDay,
        'isRepeating': _isRepeating,
        'repeatType': _isRepeating ? _repeatType : 'None',
        'endOn': _isRepeating ? _endOn : false,
        'repeatEndOn': _isRepeating && _endOn ? _formatToBackendIso(_repeatEndDate) : null,
      };

      print("Sending event to server: $eventData");

      final response = await http.post(
        //Uri.parse('http://localhost:8080/api/events/batch'),
        Uri.parse('https://calendar-backend-qhny.onrender.com/api/events/'), // Use the deployed backend URL
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(eventData),
      );
      if(response.statusCode == 200 || response.statusCode == 201){
        fetchEventsFromJava(); // Refresh the event list after batch saving
        Navigator.pop(context);
      }else{
        print("Failed to save batch events. Status code: ${response.statusCode}");
        print("Response body: ${response.body}");
      }
    }catch(e){
      print("EXCEPTION caught while saving batch events: $e");
    }
  }

  Future<void> _updateEvent(int id, DateTime startTime, DateTime endTime) async {
    try{
      final Map<String, dynamic> eventData = {
        'title': _titleController.text,
        'description': _memoController.text,
        'startTime': _formatToBackendIso(startTime),
        'endTime': _formatToBackendIso(endTime),
        'eventType': _eventType,
        'isAllDay': _isAllDay,
        'isRepeating': _isRepeating,
        'repeatType': _isRepeating ? _repeatType : 'None',
        'endOn': _isRepeating ? _endOn : false,
        'repeatEndOn': _isRepeating && _endOn ? _formatToBackendIso(_repeatEndDate) : null,
      };

      print("Updating event with ID $id: $eventData");

      final response = await http.put(
        //Uri.parse('http://localhost:8080/api/events/$id'),
        Uri.parse('https://calendar-backend-qhny.onrender.com/api/events/$id'), // Use the deployed backend URL
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(eventData),
      );
      if(response.statusCode == 200 || response.statusCode == 204){
        if(!mounted) return; // Check if the widget is still mounted before calling setState
        fetchEventsFromJava(); // Refresh the event list after updating
        Navigator.pop(context);
      }else{
        print("Failed to update event. Status code: ${response.statusCode}");
        print("Response body: ${response.body}");
      }
    }catch(e){
      print("EXCEPTION caught while updating event: $e");
    }
  }

  //iOS style date picker for selecting the repeat end date
  Future<TimeOfDay?> _showAppleStyleTimePicker(
    BuildContext context,
    DateTime initialDateTime,
  ) async {
    DateTime selected = initialDateTime;
    return await showModalBottomSheet<TimeOfDay>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(100.0)),
      ),
      builder: (BuildContext builderContext) {
        return Container(
          height: 900,
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: const Text('Cancel'),
                    onPressed: () {
                      Navigator.of(builderContext).pop();
                    },
                  ),
                  CupertinoButton(
                    child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () {
                      Navigator.of(builderContext).pop(
                        TimeOfDay(hour: selected.hour, minute: selected.minute),
                      ); 
                    },
                  ),
                ],
              ),
              const Divider(height: 0),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: initialDateTime,
                  use24hFormat: true,
                  onDateTimeChanged: (DateTime newDateTime) {
                    selected = newDateTime;
                  },
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule Calendar'),
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2000, 1, 1),
            lastDay: DateTime.utc(2100, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: (day){
                final dayStart = DateTime(day.year, day.month, day.day, 0, 0, 0);
                final dayEnd = DateTime(day.year, day.month, day.day, 23, 59, 59);
                return _events.where((event) => event.startTime.isBefore(dayEnd) && event.endTime.isAfter(dayStart)).toList();
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay; // update `_focusedDay` here as well
              });
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isEmpty) return const SizedBox();
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: events.take(3).map((event){
                    final dailyEvent = event as DailyEvent;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 0.5),
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _getEventColor(dailyEvent.eventType),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            onHeaderTapped: (focusedDay) async{
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: focusedDay,
                firstDate: DateTime(2000, 1, 1),
                lastDate: DateTime(2100, 12, 31),
              );
              if(picked != null){
                setState((){
                  _focusedDay = picked;
                  _selectedDay = picked;
                });
              }
            },
          ),
          const SizedBox(height: 8.0),
          Expanded(
            child: _isLoading ? const Center(
              child: CircularProgressIndicator(),
            )
            : ListView.builder(
              itemCount: _selectedEvents.length,
              itemBuilder: (context, index) {
                final event = _selectedEvents[index];
                return ListTile(
                  leading: Icon(Icons.event, color: _getEventColor(event.eventType)),
                  title: Text(event.title),
                  subtitle: Text(
                    event.isAllDay
                      ? "All-Day"
                      :"${DateFormat('MMM d, HH:mm').format(event.startTime)} - ${DateFormat('MMM d, HH:mm').format(event.endTime)}",
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EventDetailPage(
                          event: event, 
                          onDelete: (id) => _deleteEvent(id), 
                          onUpdate: () => fetchEventsFromJava()
                        ),
                      )
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children:[
            FloatingActionButton.extended(
              onPressed: () {
                setState((){
                  _focusedDay = DateTime.now();
                  _selectedDay = DateTime.now();
                });
              },
              label: const Text("TODAY"),
              icon: const Icon(Icons.today),
              backgroundColor: Colors.white,
              foregroundColor: Colors.blue,
            ),
            FloatingActionButton(
              onPressed: () => _showAddEventDialog(context, _selectedDay),
              child: const Icon(Icons.add),
            )
          ]
        )
      ),
    );
  }
}