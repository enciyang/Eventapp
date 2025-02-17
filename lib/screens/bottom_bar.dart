import 'package:flutter/material.dart';
import 'package:eventing/screens/home_screen.dart';
import 'package:eventing/screens/search_screen.dart';
import 'package:eventing/screens/tickets_screen.dart';
import 'package:eventing/screens/profile_screen.dart';

class BottomBar extends StatefulWidget {
  final String loggedInUser;

  const BottomBar({Key? key, required this.loggedInUser}) : super(key: key);

  @override
  _BottomBarState createState() => _BottomBarState();
}

class _BottomBarState extends State<BottomBar> {
  int _selectedIndex = 0;

  late List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _widgetOptions = [
      HomeScreen(loggedInUser: widget.loggedInUser),
      SearchScreen(loggedInUser: widget.loggedInUser),
      TicketScreen(loggedInUser: widget.loggedInUser),
    ProfileScreen(loggedInUser: widget.loggedInUser),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        elevation: 10,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedItemColor: Colors.blueGrey,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "Search"),
          BottomNavigationBarItem(icon: Icon(Icons.confirmation_num), label: "Tickets"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}
