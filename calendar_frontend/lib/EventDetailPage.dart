import 'package:flutter/material.dart';
import 'package:calendar_frontend/event_model.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EventDetailPage extends StatefulWidget {
  final DailyEvent event;
  final Function() onUpdate;
  final Function(int) onDelete;

  const EventDetailPage({
    super.key, 
    required this.event, 
    required this.onDelete,
    required this.onUpdate,
  });

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  late TextEditingController _titleController;
  late TextEditingController _memoController;
  late String _eventType;
  late DateTime _startTime;
  late DateTime _endTime;
  late bool _isAllDay;
  bool _isRepeating = false;
  String _repeatType = 'None';
  DateTime _repeatEndDate = DateTime.now();
  bool _endOn = false;

  final List<String> _types = ["Task", "Job", "Class", "Birthday", "Personal"];
  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.event.title);
    _memoController = TextEditingController(text: widget.event.description);
    _isAllDay = widget.event.isAllDay;
    if(widget.event.repeatType != null && widget.event.repeatType != 'None'){
      _eventType = widget.event.eventType;
      _isRepeating = true;
      _repeatType = widget.event.repeatType!;
    } else {
      _eventType = _types.first;
      _isRepeating = false;
      _repeatType = 'None';
    }
    _startTime = widget.event.startTime;
    _endTime = widget.event.endTime;
  }

  Future<void> _updateEvent() async {
    final response = await http.put(
      //Uri.parse('http://localhost:8080/api/events/${widget.event.id}'),
      Uri.parse('https://calendar-backend-qhny.onrender.com/api/events/${widget.event.id}'), // Use the deployed backend URL
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': _titleController.text,
        'description': _memoController.text,
        'eventType': _eventType,
        'startTime': _startTime.toIso8601String(),
        'endTime': _endTime.toIso8601String(),
        'isAllDay': _isAllDay,
      }),
    );
    if (response.statusCode == 200) {
      widget.onUpdate();
      Navigator.pop(context);
    } 
  }

  Future<void> _manualSave() async{
    if(widget.event.id == null){
      print("Error: Event ID is null. Cannot update.");
      return;
    }
    try{
      final response = await http.put(
        //Uri.parse('http://localhost:8080/api/events/${widget.event.id}'),
        Uri.parse('https://calendar-backend-qhny.onrender.com/api/events/${widget.event.id}'), // Use the deployed backend URL
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': _titleController.text,
          'description': _memoController.text,
          'eventType': _eventType,
          'startTime': _startTime.toIso8601String(),
          'endTime': _endTime.toIso8601String(),
          'isAllDay': _isAllDay,
        }),
      );
      if (response.statusCode == 200) {
        widget.onUpdate();
        Navigator.pop(context);
      } else {
        print("Server Error: ${response.statusCode}");
        print("Body: ${response.body}");
      }
    } catch (e) {
      print("Connection Error: $e");
    }
  }

  Future<void> _pickDatetime({required bool isStart}) async {
    DateTime initialDate = isStart ? _startTime : _endTime;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate == null) return;
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );
    if (pickedTime == null) return;
    setState(() {
      DateTime finalDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
      if (isStart) {
        _startTime = finalDateTime;
        if (_endTime.isBefore(_startTime)) {
          _endTime = _startTime.add(const Duration(hours: 1));
        }
      } else {
        _endTime = finalDateTime;
        if (_startTime.isAfter(_endTime)) {
          _startTime = _endTime.subtract(const Duration(hours: 1));
        }
      }
    });
  }

  Future<void> _deleteSingleEvent() async {
    try{
      final response = await http.delete(
        //Uri.parse('http://localhost:8080/api/events/${widget.event.id}'),
        Uri.parse('https://calendar-backend-qhny.onrender.com/api/events/${widget.event.id}'), // Use the deployed backend URL
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        widget.onDelete(widget.event.id!);
        Navigator.pop(context);
        Navigator.pop(context);
      } else {
        print("Failed to delete event: ${response.statusCode}");
      }
    } catch (e) {
      print("Connection Error: $e");
    }
  }

  Future<void> _deleteFutureEvents() async {
    try{
      final response = await http.delete(
        //Uri.parse('http://localhost:8080/api/events/${widget.event.id}'),
        Uri.parse('https://calendar-backend-qhny.onrender.com/api/events/future/${widget.event.id}'), // Use the deployed backend URL
        );
        if (response.statusCode == 200 || response.statusCode == 204) {
          widget.onDelete(widget.event.id!);
          Navigator.pop(context);
        } else {
          print("Failed to delete future events: ${response.statusCode}");
        }
      } catch (e) {
        print("Connection Error: $e");
      }
    }

    void _onDeleteButtonPressed(){
      bool isSeriesEvent = widget.event.isRepeating == true && widget.event.seriesId != null;
      if(isSeriesEvent){
        showDialog(
          context: context,
          builder: (BuildContext context){
            return AlertDialog(
              title: const Text("Delete Event"),
              actions: [
                TextButton(
                  onPressed: (){
                    Navigator.pop(context);
                    _deleteSingleEvent();
                  },
                  child: const Text("Delete this event only", style: TextStyle(color: Colors.red)),
                ),
                TextButton(
                  onPressed: (){
                    Navigator.pop(context);
                    _deleteFutureEvents();
                  },
                  child: const Text("Delete all future events", style: TextStyle(color: Colors.red)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
              ],
            );
          },
        );
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context){
            return AlertDialog(
              title: const Text("Delete Event"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: (){
                    Navigator.pop(context);
                    _deleteSingleEvent();
                  },
                  child: const Text("Delete", style: TextStyle(color: Colors.red)),
                ),
              ],
            );
          },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Event Details"),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.check, size: 28, color: Colors.blue),
            onPressed: _manualSave,
          ),
          IconButton(
            icon: Icon(Icons.delete, size: 28, color: Colors.red.shade400),
            onPressed: _onDeleteButtonPressed,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Title
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: "Title", border: OutlineInputBorder()),
          ),
          const SizedBox(height: 20),
          const Text("Schedule", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          // 2. All-Day Checkbox
          CheckboxListTile(
            title: const Text("All-Day Event"),
            value: _isAllDay,
            onChanged: (bool? value) {
              setState(() {
                _isAllDay = value ?? false;
              });
            },
          ),
          if(!_isAllDay)ListTile(
            title : Text("Start Time: ${_startTime.hour}:${_startTime.minute.toString().padLeft(2,'0')}"),
            trailing: const Icon(Icons.edit),
            onTap: () async{
              final time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(_startTime),
              );
              if(time != null){
                setState(() {
                  _startTime = DateTime(_startTime.year, _startTime.month, _startTime.day, time.hour, time.minute);
                });
              }
            },
          ),
          if(!_isAllDay)ListTile(
            title : Text("End Time: ${_endTime.hour}:${_endTime.minute.toString().padLeft(2,'0')}"),
            trailing: const Icon(Icons.edit),
            onTap: () async{
              final time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(_endTime),
              );
              if(time != null){
                setState(() {
                  _endTime = DateTime(_endTime.year, _endTime.month, _endTime.day, time.hour, time.minute);
                });
              }
            },
          ),
          const SizedBox(height: 20),
          Row(
            // 5. Repeat Checkbox
            children: [
              Expanded(
                child: CheckboxListTile(
                  title: const Text("Repeating"),
                  value: _isRepeating,
                  onChanged: (bool? value) {
                    setState(() {
                      _isRepeating = value ?? false;
                      if(_isRepeating && _repeatType == 'None'){
                        _repeatType = 'Daily';
                      }else if(!_isRepeating){
                        _repeatType = 'None';
                      }
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // 6. Repeat Type Dropdown (only visible if repeating)
          if(_isRepeating) ...[
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
                      // 7. End On Checkbox (only visible if repeating)
                      if(_isRepeating)...[
                        Row(
                          children:[
                            Checkbox(
                              value: _endOn,
                              onChanged: (bool? value) {
                                setState(() {
                                  _endOn = value ?? false;
                                });
                              },
                            ),
                            const Text("Set an end date for repeating"),
                          ]
                        ),
                      ],
                      // 8. Repeat End Date Picker (only visible if repeating and endOn is true)
                      if(_isRepeating && _endOn) ...[
                        TextButton.icon(
                          icon: const Icon(Icons.calendar_today),
                          label: Text("The repeat finishes on: ${DateFormat('yyyy-MM-dd').format(_repeatEndDate)}"),
                          onPressed: () async{
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: _repeatEndDate,
                              firstDate: DateTime(widget.event.startTime.year, widget.event.startTime.month, widget.event.startTime.day),
                              lastDate: DateTime(2030),
                            );
                            if(picked != null){
                              setState(() {
                                _repeatEndDate = picked;
                              });
                            }
                          },
                        ),
                      ],
          // 8. Memo
          TextField(
            controller: _memoController,
            decoration: const InputDecoration(
              labelText: "Memo", 
              border: OutlineInputBorder(),
            ),
            maxLines: 1,
          ),
          const SizedBox(height: 20),
          // 9. Event Type Dropdown
          DropdownButtonFormField<String>(
            value: widget.event.eventType.isNotEmpty ? widget.event.eventType : _types.first,
            decoration: const InputDecoration(labelText: "Event Type", border: OutlineInputBorder()),
            items: _types.map((String type){
              return DropdownMenuItem<String>(
                value: type, 
                child: Text(type),
              );
            }).toList(),
            onChanged: (String? newValue){
              if(newValue != null){
                setState(() {
                  _eventType = newValue;
                });
              }
            },
          ),
        ]            
      ),
    );
  } 
  /*
  Color _getEventColor(String type){
    switch(type){
      case "Task": return Colors.blueAccent;
      case "Job": return Colors.greenAccent;
      case "Class": return Colors.orangeAccent;
      case "Birthday": return Colors.pinkAccent;
      case "Personal": return Colors.purpleAccent;
      default: return Colors.grey;
    }
  }*/
}