import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TicketScreen extends StatefulWidget {
  final String loggedInUser; // Username of the logged-in user

  const TicketScreen({Key? key, required this.loggedInUser}) : super(key: key);

  @override
  _TicketScreenState createState() => _TicketScreenState();
}

class _TicketScreenState extends State<TicketScreen> {
  List<dynamic> hostEvents = [];
  List<dynamic> participantEvents = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchEvents();
  }

  Future<void> fetchEvents() async {
    try {
      final eventsResponse = await http.get(Uri.parse('http://10.0.2.2:3001/events'));
      final participantsResponse = await http.get(Uri.parse('http://10.0.2.2:3001/participants/user/${widget.loggedInUser}'));

      if (eventsResponse.statusCode == 200 && participantsResponse.statusCode == 200) {
        List<dynamic> allEvents = jsonDecode(eventsResponse.body);
        List<dynamic> userEvents = jsonDecode(participantsResponse.body)['events'] ?? [];

        setState(() {
          hostEvents = allEvents.where((event) => event['host'] == widget.loggedInUser).toList();
          participantEvents = userEvents;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load events');
      }
    } catch (e) {
      print("Error fetching events: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Your Events")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView( // ✅ Fix bottom overflow by making content scrollable
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const Text("Host Events", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              hostEvents.isEmpty
                  ? const Text("No events created yet.")
                  : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: hostEvents.length,
                itemBuilder: (context, index) {
                  final event = hostEvents[index];
                  return Card(
                    child: ListTile(
                      title: Text(event['title']),
                      subtitle: Text("📅 ${event['date']} | 📍 ${event['venue']}"),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              const Text("Participant Events", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              participantEvents.isEmpty
                  ? const Text("No events joined yet.")
                  : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: participantEvents.length,
                itemBuilder: (context, index) {
                  final event = participantEvents[index];
                  return Card(
                    child: ListTile(
                      title: Text(event['title']),
                      subtitle: Text("📅 ${event['date']} | 📍 ${event['venue']}"),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
