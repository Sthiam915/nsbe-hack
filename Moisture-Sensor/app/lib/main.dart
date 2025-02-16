import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';

void main() {
  runApp(const MoistureMeterApp());
}

class MoistureMeterApp extends StatelessWidget {
  const MoistureMeterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MoistureMeterScreen(),
    );
  }
}

class MoistureMeterScreen extends StatefulWidget {
  @override
  _MoistureMeterScreenState createState() => _MoistureMeterScreenState();
}

class _MoistureMeterScreenState extends State<MoistureMeterScreen> {
  final List<Map<String, dynamic>> userPlants = [];
  final Map<String, Map<String, double>> plantMoistureRanges = {
    "Rose": {"min": 40, "max": 60},
    "Cactus": {"min": 10, "max": 30},
    "Oak Tree": {"min": 60, "max": 80},
    "Apple Tree": {"min": 50, "max": 70},
    "Blueberry Bush": {"min": 55, "max": 65},
  };

  // Fixed overall moisture level (will be updated via HTTP)
  double overallMoistureLevel = 45.0;

  final Map<String, IconData> plantIcons = {
    "Rose": Icons.local_florist,
    "Cactus": Icons.eco,
    "Oak Tree": Icons.nature,
    "Apple Tree": Icons.agriculture,
    "Blueberry Bush": Icons.grass,
  };

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Start periodic moisture level updates
    _startMoistureUpdates();
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer when the widget is disposed
    super.dispose();
  }

  void _startMoistureUpdates() {
    // Fetch moisture level every 5 seconds
    _timer = Timer.periodic(Duration(seconds: 5), (timer) async {
      double newMoistureLevel = await fetchMoistureLevel();
      setState(() {
        overallMoistureLevel = newMoistureLevel;
        // Update current moisture for all plants
        for (var plant in userPlants) {
          plant["currentMoisture"] = overallMoistureLevel;
        }
      });
    });
  }

  Future<double> fetchMoistureLevel() async {
  try {
    // Replace with your actual API endpoint
    // final response = await http.get(Uri.parse('https://your-api-endpoint.com/moisture'));
    final response = await http.get(Uri.parse('http://172.20.10.6:5000/moisture'));

    if (response.statusCode == 200) {
      // Parse the response body to get the moisture level
      final data = json.decode(response.body);
      return data['moistureLevel'].toDouble();
    } else {
      // If the server returns an error, return a default value
      print('Failed to load moisture level: ${response.statusCode}');
      return 45.0; // Fallback moisture level
    }
  } catch (e) {
    // Handle network errors or other exceptions
    print('Error fetching moisture level: $e');
    return 45.0; // Fallback moisture level
  }
}

  void addPlant(String plant) {
    // Use the overallMoistureLevel as the initial currentMoisture
    setState(() {
      userPlants.add({
        "name": plant,
        "currentMoisture": overallMoistureLevel, // Fixed initial moisture
        "minMoisture": plantMoistureRanges[plant]!["min"] ?? 50.0,
        "maxMoisture": plantMoistureRanges[plant]!["max"] ?? 50.0,
      });
    });
  }

  void deletePlant(int index) {
    setState(() {
      userPlants.removeAt(index);
    });
  }

  void _showAddPlantDialog() {
    String searchQuery = "";

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Select a Plant"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: InputDecoration(
                      hintText: "Search for a plant...",
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                  SizedBox(height: 10),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: plantMoistureRanges.keys
                            .where((plant) =>
                                plant.toLowerCase().contains(searchQuery))
                            .map((plant) {
                          return ListTile(
                            leading: Icon(plantIcons[plant] ?? Icons.local_florist),
                            title: Text(plant),
                            subtitle: Text(
                                "Requires ${plantMoistureRanges[plant]!["min"]}% - ${plantMoistureRanges[plant]!["max"]}% moisture"),
                            onTap: () {
                              addPlant(plant);
                              Navigator.pop(context);
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Moisture Meter'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _showAddPlantDialog,
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Overall Moisture Level: ${overallMoistureLevel.toStringAsFixed(1)}%',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: userPlants.isEmpty
                ? Center(child: Text("No plants added. Tap + to add."))
                : ListView.builder(
                    itemCount: userPlants.length,
                    itemBuilder: (context, index) {
                      final plant = userPlants[index];
                      final isMoistureInRange = plant["currentMoisture"] >=
                              plant["minMoisture"] &&
                          plant["currentMoisture"] <= plant["maxMoisture"];
                      return Card(
                        margin: EdgeInsets.all(10),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(plantIcons[plant["name"]] ?? Icons.local_florist, size: 40),
                              SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      plant["name"],
                                      style: TextStyle(
                                          fontSize: 20, fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      'Current Moisture: ${plant["currentMoisture"].toStringAsFixed(1)}%',
                                    ),
                                    Text(
                                      'Required Range: ${plant["minMoisture"].toStringAsFixed(1)}% - ${plant["maxMoisture"].toStringAsFixed(1)}%',
                                      style: TextStyle(
                                        color: isMoistureInRange
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 10),
                              Column(
                                children: [
                                  Stack(
                                    alignment: Alignment.bottomCenter,
                                    children: [
                                      Container(
                                        height: 100,
                                        width: 20,
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.black),
                                          color: Colors.grey[300],
                                        ),
                                      ),
                                      Positioned(
                                        bottom: (plant["minMoisture"] / 100) * 100,
                                        child: Container(
                                          height: 2,
                                          width: 20,
                                          color: Colors.blue,
                                        ),
                                      ),
                                      Positioned(
                                        bottom: (plant["maxMoisture"] / 100) * 100,
                                        child: Container(
                                          height: 2,
                                          width: 20,
                                          color: Colors.blue,
                                        ),
                                      ),
                                      Container(
                                        height: (plant["currentMoisture"] / 100) * 100,
                                        width: 20,
                                        color: isMoistureInRange
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 10),
                                  IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => deletePlant(index),
                                  ),
                                ],
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
    );
  }
}