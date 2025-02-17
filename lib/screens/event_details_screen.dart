import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EventDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> event;
  final String loggedInUser;

  const EventDetailsScreen({Key? key, required this.event, required this.loggedInUser}) : super(key: key);

  @override
  _EventDetailsScreenState createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  List<dynamic> participants = [];
  bool isRegistered = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchParticipants();
  }

  /// 🔹 Fetch participants from backend
  Future<void> fetchParticipants() async {
    final url = Uri.parse('http://10.0.2.2:3001/participants/${widget.event['id']}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          participants = data['participants'] ?? [];
          isRegistered = participants.any((p) => p['name'].toLowerCase() == widget.loggedInUser.toLowerCase());
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load participants: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => isLoading = false);
      print("❌ Error fetching participants: $e");
    }
  }

  /// 🔹 Register user for event
  Future<void> registerToEvent() async {
    final url = Uri.parse('http://10.0.2.2:3001/join-event'); // ✅ Fixed API endpoint
    final body = jsonEncode({
      "username": widget.loggedInUser.trim(), // ✅ Fixed parameter name
      "eventId": widget.event['id']
    });

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      print("📤 Sending request to: $url");
      print("📦 Request body: $body");

      if (response.statusCode == 200) {
        print("✅ Response: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Successfully registered for the event!")),
        );
        fetchParticipants(); // Refresh participant list
      } else {
        final errorMessage = jsonDecode(response.body)['message'] ?? "Failed to register";
        print("❌ Error: $errorMessage");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ $errorMessage")),
        );
      }
    } catch (e) {
      print("❌ Connection error when registering: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Connection error. Try again.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.event['title'] ?? 'Event Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("📅 Date: ${widget.event['date']}", style: const TextStyle(fontSize: 16)),
            Text("⏰ Time: ${widget.event['time']}", style: const TextStyle(fontSize: 16)),
            Text("📍 Venue: ${widget.event['venue']}", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            const Text("📖 Description:", style: TextStyle(fontWeight: FontWeight.bold)),
            Text(widget.event['description'] ?? "No description available."),
            const SizedBox(height: 20),
            Row(
              children: [
                const Icon(Icons.people, size: 20),
                const SizedBox(width: 5),
                Text(
                  "Participants: ${participants.length}",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),
            isRegistered
                ? const Text("✅ You are registered!", style: TextStyle(color: Colors.green, fontSize: 16))
                : ElevatedButton(
              onPressed: registerToEvent,
              child: const Text("Join Event"),
            ),
            const SizedBox(height: 20),
            const Text("Participant List:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : Expanded(
              child: participants.isEmpty
                  ? const Center(child: Text("No participants yet"))
                  : ListView.builder(
                itemCount: participants.length,
                itemBuilder: (context, index) {
                  final participant = participants[index];
                  return ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(participant['name'] ?? 'Unknown'),
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
