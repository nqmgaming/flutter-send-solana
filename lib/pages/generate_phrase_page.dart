import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:go_router/go_router.dart';

class GeneratePhraseScreen extends StatefulWidget {
  const GeneratePhraseScreen({super.key});

  @override
  State<GeneratePhraseScreen> createState() => _GeneratePhraseScreenState();
}

class _GeneratePhraseScreenState extends State<GeneratePhraseScreen> {
  String _mnemonic = "";
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    _generateMnemonic();
  }

  Future<void> _generateMnemonic() async {
    final mnemonic = bip39.generateMnemonic();
    setState(() {
      _mnemonic = mnemonic;
    });
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _mnemonic));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Recovery phrase copied to clipboard")),
    );
    setState(() {
      _copied = true;
    });
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.orange[700],
      padding: const EdgeInsets.all(8),
      child: const Text(
        'Important! Copy and save the recovery phrase in a secure location. This cannot be recovered later.',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildMnemonicDisplay() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Text(
        _mnemonic,
        textAlign: TextAlign.justify,
        style: const TextStyle(
          fontSize: 18,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildCopyButton() {
    return IconButton(
      onPressed: _copyToClipboard,
      icon: Icon(_copied ? Icons.check : Icons.copy),
    );
  }

  Widget _buildAcknowledgementCheckbox() {
    return Row(
      children: [
        Checkbox(
          value: _copied,
          onChanged: (value) {
            setState(() {
              _copied = value ?? false;
            });
          },
        ),
        const Text("I have stored the recovery phrase securely"),
      ],
    );
  }

  Widget _buildActionButton() {
    return ElevatedButton(
      onPressed: _copied
          ? () => GoRouter.of(context).go("/passwordSetup/$_mnemonic")
          : () => GoRouter.of(context).go("/"),
      child: Text(_copied ? 'Continue' : 'Go Back'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Recovery Phrase")),
      body: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(8),
              child: _buildMnemonicDisplay(),
            ),
          ),
          _buildCopyButton(),
          _buildAcknowledgementCheckbox(),
          const SizedBox(height: 10),
          _buildActionButton(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
