import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:solana/encoder.dart';
import 'package:solana/solana.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _publicKey;
  String? _balance;
  SolanaClient? _client;
  final _storage = const FlutterSecureStorage();
  final _addressController = TextEditingController();
  final _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeWallet();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wallet'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildWalletCard(),
            const SizedBox(height: 16),
            _buildBalanceCard(),
            const SizedBox(height: 16),
            _buildTransactionCard(),
            const SizedBox(height: 16),
            _buildLogoutCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Wallet Address',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    _publicKey ?? 'Loading...',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    if (_publicKey != null) {
                      Clipboard.setData(
                          ClipboardData(text: _publicKey.toString()));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Address copied!')),
                      );
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Balance',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_balance ?? 'Loading...'),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _getBalance,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Recipient Address',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount to Send',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _showPasswordDialog,
              child: const Text('Send'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Log out'),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                GoRouter.of(context).go('/');
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _initializeWallet() async {
    final mnemonic = await _storage.read(key: 'mnemonic');
    if (mnemonic == null) return;

    final keypair = await Ed25519HDKeyPair.fromMnemonic(mnemonic);
    setState(() {
      _publicKey = keypair.publicKey.toBase58();
    });

    await dotenv.load(fileName: '.env');
    _client = SolanaClient(
      rpcUrl: Uri.parse(dotenv.env['QUICKNODE_RPC_URL']!),
      websocketUrl: Uri.parse(dotenv.env['QUICKNODE_RPC_WSS']!),
    );

    _getBalance();
  }

  Future<void> _getBalance() async {
    if (_client == null || _publicKey == null) return;

    setState(() {
      _balance = null;
    });

    try {
      final balanceResult = await _client!.rpcClient
          .getBalance(_publicKey!, commitment: Commitment.confirmed);
      final balance = balanceResult.value / lamportsPerSol;
      setState(() {
        _balance = balance.toString();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch balance: $e')),
      );
    }
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
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final storedPassword = await _storage.read(key: 'password');
                if (passwordController.text == storedPassword) {
                  Navigator.pop(context);
                  _sendTransaction();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid password')),
                  );
                }
              },
              child: const Text('Verify'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendTransaction() async {
    if (_client == null || _publicKey == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Client or public key not initialized')),
      );
      return;
    }

    final recipient = _addressController.text;
    final amount = double.tryParse(_amountController.text) ?? 0;

    if (recipient.isEmpty || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid address or amount')),
      );
      return;
    }

    try {
      final mnemonic = await _storage.read(key: 'mnemonic');
      if (mnemonic == null) throw Exception('Mnemonic not found');

      final keypair = await Ed25519HDKeyPair.fromMnemonic(mnemonic);

      final instruction = SystemInstruction.transfer(
        fundingAccount: keypair.publicKey,
        recipientAccount: Ed25519HDPublicKey.fromBase58(recipient),
        lamports: (amount * lamportsPerSol).toInt(),
      );

      final message = Message.only(instruction);
      final blockhash = await _client!.rpcClient.getLatestBlockhash();

      final compiled = message.compile(
        recentBlockhash: blockhash.value.blockhash,
        feePayer: keypair.publicKey,
      );

      final signature = await keypair.sign(compiled.toByteArray());

      final tx = SignedTx(
        signatures: [
          Signature(
            signature.bytes,
            publicKey: keypair.publicKey,
          )
        ],
        compiledMessage: compiled,
      );

      final result = await _client!.rpcClient.sendTransaction(tx.encode());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Transaction successful: $result')),
      );
      _getBalance();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Transaction failed: $e')),
      );
    }
  }
}
