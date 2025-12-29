import 'dart:convert';
import 'package:exam_web/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? geoData;
  Set<String> selectedHistory = {};

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

  Future<void> deleteSelectedHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    history.removeWhere((ip) => selectedHistory.contains(ip));
    await prefs.setStringList('history', history);
    setState(() {
      selectedHistory.clear();
    });
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

            if (geoData != null && geoData!['loc'] != null)
              SizedBox(
                height: 400, // keep a fixed height for both
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Geo Info Card
                    Expanded(
                      flex: 1, // half of the width
                      child: Card(
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
                    ),

                    const SizedBox(width: 20), // spacing between card & map

                    // Map
                    Expanded(
                      flex: 1, // half of the width
                      child: FlutterMap(
                        mapController: MapController(),
                        options: MapOptions(
                          initialCenter: LatLng(
                            double.parse(geoData!['loc'].split(',')[0]),
                            double.parse(geoData!['loc'].split(',')[1]),
                          ),
                          initialZoom: 10,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                            subdomains: const ['a', 'b', 'c'],
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: LatLng(
                                  double.parse(geoData!['loc'].split(',')[0]),
                                  double.parse(geoData!['loc'].split(',')[1]),
                                ),
                                width: 80,
                                height: 80,
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.location_pin,
                                  color: Colors.red,
                                  size: 40,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),


            const SizedBox(height: 20),

            // Search History
            Expanded(
              child: Column(
                children: [
                  if (selectedHistory.isNotEmpty || history.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade300, // background color
                        borderRadius: BorderRadius.circular(8), // optional rounded corners
                      ),
                      child: const Text(
                        "HISTORY",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white, // text color
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),

                  // Delete Selected Button
                  if (selectedHistory.isNotEmpty)
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: deleteSelectedHistory,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text("Delete Selected"),
                      ),
                    ),

                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView(
                      children: history.map((ip) {
                        return CheckboxListTile(
                          value: selectedHistory.contains(ip),
                          onChanged: (checked) {
                            setState(() {
                              if (checked == true) {
                                selectedHistory.add(ip);
                              } else {
                                selectedHistory.remove(ip);
                              }
                            });
                          },
                          title: Text(ip),
                          secondary: IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: () => fetchGeoByIP(ip),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
