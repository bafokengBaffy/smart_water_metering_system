import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:intl/intl.dart'; // For timestamp formatting
import 'analysis_screen.dart';
import 'settings_screen.dart';
import 'home_screen.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  PaymentScreenState createState() => PaymentScreenState();
}

class PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  String _selectedMobileProvider = 'M-Pesa';
  bool _isProcessing = false;
  late final StreamController<String> _paymentStatusController;

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  final List<String> mobileProviders = ['M-Pesa', 'EcoCash'];

  // Load API configuration from environment variables
  static final Map<String, dynamic> _apiConfig = {
    'mpesa': {
      'consumerKey': dotenv.env['CONSUMER_KEY']!,
      'consumerSecret': dotenv.env['CONSUMER_SECRET']!,
      'businessShortCode': dotenv.env['BUSINESS_SHORT_CODE'] ?? '174379',
      'passKey': dotenv.env['PASS_KEY'] ?? 'lsEGVDKEuwR3dA50zQyOjb1yNSOb',
      'env': dotenv.env['MPESA_ENV'] ?? 'production',
      'tokenUrl':
          dotenv.env['TOKEN_URL'] ??
          'https://api.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials',
      'stkPushUrl':
          dotenv.env['STK_PUSH_URL'] ??
          'https://api.safaricom.co.ke/mpesa/stkpush/v1/processrequest',
    },
    'ecocash': {
      'apiKey': dotenv.env['ECOCASH_API_KEY'] ?? '',
      'merchantId': dotenv.env['ECOCASH_MERCHANT_ID'] ?? '',
      'env': dotenv.env['ECOCASH_ENV'] ?? 'sandbox',
      'paymentUrl':
          dotenv.env['ECOCASH_PAYMENT_URL'] ??
          'https://sandbox.ecocash.co.ls/api/payments',
    },
  };

  @override
  void initState() {
    super.initState();
    _paymentStatusController = StreamController<String>.broadcast();
  }

  @override
  void dispose() {
    _paymentStatusController.close();
    _phoneController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mobile Payment'),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isProcessing ? _buildPaymentProcessing() : _buildPaymentForm(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildPaymentForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildProviderDropdown(),
            const SizedBox(height: 20),
            _buildPhoneField(),
            const SizedBox(height: 20),
            _buildAmountField(),
            const SizedBox(height: 30),
            _buildTransactionPreview(),
            const SizedBox(height: 40),
            _buildPayButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedMobileProvider,
      items:
          mobileProviders.map((provider) {
            return DropdownMenuItem(value: provider, child: Text(provider));
          }).toList(),
      onChanged: (value) => setState(() => _selectedMobileProvider = value!),
      decoration: InputDecoration(
        labelText: 'Payment Method',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.grey[200],
      ),
    );
  }

  Widget _buildPhoneField() {
    return TextFormField(
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      decoration: InputDecoration(
        labelText: 'Mobile Number',
        prefixText: '+266 ',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.grey[200],
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Enter phone number';
        if (value.length != 8) return 'Must be 8 digits';
        return null;
      },
    );
  }

  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: 'Amount (LSL)',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.grey[200],
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Enter amount';
        if (double.tryParse(value) == null) return 'Invalid amount';
        return null;
      },
    );
  }

  Widget _buildTransactionPreview() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Total:', style: TextStyle(fontSize: 16)),
            Text(
              'LSL ${_amountController.text.isEmpty ? '0.00' : _amountController.text}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPayButton() {
    return ElevatedButton(
      onPressed: _isProcessing ? null : _initiatePayment,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: const Text('CONFIRM PAYMENT'),
    );
  }

  Widget _buildPaymentProcessing() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          StreamBuilder<String>(
            stream: _paymentStatusController.stream,
            builder: (context, snapshot) {
              return Text(
                snapshot.data ?? 'Processing payment...',
                style: const TextStyle(fontSize: 16),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _initiatePayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isProcessing = true);
    _paymentStatusController.add('Validating payment details...');

    try {
      final paymentData = {
        'phone': _phoneController.text,
        'amount': _amountController.text,
        'provider': _selectedMobileProvider.toLowerCase(),
      };

      final result = await MobilePaymentService.processPayment(
        paymentData: paymentData,
        config: _apiConfig,
        statusCallback: _paymentStatusController.add,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: result['success'] ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Widget _buildBottomNav() {
    return SafeArea(
      child: Container(
        height: 70,
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey, width: 0.3)),
        ),
        child: BottomAppBar(
          padding: EdgeInsets.zero,
          elevation: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavButton(
                icon: Icons.home,
                label: "Home",
                isActive: false,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HomeScreen(),
                  ),
                )
              ),
              _NavButton(
                icon: Icons.analytics,
                label: "Stats",
                isActive: false,
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AnalysisScreen(),
                      ),
                    ),
              ),
              _NavButton(
                icon: Icons.payment,
                label: "Pay",
                isActive: true,
                onTap: () {},
              ),
              _NavButton(
                icon: Icons.settings,
                label: "Settings",
                isActive: false,
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.label,
    this.isActive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color:
              isActive
                  ? Colors.blueAccent.withAlpha((0.2 * 255).toInt())
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? Colors.blueAccent : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.blueAccent : Colors.grey,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MobilePaymentService {
  static Future<Map<String, dynamic>> processPayment({
    required Map<String, dynamic> paymentData,
    required Map<String, dynamic> config,
    required Function(String) statusCallback,
  }) async {
    final provider = paymentData['provider'];
    final amount = paymentData['amount'];
    final phone = paymentData['phone'];

    statusCallback('Connecting to ${provider.toUpperCase()}...');

    if (provider == 'mpesa') {
      return await _processMpesaPayment(
        phone: phone,
        amount: amount,
        config: config['mpesa'],
        statusCallback: statusCallback,
      );
    } else if (provider == 'ecocash') {
      return await _processEcoCashPayment(
        phone: phone,
        amount: amount,
        config: config['ecocash'],
        statusCallback: statusCallback,
      );
    }
    return {'success': false, 'message': 'Invalid payment provider'};
  }

  static Future<Map<String, dynamic>> _processMpesaPayment({
    required String phone,
    required String amount,
    required Map<String, dynamic> config,
    required Function(String) statusCallback,
  }) async {
    try {
      statusCallback('Authenticating with M-Pesa...');
      final token = await _getMpesaToken(
        config['consumerKey'],
        config['consumerSecret'],
        config['tokenUrl'],
      );

      statusCallback('Processing transaction...');

      // Generate timestamp in the required format: yyyyMMddHHmmss
      final timestamp = DateFormat(
        "yyyyMMddHHmmss",
      ).format(DateTime.now().toUtc());

      final password = base64.encode(
        utf8.encode(
          '${config['businessShortCode']}${config['passKey']}$timestamp',
        ),
      );

      final response = await http.post(
        Uri.parse(config['stkPushUrl']),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          "BusinessShortCode": config['businessShortCode'],
          "Password": password,
          "Timestamp": timestamp,
          "TransactionType": "CustomerPayBillOnline",
          "Amount": amount,
          "PartyA": "266$phone",
          "PartyB": config['businessShortCode'],
          "PhoneNumber": "266$phone",
          "CallBackURL":
              dotenv.env['CALLBACK_URL'] ??
              "https://52ae-197-189-137-133.ngrok-free.app/mpesa-callback",
          "AccountReference": "MobilePaymentLS",
          "TransactionDesc": "Lesotho Payment",
        }),
      );

      final responseData = json.decode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Payment initiated. Confirm on your M-Pesa',
        };
      } else {
        return {'success': false, 'message': _parseMpesaError(responseData)};
      }
    } catch (e) {
      return {'success': false, 'message': 'Payment failed: ${e.toString()}'};
    }
  }

  static Future<String> _getMpesaToken(
    String consumerKey,
    String consumerSecret,
    String tokenUrl,
  ) async {
    final authStr = base64.encode(utf8.encode('$consumerKey:$consumerSecret'));
    final response = await http.get(
      Uri.parse(tokenUrl),
      headers: {'Authorization': 'Basic $authStr'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body)['access_token'];
    }
    throw Exception('Authentication failed: ${response.body}');
  }

  static String _parseMpesaError(dynamic errorData) {
    return errorData['errorMessage'] ?? 'Payment processing failed';
  }

  static Future<Map<String, dynamic>> _processEcoCashPayment({
    required String phone,
    required String amount,
    required Map<String, dynamic> config,
    required Function(String) statusCallback,
  }) async {
    try {
      statusCallback('Connecting to EcoCash...');

      final response = await http.post(
        Uri.parse(config['paymentUrl']),
        headers: {
          'X-API-KEY': config['apiKey'],
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'merchant_id': config['merchantId'],
          'subscriber_id': phone,
          'amount': amount,
          'currency': 'LSL',
          'reference': 'PAY-${DateTime.now().millisecondsSinceEpoch}',
        }),
      );

      final responseData = json.decode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Payment initiated. Confirm on your EcoCash menu',
        };
      } else {
        return {'success': false, 'message': _parseEcoCashError(responseData)};
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'EcoCash payment failed: ${e.toString()}',
      };
    }
  }

  static String _parseEcoCashError(dynamic errorData) {
    return errorData['error']['message'] ?? 'EcoCash payment failed';
  }
}
