import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:bip39/bip39.dart' as bip39;

class InputPhraseScreen extends StatefulWidget {
  const InputPhraseScreen({super.key});

  @override
  State<InputPhraseScreen> createState() => _InputPhraseScreenState();
}

class _InputPhraseScreenState extends State<InputPhraseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _words = List<String>.filled(12, '');
  bool _validationFailed = false;

  void _onSubmit(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final wordsString = _words.join(' ');
      if (bip39.validateMnemonic(wordsString)) {
        GoRouter.of(context).go("/passwordSetup/$wordsString");
      } else {
        setState(() {
          _validationFailed = true;
        });
      }
    }
  }

  Widget _buildRecoveryPhraseInput() {
    return Form(
      key: _formKey,
      child: SizedBox(
        width: 300,
        child: GridView.builder(
          padding: const EdgeInsets.all(3),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 3,
          ),
          shrinkWrap: true,
          itemCount: 12,
          itemBuilder: (context, index) {
            return TextFormField(
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                hintText: '${index + 1}',
              ),
              onSaved: (value) {
                _words[index] = value?.trim() ?? '';
              },
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Required';
                }
                if (!RegExp(r"^[a-z]+$").hasMatch(value.trim())) {
                  return 'Invalid word';
                }
                return null;
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildValidationError() {
    if (!_validationFailed) return const SizedBox.shrink();
    return const Text(
      'Invalid recovery phrase. Please try again.',
      style: TextStyle(color: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Enter Recovery Phrase")),
      body: Center( // Centers the content vertically and horizontally
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Please enter your recovery phrase:',
                  style: TextStyle(fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                _buildRecoveryPhraseInput(),
                const SizedBox(height: 16),
                _buildValidationError(),
                const SizedBox(height: 24),
                SizedBox(
                  width: 200,
                  child: ElevatedButton(
                    onPressed: () => _onSubmit(context),
                    child: const Text('Continue'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
