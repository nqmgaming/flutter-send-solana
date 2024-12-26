import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:web3_login/pages/generate_phrase_page.dart';
import 'package:web3_login/pages/home_page.dart';
import 'package:web3_login/pages/input_phrase_page.dart';
import 'package:web3_login/pages/login_page.dart';
import 'package:web3_login/pages/setup_account_page.dart';
import 'package:web3_login/pages/setup_password_page.dart';

void main() {
  runApp(const MyApp());
}

final GoRouter _router = GoRouter(routes: <GoRoute>[
  GoRoute(
      path: '/',
      builder: (context, state) {
        return const LoginScreen();
      }),
  GoRoute(
      path: '/setup',
      builder: (context, state) {
        return const SetUpScreen();
      }),
  GoRoute(
      path: '/inputPhrase',
      builder: (context, state) {
        return const InputPhraseScreen();
      }),
  GoRoute(
      path: '/generatePhrase',
      builder: (context, state) {
        return const GeneratePhraseScreen();
      }),
  GoRoute(
      path: '/passwordSetup/:mnemonic',
      builder: (context, state) {
        return SetupPasswordScreen(mnemonic: state.pathParameters["mnemonic"]);
      }),
  GoRoute(
      path: '/home',
      builder: (context, state) {
        return const HomeScreen();
      }),
]);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      theme: ThemeData.dark().copyWith(
        elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueGrey[500],
        )),
        primaryColor: Colors.grey[900],
        scaffoldBackgroundColor: Colors.grey[850],
      ),
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
    );
  }
}
