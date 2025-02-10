import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_bitcoin/flutter_bitcoin.dart' hide Transaction;
import 'package:hex/hex.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final metamaskApiKey = dotenv.get('METAMASK_API_KEY');
final rpcUrl = 'https://sepolia.infura.io/v3/$metamaskApiKey';
final web3Client =
    Web3Client(rpcUrl, Client());

Future<String> signTransaction({
  required EthPrivateKey privateKey,
  required Transaction transaction,
}) async {
  try {
    var result = await web3Client.signTransaction(
      privateKey,
      transaction,
      chainId: 11155111,
    );

    // day 13 changes
    if (transaction.isEIP1559) {
      result = prependTransactionType(0x02, result);
    } // end

    return HEX.encode(result);
  } catch (e) {
    rethrow;
  }
}

Future<String> sendRawTransaction(String tx) async {
  try {
    final txHash =
        await web3Client.sendRawTransaction(Uint8List.fromList(HEX.decode(tx)));
    return txHash;
  } catch (e) {
    rethrow;
  }
}

String sampleBitcoinTx(HDWallet btcWallet) {
  final txb = TransactionBuilder();
  txb.setVersion(1);
  // previous transaction output, has 15000 satoshis
  txb.addInput(
      '61d520ccb74288c96bc1a2b20ea1c0d5a704776dd0164a396efec3ea7040349d', 0);
  // (in)15000 - (out)12000 = (fee)3000, this is the miner fee
  txb.addOutput('1cMh228HTCiwS8ZsaakH8A8wze1JR5ZsP', 12000);
  txb.sign(vin: 0, keyPair: ECPair.fromWIF(btcWallet.wif!));
  // return txb.build().toHex();
  return ""; // disable this for now
}

Future<String> sampleEthereumTx(HDWallet ethWallet) async {
  final ethPriKey = EthPrivateKey.fromHex(ethWallet.privKey!);
  return await signTransaction(
    privateKey: ethPriKey,
    transaction: Transaction(
      from: ethPriKey.address,
      // Send to yourself
      to: ethPriKey.address, //EthereumAddress.fromHex("0xE2Dc3214f7096a94077E71A3E218243E289F1067"),
      value: EtherAmount.fromBase10String(EtherUnit.gwei, "100"),
    ),
  );
}

// day 13 changes (to end of file)
const abi = [
  {
    "inputs": [
      {"internalType": "address", "name": "account", "type": "address"}
    ],
    "name": "balanceOf",
    "outputs": [
      {"internalType": "uint256", "name": "", "type": "uint256"}
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "decimals",
    "outputs": [
      {"internalType": "uint8", "name": "", "type": "uint8"}
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {"internalType": "address", "name": "recipient", "type": "address"},
      {"internalType": "uint256", "name": "amount", "type": "uint256"}
    ],
    "name": "transfer",
    "outputs": [
      {"internalType": "bool", "name": "", "type": "bool"}
    ],
    "stateMutability": "nonpayable",
    "type": "function"
  },
];

// https://ethereum.stackexchange.com/a/114778
Future<double> readTokenBalance(
    String contractAddress, String walletAddress) async {
  try {
    final contract = DeployedContract(
      ContractAbi.fromJson(jsonEncode(abi), 'ERC20'),
      EthereumAddress.fromHex(contractAddress),
    );
    final balanceFunction = contract.function('balanceOf');
    final balance = await web3Client.call(
      contract: contract,
      function: balanceFunction,
      params: [EthereumAddress.fromHex(walletAddress)],
    );
    print('balance: $balance');
    final rawBalance = BigInt.parse(balance.first.toString());
    final decimanls = await web3Client.call(
      contract: contract,
      function: contract.function('decimals'),
      params: [],
    );
    final decimals = int.parse(decimanls.first.toString());
    return rawBalance / BigInt.from(10).pow(decimals);
  } catch (e) {
    rethrow;
  }
}

Future<EtherAmount> getMaxPriorityFee() async {
  try {
    final response = await post(
      Uri.parse(rpcUrl),
      body: jsonEncode({
        "jsonrpc": "2.0",
        "method": "eth_maxPriorityFeePerGas",
        "params": [],
        "id": 1,
      }),
    );
    final json = jsonDecode(response.body);
    final result = json['result'];
    return EtherAmount.fromBigInt(EtherUnit.wei, BigInt.parse(result));
  } catch (e) {
    rethrow;
  }
}

Future<String> sendTokenTransaction({
  required EthPrivateKey privateKey,
  required String contractAddress,
  required String toAddress,
  required BigInt amount,
}) async {
  try {
    final contract = DeployedContract(
      ContractAbi.fromJson(jsonEncode(abi), 'ERC20'),
      EthereumAddress.fromHex(contractAddress),
    );
    final transferFunction = contract.function('transfer');
    final transferTx = Transaction.callContract(
      contract: contract,
      function: transferFunction,
      parameters: [EthereumAddress.fromHex(toAddress), amount],
    );
    final tx = await signTransaction(
      privateKey: privateKey,
      transaction: transferTx,
    );
    final txHash = await sendRawTransaction(tx);
    return txHash;
  } catch (e) {
    rethrow;
  }
}