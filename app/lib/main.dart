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
      title: 'Moisture Meter',
      debugShowCheckedModeBanner: false,
      home: const MoistureMeterScreen(),
      routes: {
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}

// ===================
// Settings Screen for Customizable Update Interval
// ===================
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int updateInterval = 5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text("Update Interval (seconds)"),
            Slider(
              value: updateInterval.toDouble(),
              min: 5,
              max: 60,
              divisions: 11,
              label: updateInterval.toString(),
              onChanged: (double value) {
                setState(() {
                  updateInterval = value.toInt();
                });
              },
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, updateInterval);
              },
              child: const Text("Save Settings"),
            ),
          ],
        ),
      ),
    );
  }
}

// ===================
// Main Screen with Extended Functionality
// ===================
class MoistureMeterScreen extends StatefulWidget {
  const MoistureMeterScreen({super.key});

  @override
  _MoistureMeterScreenState createState() => _MoistureMeterScreenState();
}

class _MoistureMeterScreenState extends State<MoistureMeterScreen> {
  // Extended plant model includes moisture history and profile info.
  final List<Plant> userPlants = [];

  // Default plant profiles with moisture ranges, icons, and care tips.
  final Map<String, PlantProfile> plantProfiles = {
    "Rose": PlantProfile(
      minMoisture: 40,
      maxMoisture: 60,
      icon: Icons.local_florist,
      careTips: "Needs moderate water and plenty of sunlight.",
    ),
    "Cactus": PlantProfile(
      minMoisture: 10,
      maxMoisture: 30,
      icon: Icons.eco,
      careTips: "Very little water is required. Avoid overwatering.",
    ),
    "Oak Tree": PlantProfile(
      minMoisture: 60,
      maxMoisture: 80,
      icon: Icons.nature,
      careTips: "Needs deep watering during dry spells.",
    ),
    "Apple Tree": PlantProfile(
      minMoisture: 50,
      maxMoisture: 70,
      icon: Icons.agriculture,
      careTips: "Water regularly, especially in summer.",
    ),
    "Blueberry Bush": PlantProfile(
      minMoisture: 55,
      maxMoisture: 65,
      icon: Icons.grass,
      careTips: "Keep soil consistently moist; avoid drying out.",
    ),
  };

  Timer? _timer;
  int updateInterval = 5; // in seconds

  @override
  void initState() {
    super.initState();
    _startMoistureUpdates();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Start periodic moisture updates.
  void _startMoistureUpdates() {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: updateInterval), (timer) async {
      for (var plant in userPlants) {
        double newMoistureLevel = await fetchMoistureLevel(plant.name);
        setState(() {
          plant.currentMoisture = newMoistureLevel;
          // Add new reading to history.
          plant.moistureHistory.add(MoistureReading(
            DateTime.now(),
            newMoistureLevel,
          ));
        });
        // Check moisture level and notify if out of range.
        _checkMoistureLevel(plant);
      }
    });
  }

  // Check and notify if moisture level is out of the ideal range.
  void _checkMoistureLevel(Plant plant) {
    if (plant.currentMoisture < plant.customMinMoisture || plant.currentMoisture > plant.customMaxMoisture) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${plant.name} is out of the ideal moisture range!"),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // Fetch moisture level from an API endpoint.
  Future<double> fetchMoistureLevel(String plantName) async {
    try {
      final response = await http.get(Uri.parse('http://18.227.105.1:5000/moisture'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['moistureLevel'] as num).toDouble();
      } else {
        debugPrint('Failed to load moisture level: ${response.statusCode}');
        return 45.0;
      }
    } catch (e) {
      debugPrint('Error fetching moisture level for $plantName: $e');
      return 45.0;
    }
  }

  // Add a new plant.
  void addPlant(String plantName) {
    final profile = plantProfiles[plantName] ??
        PlantProfile(
          minMoisture: 50,
          maxMoisture: 50,
          icon: Icons.local_florist,
          careTips: "No info available.",
        );
    setState(() {
      userPlants.add(Plant(
        name: plantName,
        currentMoisture: 45.0,
        customMinMoisture: profile.minMoisture,
        customMaxMoisture: profile.maxMoisture,
        profile: profile,
      ));
    });
  }

  // Delete a plant.
  void deletePlant(int index) {
    setState(() {
      userPlants.removeAt(index);
    });
  }

  // Show add plant dialog with search functionality.
  void _showAddPlantDialog() {
    String searchQuery = "";
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Select a Plant"),
              content: SizedBox(
                height: 300,
                child: Column(
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        hintText: "Search for a plant...",
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value.toLowerCase();
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: plantProfiles.keys
                              .where((plant) => plant.toLowerCase().contains(searchQuery))
                              .map((plant) {
                            final profile = plantProfiles[plant]!;
                            return ListTile(
                              leading: Icon(profile.icon),
                              title: Text(plant),
                              subtitle: Text("Range: ${profile.minMoisture}% - ${profile.maxMoisture}%\nTips: ${profile.careTips}"),
                              onTap: () {
                                addPlant(plant);
                                Navigator.pop(dialogContext);
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text("Cancel"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Placeholder: Fetch weather info from a weather API.
  Future<Map<String, dynamic>> fetchWeatherInfo() async {
    await Future.delayed(const Duration(seconds: 1));
    return {"forecast": "Sunny", "rainChance": 10};
  }

  // Provide watering recommendation based on moisture level and weather.
  Future<String> getWateringRecommendation(Plant plant) async {
    final weather = await fetchWeatherInfo();
    if (plant.currentMoisture < plant.customMinMoisture) {
      return "Water ${plant.name} now. Forecast: ${weather['forecast']}.";
    } else if (plant.currentMoisture > plant.customMaxMoisture) {
      return "Do not water ${plant.name} now.";
    } else {
      return "${plant.name} is in the optimal range.";
    }
  }

  // Open settings screen to adjust the update interval.
  Future<void> _openSettings() async {
    final result = await Navigator.pushNamed(context, '/settings');
    if (result != null && result is int) {
      setState(() {
        updateInterval = result;
        _startMoistureUpdates();
      });
    }
  }

  // Show moisture history for a given plant.
  void _showHistory(Plant plant) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("${plant.name} - Moisture History"),
          content: SizedBox(
            height: 300,
            width: 300,
            child: ListView.builder(
              itemCount: plant.moistureHistory.length,
              itemBuilder: (context, index) {
                final reading = plant.moistureHistory[index];
                return ListTile(
                  title: Text(
                    "${reading.time.hour}:${reading.time.minute}:${reading.time.second} - ${reading.level.toStringAsFixed(1)}%",
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
          ],
        );
      },
    );
  }

  // Build main UI.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Moisture Meter'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettings,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddPlantDialog,
          ),
        ],
      ),
      body: userPlants.isEmpty
          ? const Center(child: Text("No plants added. Tap + to add."))
          : ListView.builder(
              itemCount: userPlants.length,
              itemBuilder: (context, index) {
                final plant = userPlants[index];
                final isMoistureInRange = plant.currentMoisture >= plant.customMinMoisture &&
                    plant.currentMoisture <= plant.customMaxMoisture;
                return Card(
                  margin: const EdgeInsets.all(10),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(plant.profile.icon, size: 40),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(plant.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 10),
                              Text('Current Moisture: ${plant.currentMoisture.toStringAsFixed(1)}%'),
                              Text(
                                'Range: ${plant.customMinMoisture}% - ${plant.customMaxMoisture}%',
                                style: TextStyle(color: isMoistureInRange ? Colors.green : Colors.red),
                              ),
                              FutureBuilder<String>(
                                future: getWateringRecommendation(plant),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData) {
                                    return Text("Recommendation: ${snapshot.data!}");
                                  }
                                  return const SizedBox();
                                },
                              ),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            GestureDetector(
                              onTap: () => _showHistory(plant),
                              child: Container(
                                height: 100,
                                width: 20,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.black),
                                  color: Colors.grey[300],
                                ),
                                child: Stack(
                                  alignment: Alignment.bottomCenter,
                                  children: [
                                    Positioned(
                                      bottom: (plant.customMinMoisture / 100) * 100,
                                      child: Container(height: 2, width: 20, color: Colors.blue),
                                    ),
                                    Positioned(
                                      bottom: (plant.customMaxMoisture / 100) * 100,
                                      child: Container(height: 2, width: 20, color: Colors.blue),
                                    ),
                                    Container(
                                      height: (plant.currentMoisture / 100) * 100,
                                      width: 20,
                                      color: isMoistureInRange ? Colors.green : Colors.red,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
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
    );
  }
}

// ===================
// Data Models
// ===================

class Plant {
  final String name;
  double currentMoisture;
  double customMinMoisture;
  double customMaxMoisture;
  final PlantProfile profile;
  final List<MoistureReading> moistureHistory;

  Plant({
    required this.name,
    required this.currentMoisture,
    required this.customMinMoisture,
    required this.customMaxMoisture,
    required this.profile,
  }) : moistureHistory = [MoistureReading(DateTime.now(), currentMoisture)];
}

class PlantProfile {
  final double minMoisture;
  final double maxMoisture;
  final IconData icon;
  final String careTips;

  PlantProfile({
    required this.minMoisture,
    required this.maxMoisture,
    required this.icon,
    required this.careTips,
  });
}

class MoistureReading {
  final DateTime time;
  final double level;

  MoistureReading(this.time, this.level);
}
