import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:solana/base58.dart';
import 'package:solana/encoder.dart';
import 'package:solana/solana.dart';
import 'package:solana_mobile_client/solana_mobile_client.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _publicKey;
  String? _balance;
  SolanaClient? client;
  final storage = const FlutterSecureStorage();
  final addressController = TextEditingController();
  final balanceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _readPk();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wallet'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    const Text('Wallet Address',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(
                            width: 200,
                            child: Text(_publicKey ?? 'Loading...')),
                        IconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: () {
                            if (_publicKey != null) {
                              Clipboard.setData(
                                  ClipboardData(text: _publicKey!));
                            }
                          },
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    const Text('Balance',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_balance ?? 'Loading...'),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: () {
                            _getBalance();
                          },
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    TextField(
                      controller: addressController,
                      decoration: const InputDecoration(
                        labelText: 'Recipient Address',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: balanceController,
                      decoration: const InputDecoration(
                        labelText: 'Amount to Send',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _showPasswordDialog,
                      child: const Text('Send'),
                    ),
                  ],
                ),
              ),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Log out'),
                    IconButton(
                      icon: const Icon(Icons.logout),
                      onPressed: () {
                        GoRouter.of(context).go("/");
                      },
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _readPk() async {
    final mnemonic = await storage.read(key: 'mnemonic');
    if (mnemonic != null) {
      final keypair = await Ed25519HDKeyPair.fromMnemonic(mnemonic);
      setState(() {
        _publicKey = keypair.publicKey.toBase58();
      });
      _initializeClient();
    }
  }

  void _initializeClient() async {
    await dotenv.load(fileName: ".env");

    client = SolanaClient(
      rpcUrl: Uri.parse(dotenv.env['QUICKNODE_RPC_URL'].toString()),
      websocketUrl: Uri.parse(dotenv.env['QUICKNODE_RPC_WSS'].toString()),
    );
    _getBalance();
  }

  void _getBalance() async {
    setState(() {
      _balance = null;
    });
    final getBalance = await client?.rpcClient
        .getBalance(_publicKey!, commitment: Commitment.confirmed);
    final balance = (getBalance!.value) / lamportsPerSol;
    setState(() {
      _balance = balance.toString();
    });
  }

  void _showPasswordDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final passwordController = TextEditingController();
        return AlertDialog(
          title: const Text('Verify Password'),
          content: TextField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final storedPassword = await storage.read(key: 'password');
                if (passwordController.text == storedPassword) {
                  // Proceed with sending the transaction
                  _sendTransaction();
                } else {
                  // Show error message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid password')),
                  );
                }
                Navigator.pop(context);
              },
              child: const Text('Verify'),
            ),
          ],
        );
      },
    );
  }

  void _sendTransaction() async {
    final recipient = addressController.text;
    final amount = double.parse(balanceController.text) * lamportsPerSol;

    if (recipient.isEmpty || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter a valid address and amount')),
      );
      return;
    }

    if (client == null || _publicKey == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Client or public key not initialized')),
      );
      return;
    }

    try {
      final mnemonic = await storage.read(key: 'mnemonic');
      if (mnemonic == null) {
        throw Exception('Mnemonic not found in storage');
      }

      final keypair = await Ed25519HDKeyPair.fromMnemonic(mnemonic);

      // Create transaction instruction
      final instruction = SystemInstruction.transfer(
        fundingAccount: keypair.publicKey,
        recipientAccount: Ed25519HDPublicKey.fromBase58(recipient),
        lamports: amount.toInt(),
      );

      print(instruction.accounts);

      // // Sign and send transaction
      final message = Message.only(instruction);
      // final transaction = await client?.rpcClient.signAndSendTransaction(
      //   message,
      //   [keypair],
      //   onSigned: (signature) {
      //     ScaffoldMessenger.of(context).showSnackBar(
      //       SnackBar(content: Text('Transaction signed: $signature')),
      //     );
      //   },
      // );

      final blockhash =
          await client?.rpcClient.getLatestBlockhash().then((b) => b.value);
      final compiled = message.compile(
        recentBlockhash: blockhash?.blockhash ?? '',
        feePayer: keypair.publicKey,
      );

      final key = await keypair.sign(compiled.toByteArray());

      final tx = SignedTx(
        signatures: [
          Signature(
            key.bytes,
            publicKey: keypair.publicKey,
          )
        ],
        compiledMessage: compiled,
      );

      final transaction = await client?.rpcClient.sendTransaction(tx.encode());

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Transaction successful:' + transaction.toString())),
      );

      // Refresh balance
      _getBalance();
    } catch (e) {
      print("Transactionfailed: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Transaction failed: $e')),
      );
    }
  }
}
