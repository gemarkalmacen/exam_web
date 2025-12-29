import 'dart:convert';
import 'package:exam_web/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? geoData;
  final TextEditingController ipController = TextEditingController();
  List<String> history = [];
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchUserGeo();
    loadHistory();
  }

  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  Future<void> fetchUserGeo() async {
    try {
      final response = await http.get(Uri.parse('https://ipinfo.io/geo'));
      final data = jsonDecode(response.body);
      setState(() {
        geoData = data;
        errorMessage = null;
      });
    } catch (e) {
      setState(() {
        errorMessage = "Failed to fetch geolocation";
      });
    }
  }

  Future<void> fetchGeoByIP(String ip) async {
    final ipRegex = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');
    if (!ipRegex.hasMatch(ip)) {
      setState(() {
        errorMessage = "Invalid IP address";
      });
      return;
    }

    try {
      final response = await http.get(Uri.parse('https://ipinfo.io/$ip/geo'));
      final data = jsonDecode(response.body);
      setState(() {
        geoData = data;
        errorMessage = null;
        addToHistory(ip);
      });
    } catch (e) {
      setState(() {
        errorMessage = "Failed to fetch geolocation for IP";
      });
    }
  }

  Future<void> addToHistory(String ip) async {
    if (!history.contains(ip)) {
      history.add(ip);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setStringList('history', history);
    }
  }

  Future<void> loadHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList('history') ?? [];
    setState(() {
      history = stored;
    });
  }

  Future<void> clearSearch() async {
    ipController.clear();
    await fetchUserGeo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home"),
        actions: [
          // IconButton(
          //   icon: const Icon(Icons.refresh),
          //   tooltip: "Clear Search",
          //   onPressed: clearSearch,
          // ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Logout",
            onPressed: logout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // IP Input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: ipController,
                    decoration: const InputDecoration(
                        labelText: "Enter IP address"),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => fetchGeoByIP(ipController.text.trim()),
                  child: const Text("Search"),
                ),

                const SizedBox(width: 8),

                ElevatedButton(
                  onPressed: clearSearch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF29B6F6), // same blue
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                  child: const Text("Clear"),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Error Message
            if (errorMessage != null)
              Text(errorMessage!, style: const TextStyle(color: Colors.red)),

            // Geo Info Display
            if (geoData != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: geoData!.entries
                        .map((e) => Text("${e.key}: ${e.value}"))
                        .toList(),
                  ),
                ),
              ),
            const SizedBox(height: 20),

            // Search History
            if (history.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "HISTORY",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  children: history
                      .map((ip) => ListTile(
                            title: Text(ip),
                            onTap: () => fetchGeoByIP(ip),
                          ))
                      .toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
