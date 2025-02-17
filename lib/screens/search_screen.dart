import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'event_details_screen.dart';

class SearchScreen extends StatefulWidget {
  final String loggedInUser;

  const SearchScreen({Key? key, required this.loggedInUser}) : super(key: key);

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  List<dynamic> allEvents = [];
  List<dynamic> filteredEvents = [];
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    fetchEvents();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    fetchEvents();
  }

  /// 🔹 Fetch all events from the backend
  Future<void> fetchEvents() async {
    try {
      final response = await http.get(Uri.parse('http://10.0.2.2:3001/events'));

      if (response.statusCode == 200) {
        setState(() {
          allEvents = jsonDecode(response.body);
          filteredEvents = allEvents; // Show all events by default
        });
      }
    } catch (e) {
      print("Error fetching events: $e");
    }
  }

  /// 🔹 Filter events based on search query
  void filterEvents(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
      filteredEvents = allEvents.where((event) {
        return (event['title'] ?? '').toLowerCase().contains(searchQuery);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    // 🔹 Group events by category
    Map<String, List<dynamic>> categorizedEvents = {};

    for (var event in filteredEvents) {
      String category = event['category']?.toString() ?? 'Other';
      if (!categorizedEvents.containsKey(category)) {
        categorizedEvents[category] = [];
      }
      categorizedEvents[category]!.add(event);
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Search Events")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 🔹 Search Bar
            TextField(
              onChanged: filterEvents,
              decoration: const InputDecoration(
                labelText: "Search Events",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),

            // 🔹 Event List by Category with Pull-to-Refresh
            Expanded(
              child: RefreshIndicator(
                onRefresh: fetchEvents,
                child: ListView(
                  children: categorizedEvents.entries.map((entry) {
                    String category = entry.key;
                    List<dynamic> events = entry.value;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 🔹 Category Header
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            category,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),

                        // 🔹 Events List
                        Column(
                          children: events.map((event) {
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EventDetailsScreen(
                                      event: event,
                                      loggedInUser: widget.loggedInUser,
                                    ),
                                  ),
                                );
                              },
                              child: Card(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                child: ListTile(
                                  title: Text(event['title'] ?? 'No Title'),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("📅 ${event['date'] ?? 'No Date'}"),
                                      Text("📍 ${event['venue'] ?? 'No Venue'}"),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 10),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
