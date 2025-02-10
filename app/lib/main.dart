import 'package:flutter/material.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:flutter_bitcoin/flutter_bitcoin.dart' hide Transaction;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:web3dart/web3dart.dart';
import 'package:wallet/wallet.dart' as wallet;

import 'tx.dart';

void main() {
  dotenv.load(fileName: '.env');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

// https://etherscan.io/address/0x1f9840a85d5af5bf1d1762f925bdaddc4201f984
const uniContractAddress = "0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984";

class _MyHomePageState extends State<MyHomePage> {
  TextEditingController mnemonicController = TextEditingController();
  String mnemonic = "";
  HDWallet? btcWallet, ethWallet, tronWallet;
  String? btcTx, ethTx, ethTxHash;
  // day 13
  String? ethAddress;
  double? uniBalance; // end

  void refreshMnemonic() {
    print('Got mnemonic: ${mnemonicController.text}');
    final newMnemonic = mnemonicController.text;
    if (bip39.validateMnemonic(newMnemonic)) {
      final seed = bip39.mnemonicToSeed(newMnemonic);
      final hdWallet = HDWallet.fromSeed(seed);
      setState(() {
        mnemonic = newMnemonic;
        btcWallet = hdWallet.derivePath("m/44'/0'/0'/0/0");
        ethWallet = hdWallet.derivePath("m/44'/60'/0'/0/0");  // eth mainnet derivation path works for sepolia as well
        tronWallet = hdWallet.derivePath("m/44'/195'/0'/0/0");

        // day 12
        // disabled because this causes an error (Unsupported operation: Uint64 accessor not supported by dart2js.)
        // btcTx = sampleBitcoinTx(btcWallet!);
        
        // day 12 (disabled for day 13)
        // sampleEthereumTx(ethWallet!).then((tx) {
        //   setState(() {
        //     ethTx = tx;
        //   });
        // });

        // day 13
        final ethPriKey = EthPrivateKey.fromHex(ethWallet!.privKey!);
        ethAddress = ethPriKey.address.hex;
        readTokenBalance(uniContractAddress, ethAddress!).then((balance) {
          setState(() {
            uniBalance = balance;
          });
        }); // end

      });
    } else {
      setState(() {
        btcWallet = null;
        ethWallet = null;
        tronWallet = null;
        btcTx = null;
        ethTx = null;
        ethTxHash = null;
      });
    }
  }

  // day 13
  void sendToken() {
    final ethPriKey = EthPrivateKey.fromHex(ethWallet!.privKey!);
    sendTokenTransaction(
      privateKey: ethPriKey,
      contractAddress: uniContractAddress,
      // send to yourself
      toAddress: ethAddress!, //"0xE2Dc3214f7096a94077E71A3E218243E289F1067",
      amount: BigInt.from(100),
    ).then((txHash) {
      setState(() {
        ethTxHash = txHash;
      });
    });
  } // end

  @override
  void initState() {
    super.initState();
    refreshMnemonic();
  }

  @override
  Widget build(BuildContext context) {
    final btcAddress = btcWallet?.address;

    // final ethPriKey = ethWallet?.privKey == null
    //     ? null
    //     : EthPrivateKey.fromHex(ethWallet!.privKey!);
    // final ethAddress = ethPriKey?.address.hex; 

    String? tronAddress;
    if (tronWallet != null) {
      final tronPrivateKey =
          wallet.PrivateKey(BigInt.parse(tronWallet!.privKey!, radix: 16));
      final tronPubKey = wallet.tron.createPublicKey(tronPrivateKey);
      tronAddress = wallet.tron.createAddress(tronPubKey);
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                controller: mnemonicController,
                decoration: const InputDecoration(
                  labelText: 'Enter mnemonic',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                onChanged: (text) {
                  refreshMnemonic();
                },
              ),
            ),
            const SizedBox(height: 20),
            if (mnemonic.isNotEmpty) ...[
              if (btcAddress != null) Text('Bitcoin address: $btcAddress'),
              if (ethAddress != null) Text('Ethereum address: $ethAddress'),
              if (tronAddress != null) Text('Tron address: $tronAddress'),
              const SizedBox(height: 20),
              if (btcTx != null) Text('Bitcoin tx: $btcTx'),
              const SizedBox(height: 10),
              if (ethTx != null) Text('Ethereum tx: $ethTx'),
              if (ethTxHash != null) Text('Ethereum tx hash: $ethTxHash'),
              if (ethTx != null)
                SizedBox(
                  width: 200,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      final txHash = await sendRawTransaction(ethTx!);
                      setState(() {
                        ethTxHash = txHash;
                      });
                    },
                    child: const Text('Day 12 Broadcast tx'),
                  ),
                ),
              // day 13
              if (uniBalance != null) Text('UNI balance: $uniBalance'),
              if (uniBalance != null)
                SizedBox(
                  width: 200,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: sendToken,
                    child: const Text('Day 13 Send Token Tx'),
                  ),
                ) //end
            ],
          ],
        ),
      ),
    );
  }
}