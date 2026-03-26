import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:dharma_police/providers/auth_provider.dart';
import 'package:dharma_police/services/api/hierarchy_api.dart';

class PoliceRegistrationScreen extends StatefulWidget {
  const PoliceRegistrationScreen({super.key});
  @override
  State<PoliceRegistrationScreen> createState() => _PoliceRegistrationScreenState();
}

class _PoliceRegistrationScreenState extends State<PoliceRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  static const Color navy = Color(0xFF1A237E);

  String? _selectedRank;
  String? _selectedDistrict;
  String? _selectedStation;

  List<String> _districts = [];
  List<String> _stations = [];
  bool _loadingHierarchy = true;

  static const List<String> _ranks = [
    'Director General of Police',
    'Additional Director General of Police',
    'Inspector General of Police',
    'Deputy Inspector General of Police',
    'Superintendent of Police',
    'Additional Superintendent of Police',
    'Deputy Superintendent of Police',
    'Inspector of Police',
    'Sub Inspector of Police',
    'Assistant Sub Inspector of Police',
    'Head Constable',
    'Police Constable',
  ];

  @override
  void initState() {
    super.initState();
    _loadHierarchy();
  }

  Future<void> _loadHierarchy() async {
    try {
      final districts = await HierarchyApi.getDistricts();
      setState(() {
        _districts = districts.map((d) => d['name'].toString()).toList();
        _loadingHierarchy = false;
      });
    } catch (e) {
      setState(() => _loadingHierarchy = false);
    }
  }

  Future<void> _loadStations(String district) async {
    try {
      final stations = await HierarchyApi.getStations(circle: district);
      setState(() {
        _stations = stations.map((s) => s['name'].toString()).toList();
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRank == null) { _snack('Please select your rank'); return; }

    setState(() => _isLoading = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);

      // 1. Create Firebase account
      await auth.signUpWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      // 2. Create backend account + police profile
      await auth.createAccountAndPoliceProfile(
        displayName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        rank: _selectedRank!,
        district: _selectedDistrict,
        stationName: _selectedStation,
      );

      if (mounted) {
        _snack('Registration successful!', Colors.green);
        context.go('/dashboard');
      }
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '').trim();
      _snack(msg);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _snack(String msg, [Color? bg]) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: bg));
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          SizedBox(
            height: h * 0.18, width: w,
            child: Stack(children: [
              SvgPicture.asset('assets/svg/Frame.svg', fit: BoxFit.fill, width: w, height: h * 0.18),
              Positioned(top: 0, left: 0, child: SafeArea(child: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/login')))),
              Positioned(left: 0, right: 0, bottom: 8, child: Image.asset('assets/images/police_logo.png', height: 60)),
            ]),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    const Text('Police Registration', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Create your officer account', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                    const SizedBox(height: 20),

                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(labelText: 'Full Name', prefixIcon: const Icon(Icons.person), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                      validator: (v) => (v == null || v.trim().length < 2) ? 'Name required' : null,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(labelText: 'Email', prefixIcon: const Icon(Icons.email_outlined), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                      validator: (v) => (v == null || !v.contains('@')) ? 'Valid email required' : null,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        suffixIcon: IconButton(icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _obscurePassword = !_obscurePassword)),
                      ),
                      validator: (v) => (v == null || v.length < 6) ? 'Min 6 chars' : null,
                    ),
                    const SizedBox(height: 12),

                    // Rank
                    DropdownButtonFormField<String>(
                      value: _selectedRank,
                      decoration: InputDecoration(labelText: 'Rank', prefixIcon: const Icon(Icons.military_tech), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                      items: _ranks.map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 14)))).toList(),
                      onChanged: (v) => setState(() => _selectedRank = v),
                      validator: (v) => v == null ? 'Select rank' : null,
                    ),
                    const SizedBox(height: 12),

                    // District
                    if (!_loadingHierarchy)
                      DropdownButtonFormField<String>(
                        value: _selectedDistrict,
                        decoration: InputDecoration(labelText: 'District', prefixIcon: const Icon(Icons.location_city), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                        items: _districts.map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 14)))).toList(),
                        onChanged: (v) {
                          setState(() { _selectedDistrict = v; _selectedStation = null; _stations = []; });
                          if (v != null) _loadStations(v);
                        },
                      ),
                    if (_loadingHierarchy) const Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator(strokeWidth: 2)),
                    const SizedBox(height: 12),

                    // Station
                    if (_stations.isNotEmpty)
                      DropdownButtonFormField<String>(
                        value: _selectedStation,
                        decoration: InputDecoration(labelText: 'Station', prefixIcon: const Icon(Icons.local_police), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                        items: _stations.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 14)))).toList(),
                        onChanged: (v) => setState(() => _selectedStation = v),
                      ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity, height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _register,
                        style: ElevatedButton.styleFrom(backgroundColor: navy, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
                            : const Text('Register', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text('Already have an account?', style: TextStyle(color: Colors.grey.shade600)),
                      TextButton(onPressed: () => context.go('/login'), child: const Text('Sign In', style: TextStyle(color: navy, fontWeight: FontWeight.bold))),
                    ]),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
