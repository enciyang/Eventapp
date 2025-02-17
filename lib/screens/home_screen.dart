import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {
  final String loggedInUser;

  const HomeScreen({Key? key, required this.loggedInUser}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _venueController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String _selectedCategory = "Workshop";
  final List<String> _categories = [
    "Workshop", "Sports", "Education", "Fun", "Music", "Tech", "Business", "Social"
  ];
  List<dynamic> _hostEvents = [];

  @override
  void initState() {
    super.initState();
    fetchHostEvents();
  }

  Future<void> fetchHostEvents() async {
    try {
      final response = await http.get(Uri.parse('http://10.0.2.2:3001/events'));
      if (response.statusCode == 200) {
        List<dynamic> allEvents = jsonDecode(response.body);
        setState(() {
          _hostEvents = allEvents.where((event) =>
          event['host']?.toLowerCase() == widget.loggedInUser.toLowerCase()
          ).toList();
        });
      }
    } catch (e) {
      print("Error fetching host events: $e");
    }
  }

  Future<void> _createEvent() async {
    if (_titleController.text.isEmpty ||
        _dateController.text.isEmpty ||
        _timeController.text.isEmpty ||
        _venueController.text.isEmpty ||
        _descriptionController.text.isEmpty) {
      return;
    }

    Map<String, dynamic> newEvent = {
      "title": _titleController.text,
      "date": _dateController.text,
      "time": _timeController.text,
      "venue": _venueController.text,
      "description": _descriptionController.text,
      "category": _selectedCategory,
      "host": widget.loggedInUser,
    };

    final response = await http.post(
      Uri.parse('http://10.0.2.2:3001/events'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(newEvent),
    );

    if (response.statusCode == 200) {
      fetchHostEvents(); // Refresh events after creation
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Event Created Successfully!")),
      );
    }
  }

  Future<void> _deleteEvent(int eventId) async {
    final response = await http.delete(Uri.parse('http://10.0.2.2:3001/events/$eventId'));
    if (response.statusCode == 200) {
      fetchHostEvents();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Event Deleted Successfully!")),
      );
    }
  }

  Future<void> _editEvent(int eventId, Map<String, dynamic> updatedEvent) async {
    final response = await http.put(
      Uri.parse('http://10.0.2.2:3001/events/$eventId'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(updatedEvent),
    );

    if (response.statusCode == 200) {
      fetchHostEvents();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Event Updated Successfully!")),
      );
    }
  }


  void _showEditEventDialog(Map<String, dynamic> event) {
    _titleController.text = event['title'];
    _dateController.text = event['date'];
    _timeController.text = event['time'];
    _venueController.text = event['venue'];
    _descriptionController.text = event['description'];
    _selectedCategory = event['category'];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Event"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: _titleController, decoration: const InputDecoration(labelText: "Title")),
                TextField(controller: _dateController, decoration: const InputDecoration(labelText: "Date")),
                TextField(controller: _timeController, decoration: const InputDecoration(labelText: "Time")),
                TextField(controller: _venueController, decoration: const InputDecoration(labelText: "Venue")),
                TextField(controller: _descriptionController, decoration: const InputDecoration(labelText: "Description")),
                DropdownButton<String>(
                  value: _selectedCategory,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedCategory = newValue!;
                    });
                  },
                  items: _categories.map((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                _editEvent(event["id"], {
                  "title": _titleController.text,
                  "date": _dateController.text,
                  "time": _timeController.text,
                  "venue": _venueController.text,
                  "description": _descriptionController.text,
                  "category": _selectedCategory,
                  "host": event["host"]
                });
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Eventing")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Create and Manage Events",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: "Title")),
            TextField(controller: _dateController, decoration: const InputDecoration(labelText: "Date")),
            TextField(controller: _timeController, decoration: const InputDecoration(labelText: "Time")),
            TextField(controller: _venueController, decoration: const InputDecoration(labelText: "Venue")),
            TextField(controller: _descriptionController, decoration: const InputDecoration(labelText: "Description")),

            DropdownButton<String>(
              value: _selectedCategory,
              onChanged: (String? newValue) {
                setState(() {
                  _selectedCategory = newValue!;
                });
              },
              items: _categories.map((String category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
            ),

            ElevatedButton(
              onPressed: _createEvent,
              child: const Text("Create Event"),
            ),

            const SizedBox(height: 20),
            const Text(
              "Host Events",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            Expanded(
              child: _hostEvents.isEmpty
                  ? const Center(child: Text("No events created yet."))
                  : ListView.builder(
                itemCount: _hostEvents.length,
                itemBuilder: (context, index) {
                  final event = _hostEvents[index];
                  return Card(
                    child: ListTile(
                      title: Text(event["title"] ?? "Untitled"),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("📅 Date: ${event["date"]}"),
                          Text("⏰ Time: ${event["time"]}"),
                          Text("📍 Venue: ${event["venue"]}"),
                          Text("🏷️ Category: ${event["category"]}"),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _showEditEventDialog(event),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteEvent(event["id"]),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
