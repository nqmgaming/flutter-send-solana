import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final passwordController = TextEditingController();
  bool validationFailed = false;
  String? password;
  bool _loading = true;
  String? key;
  final storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();

    _checkForSavedLogin().then((credentialsFound) {
      if (!credentialsFound && mounted) {
        GoRouter.of(context).go("/setup");
      } else {
        setState(() {
          _loading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/QuickNodeLogo.png',
                  width: 100,
                ),
                const SizedBox(height: 16),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value != password) {
                            setState(() {
                              validationFailed = true;
                            });
                            return 'Invalid Password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      if (validationFailed)
                        const Text(
                          'Invalid Password',
                          style: TextStyle(color: Colors.red),
                        ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _onSubmit,
                        child: const Text('Login'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => onDifferentAccountPressed(context),
                  child: const Text('Use different Account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _checkForSavedLogin() async {
    key = await storage.read(key: 'mnemonic');
    password = await storage.read(key: 'password');
    return key != null && password != null;
  }

  Future<void> onDifferentAccountPressed(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Warning'),
          content: const Text(
              'Access to the current account will be lost if the seed phrase is lost.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                GoRouter.of(context).go("/setup");
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _onSubmit() {
    if (_formKey.currentState!.validate()) {
      GoRouter.of(context).go("/home");
    }
  }
}
