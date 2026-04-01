import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:device_apps/device_apps.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Doomscroll Stopper',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Doomscroll Stopper'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const platform = MethodChannel('com.example.doomscroll_stop/doomscroll');
  
  List<Application> _apps = [];
  Application? _selectedApp;
  
  final List<int> _minutesOptions = [1, 2, 3, 4, 5, 7, 10, 15, 20, 30, 45, 60];
  int _selectedMinutes = 5;
  
  bool _isServiceRunning = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    // Request basic permissions via permission_handler
    await [
      Permission.notification,
    ].request();
    
    // Fetch installed apps using device_apps package
    List<Application> apps = await DeviceApps.getInstalledApplications(
      includeAppIcons: true,
      includeSystemApps: false,
      onlyAppsWithLaunchIntent: true,
    );
    apps.sort((a, b) => a.appName.toLowerCase().compareTo(b.appName.toLowerCase()));
    
    setState(() {
      _apps = apps;
      _loading = false;
    });
  }

  Future<void> _toggleService() async {
    if (_selectedApp == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an app first')));
      return;
    }
    
    try {
      if (_isServiceRunning) {
        await platform.invokeMethod('stopService');
        setState(() => _isServiceRunning = false);
      } else {
        await platform.invokeMethod('startService', {
          'packageNames': [_selectedApp!.packageName],
          'minimumTimeElapsed': _selectedMinutes * 60,
          'initialTime': DateTime.now().millisecondsSinceEpoch,
        });
        setState(() => _isServiceRunning = true);
      }
    } catch (e) {
      debugPrint("Service error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _loading 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('1. Pick an App', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                DropdownButtonFormField<Application>(
                  value: _selectedApp,
                  isExpanded: true,
                  hint: const Text('Select application...'),
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: _apps.map((app) {
                    return DropdownMenuItem<Application>(
                      value: app,
                      child: Row(
                        children: [
                          if (app is ApplicationWithIcon) ...[
                            Image.memory(app.icon, width: 32, height: 32),
                            const SizedBox(width: 10),
                          ],
                          Expanded(child: Text(app.appName, overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() => _selectedApp = val);
                  },
                ),
                
                const SizedBox(height: 30),
                
                const Text('2. Trigger Time', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                DropdownButtonFormField<int>(
                  value: _selectedMinutes,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: _minutesOptions.map((min) => DropdownMenuItem(value: min, child: Text('$min minutes'))).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedMinutes = val);
                  },
                ),
                
                const Spacer(),
                
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: _isServiceRunning ? Colors.red : Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _toggleService,
                  child: Text(
                    _isServiceRunning ? 'STOP TRACKING' : 'START TRACKING',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}
