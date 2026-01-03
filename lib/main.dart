```dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';

void main() {
  runApp(TattooStudioApp());
}

class TattooStudioApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tattoo Studio Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: Color(0xFF9C27B0),
          secondary: Color(0xFFE91E63),
          surface: Color(0xFF1E1E1E),
          background: Color(0xFF121212),
          onSurface: Colors.white,
          onBackground: Colors.white,
        ),
        cardTheme: CardTheme(
          color: Color(0xFF2C2C2C),
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          elevation: 0,
          centerTitle: true,
        ),
      ),
      home: LicenseManager(),
    );
  }
}

class LicenseManager extends StatefulWidget {
  @override
  _LicenseManagerState createState() => _LicenseManagerState();
}

class _LicenseManagerState extends State<LicenseManager> {
  bool _isLicenseValid = false;
  int _trialDaysLeft = 5;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkLicense();
  }

  Future<void> _checkLicense() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check if license key exists
    final licenseKey = prefs.getString('license_key');
    if (licenseKey != null && _validateLicenseKey(licenseKey)) {
      setState(() {
        _isLicenseValid = true;
        _isLoading = false;
      });
      return;
    }

    // Check trial period
    final firstRun = prefs.getInt('first_run');
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    
    if (firstRun == null) {
      await prefs.setInt('first_run', currentTime);
      setState(() {
        _trialDaysLeft = 5;
        _isLoading = false;
      });
    } else {
      final daysPassed = ((currentTime - firstRun) / (1000 * 60 * 60 * 24)).floor();
      final daysLeft = 5 - daysPassed;
      
      setState(() {
        _trialDaysLeft = daysLeft > 0 ? daysLeft : 0;
        _isLoading = false;
      });
    }
  }

  bool _validateLicenseKey(String key) {
    final pattern = RegExp(r'^[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$');
    if (!pattern.hasMatch(key)) return false;
    
    // Simple validation - in real app, validate with server
    final hash = sha256.convert(utf8.encode(key + 'tattoo_studio_salt'));
    final validHashes = [
      'a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5z6',
      // Add more valid license hashes here
    ];
    
    return key == 'DEMO-DEMO-DEMO-DEMO' || validHashes.contains(hash.toString());
  }

  Future<void> _activateLicense(String licenseKey) async {
    if (_validateLicenseKey(licenseKey)) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('license_key', licenseKey);
      setState(() {
        _isLicenseValid = true;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chave de licença inválida')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isLicenseValid && _trialDaysLeft <= 0) {
      return LicenseExpiredScreen(onActivate: _activateLicense);
    }

    return MainApp(
      isTrialVersion: !_isLicenseValid,
      trialDaysLeft: _trialDaysLeft,
      onActivateLicense: _activateLicense,
    );
  }
}

class LicenseExpiredScreen extends StatefulWidget {
  final Function(String) onActivate;

  LicenseExpiredScreen({required this.onActivate});

  @override
  _LicenseExpiredScreenState createState() => _LicenseExpiredScreenState();
}

class _LicenseExpiredScreenState extends State<LicenseExpiredScreen> {
  final TextEditingController _licenseController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF9C27B0), Color(0xFFE91E63)],
          ),
        ),
        child: Center(
          child: Card(
            margin: EdgeInsets.all(32),
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    'Período de Teste Expirado',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Seu período de teste de 5 dias expirou. Para continuar usando o app, insira sua chave de licença.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[300]),
                  ),
                  SizedBox(height: 24),
                  TextField(
                    controller: _licenseController,
                    decoration: InputDecoration(
                      labelText: 'Chave de Licença',
                      hintText: 'XXXX-XXXX-XXXX-XXXX',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: Icon(Icons.vpn_key),
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Use DEMO-DEMO-DEMO-DEMO para demonstração',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      widget.onActivate(_licenseController.text);
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('Ativar Licença'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MainApp extends StatefulWidget {
  final bool isTrialVersion;
  final int trialDaysLeft;
  final Function(String) onActivateLicense;

  MainApp({
    required this.isTrialVersion,
    required this.trialDaysLeft,
    required this.onActivateLicense,
  });

  @override
  _MainAppState createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _currentIndex = 0;
  final DataService _dataService = DataService();

  @override
  void initState() {
    super.initState();
    _dataService.init();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(dataService: _dataService),
      ClientsScreen(dataService: _dataService),
      CalendarScreen(dataService: _dataService),
      GalleryScreen(dataService: _dataService),
      FinancialScreen(dataService: _dataService),
      MaterialsScreen(dataService: _dataService),
    ];

    return Scaffold(
      appBar: widget.isTrialVersion ? AppBar(
        backgroundColor: Colors.orange,
        title: Text('TESTE - ${widget.trialDaysLeft} dias restantes'),
        actions: [
          TextButton.icon(
            onPressed: () => _showLicenseDialog(),
            icon: Icon(Icons.vpn_key, color: Colors.white),
            label: Text('Ativar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ) : null,
      body: pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Clientes',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Agenda',
          ),
          NavigationDestination(
            icon: Icon(Icons.photo_library_outlined),
            selectedIcon: Icon(Icons.photo_library),
            label: 'Galeria',
          ),
          NavigationDestination(
            icon: Icon(Icons.attach_money_outlined),
            selectedIcon: Icon(Icons.attach_money),
            label: 'Financeiro',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_outlined),
            selectedIcon: Icon(Icons.inventory),
            label: 'Materiais',
          ),
        ],
      ),
    );
  }

  void _showLicenseDialog() {
    final TextEditingController controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ativar Licença'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'Chave de Licença',
                hintText: 'XXXX-XXXX-XXXX-XXXX',
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            SizedBox(height: 8),
            Text(
              'Use DEMO-DEMO-DEMO-DEMO para demonstração',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              widget.onActivateLicense(controller.text);
              Navigator.pop(context);
            },
            child: Text('Ativar'),
          ),
        ],
      ),
    );
  }
}

// Data Models
class Client {
  String id;
  String name;
  String phone;
  String email;
  DateTime birthDate;
  String observations;
  List<String> tattooHistory;

  Client({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.birthDate,
    required this.observations,
    required this.tattooHistory,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'email': email,
    'birthDate': birthDate.millisecondsSinceEpoch,
    'observations': observations,
    'tattooHistory': tattooHistory,
  };

  factory Client.fromJson(Map<String, dynamic> json) => Client(
    id: json['id'],
    name: json['name'],
    phone: json['phone'],
    email: json['email'],
    birthDate: DateTime.fromMillisecondsSinceEpoch(json['birthDate']),
    observations: json['observations'],
    tattooHistory: List<String>.from(json['tattooHistory'] ?? []),
  );
}

class Appointment {
  String id;
  String clientId;
  String clientName;
  DateTime dateTime;
  String style;
  String description;
  double estimatedPrice;
  String status;
  List<String> photos;

  Appointment({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.dateTime,
    required this.style,
    required this.description,
    required this.estimatedPrice,
    required this.status,
    required this.photos,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'clientId': clientId,
    'clientName': clientName,
    'dateTime': dateTime.millisecondsSinceEpoch,
    'style': style,
    'description': description,
    'estimatedPrice': estimatedPrice,
    'status': status,
    'photos': photos,
  };

  factory Appointment.fromJson(Map<String, dynamic> json) => Appointment(
    id: json['id'],
    clientId: json['clientId'],
    clientName: json['clientName'],
    dateTime: DateTime.fromMillisecondsSinceEpoch(json['dateTime']),
    style: json['style'],
    description: json['description'],
    estimatedPrice: json['estimatedPrice'].toDouble(),
    status: json['status'],
    photos: List<String>.from(json['photos'] ?? []),
  );
}

class TattooWork {
  String id;
  String clientId;
  String clientName;
  String style;
  String description;
  List<String> beforePhotos;
  List<String> afterPhotos;
  double price;
  DateTime date;

  TattooWork({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.style,
    required this.description,
    required this.beforePhotos,
    required this.afterPhotos,
    required this.price,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'clientId': clientId,
    'clientName': clientName,
    'style': style,
    'description': description,
    'beforePhotos': beforePhotos,
    'afterPhotos':