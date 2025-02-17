import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../screens/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String loggedInUser;

  const ProfileScreen({Key? key, required this.loggedInUser}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<dynamic> notifications = [];
  List<dynamic> mostPopularEvents = [];
  Map<String, int> categoryCounts = {};
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() => isLoading = true);
    await fetchNotifications();
    await fetchStatistics();
    setState(() => isLoading = false);
  }

  Future<void> fetchNotifications() async {
    try {
      final response = await http.get(Uri.parse('http://10.0.2.2:3001/notifications'));

      if (response.statusCode == 200) {
        setState(() {
          notifications = jsonDecode(response.body);
        });
      } else {
        setState(() {
          errorMessage = "Failed to load notifications.";
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Error fetching notifications: $e";
      });
    }
  }

  Future<void> fetchStatistics() async {
    try {
      final response = await http.get(Uri.parse('http://10.0.2.2:3001/stats'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          mostPopularEvents = data['mostPopularEvents'] ?? [];
          categoryCounts = Map<String, int>.from(data['categoryCounts'] ?? {});
        });
      } else {
        setState(() {
          errorMessage = "Failed to load event statistics.";
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Error fetching statistics: $e";
      });
    }
  }

  String formatTimestamp(String timestamp) {
    try {
      final DateTime parsedTime = DateTime.parse(timestamp);
      return DateFormat.yMMMd().add_jm().format(parsedTime);
    } catch (e) {
      return timestamp;
    }
  }

  void _logout() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      body: RefreshIndicator(
        onRefresh: loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    const Icon(Icons.person, size: 100, color: Colors.blueGrey),
                    const SizedBox(height: 10),
                    Text(
                      "Welcome, ${widget.loggedInUser}!",
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),

              const Text("🔔 Notifications", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),

              errorMessage.isNotEmpty
                  ? Text(errorMessage, style: const TextStyle(color: Colors.red))
                  : notifications.isEmpty
                  ? const Text("No notifications yet.")
                  : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: const Icon(Icons.notifications, color: Colors.blueGrey),
                      title: Text(notifications[index]['message']),
                      subtitle: Text(formatTimestamp(notifications[index]['timestamp'])),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              const Text("📊 Event Statistics", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),

              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("🎟️ Most Popular Events", style: TextStyle(fontWeight: FontWeight.bold)),
                  mostPopularEvents.isEmpty
                      ? const Text("No popular events yet.")
                      : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: mostPopularEvents.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(mostPopularEvents[index]['title'] ?? "Untitled"),
                        subtitle: Text("Participants: ${mostPopularEvents[index]['participantCount']}"),
                      );
                    },
                  ),

                  const SizedBox(height: 10),

                  const Text("📌 Participants per Category", style: TextStyle(fontWeight: FontWeight.bold)),
                  categoryCounts.isEmpty
                      ? const Text("No category statistics yet.")
                      : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: categoryCounts.length,
                    itemBuilder: (context, index) {
                      String category = categoryCounts.keys.elementAt(index);
                      return ListTile(
                        title: Text(category),
                        subtitle: Text("Participants: ${categoryCounts[category]}"),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Center(
                child: ElevatedButton(
                  onPressed: _logout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: const Text(
                    "logout the account",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}