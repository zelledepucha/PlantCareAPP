import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('plant_data');
  runApp(PlantCareApp());
}

class PlantCareApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Plant Care',
      theme: ThemeData(primarySwatch: Colors.green),
      home: GalleryScreen(),
    );
  }
}

class GalleryScreen extends StatefulWidget {
  @override
  _GalleryScreenState createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final Box _plantBox = Hive.box('plant_data'); // Fixed Box type

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      await _plantBox.add({'photo': bytes, 'name': '', 'schedule': []});
      setState(() {});
    }
  }

  void _deletePhoto(int index) async {
    await _plantBox.deleteAt(index);
    setState(() {});
  }

  void _editPlant(int index) {
    final plantData = _plantBox.getAt(index);
    TextEditingController nameController = TextEditingController(
      text: plantData?['name'],
    );

    DateTime? selectedDateTime;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Plant Info'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Plant Name'),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2023),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    final TimeOfDay? pickedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (pickedTime != null) {
                      selectedDateTime = DateTime(
                        picked.year,
                        picked.month,
                        picked.day,
                        pickedTime.hour,
                        pickedTime.minute,
                      );
                    }
                  }
                },
                child: Text('Set Watering Schedule'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (selectedDateTime != null) {
                  List<dynamic> scheduleList = List.from(
                    plantData?['schedule'] ?? [],
                  );
                  scheduleList.add(selectedDateTime.toString());

                  _plantBox.putAt(index, {
                    'photo': plantData?['photo'],
                    'name': nameController.text,
                    'schedule': scheduleList,
                  });

                  setState(() {});
                }
                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Plant Care Gallery')),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.green),
              child: Text(
                'Plant Care',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: Icon(Icons.schedule),
              title: Text('Watering Schedule History'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ScheduleHistoryScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.info),
              title: Text('Plant Care Tips'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PlantTipsScreen()),
                );
              },
            ),
          ],
        ),
      ),
      body: ValueListenableBuilder(
        valueListenable: _plantBox.listenable(),
        builder: (context, Box box, _) {
          if (box.isEmpty) {
            return Center(child: Text('No plants added.'));
          }
          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
            ),
            itemCount: box.length,
            itemBuilder: (context, index) {
              final plantData = box.getAt(index);
              if (plantData == null || plantData['photo'] == null) {
                return SizedBox.shrink();
              }
              List<dynamic> scheduleList = plantData['schedule'] ?? [];

              return GestureDetector(
                onTap: () => _editPlant(index),
                child: Card(
                  margin: EdgeInsets.all(8),
                  child: Column(
                    children: [
                      Expanded(
                        child: Image.memory(
                          Uint8List.fromList(plantData['photo']),
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      ),
                      Text(plantData['name'] ?? 'Unknown Plant'),
                      Text(
                        'Next Watering: ${scheduleList.isNotEmpty ? scheduleList.last : 'Not Set'}',
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deletePhoto(index),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickImage,
        child: Icon(Icons.add_a_photo),
      ),
    );
  }
}

class PlantTipsScreen extends StatelessWidget {
  final List<String> tips = [
    "Water your plants early in the morning or late in the evening to prevent evaporation.",
    "Ensure proper drainage to avoid root rot.",
    "Use organic compost to enrich the soil.",
    "Place indoor plants near sunlight but avoid direct harsh exposure.",
    "Mist tropical plants to maintain humidity levels.",
    "Prune dead leaves to promote new growth.",
    "Rotate potted plants periodically for even growth.",
    "Check soil moisture before watering to prevent overwatering.",
    "Use banana peels or eggshells as natural fertilizers.",
    "Group plants with similar water and light needs together for easy care.",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Plant Care Tips')),
      body: ListView.builder(
        itemCount: tips.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: Icon(Icons.eco, color: Colors.green),
            title: Text(tips[index]),
          );
        },
      ),
    );
  }
}

class ScheduleHistoryScreen extends StatelessWidget {
  final Box _plantBox = Hive.box('plant_data');

  @override
  Widget build(BuildContext context) {
    List<String> history = [];

    for (int i = 0; i < _plantBox.length; i++) {
      final plantData = _plantBox.getAt(i);
      List<dynamic> scheduleList = plantData?['schedule'] ?? [];
      for (var schedule in scheduleList) {
        history.add('${plantData?['name'] ?? "Unknown Plant"} - $schedule');
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text('Watering Schedule History')),
      body:
          history.isEmpty
              ? Center(child: Text('No schedule history available.'))
              : ListView.builder(
                itemCount: history.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: Icon(Icons.water_drop, color: Colors.blue),
                    title: Text(history[index]),
                  );
                },
              ),
    );
  }
}
