import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  PaymentScreenState createState() => PaymentScreenState();
}

class PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  int _selectedMethod = 0; // 0=Mobile, 1=Bank, 2=Card
  String _selectedMobileProvider = 'M-Pesa';
  String _selectedBank = 'FNB';
  String _cardType = '';

  // Controllers
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _branchController = TextEditingController();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final TextEditingController _cardNameController = TextEditingController();

  // Payment providers
  final List<String> mobileProviders = ['M-Pesa', 'EcoCash'];
  final List<String> banks = [
    'FNB',
    'Standard Bank',
    'Post Bank',
    'NetBank'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Make Payment'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Payment Method Selector
              _buildMethodSelector(),
              const SizedBox(height: 20),

              // Dynamic Form Sections
              _buildMobileMoneySection(),
              _buildBankTransferSection(),
              _buildCardSection(),

              // Transaction Summary
              _buildTransactionSummary(),
              const SizedBox(height: 30),

              // Payment Button
              _buildPayButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMethodSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _methodChoice(0, Icons.phone_iphone, 'Mobile'),
        _methodChoice(1, Icons.account_balance, 'Bank'),
        _methodChoice(2, Icons.credit_card, 'Card'),
      ],
    );
  }

  Widget _methodChoice(int index, IconData icon, String text) {
    return ChoiceChip(
      selected: _selectedMethod == index,
      onSelected: (selected) => setState(() => _selectedMethod = index),
      avatar: Icon(icon, size: 20),
      label: Text(text),
      selectedColor: Colors.blue[100],
    );
  }

  Widget _buildMobileMoneySection() {
    return Visibility(
      visible: _selectedMethod == 0,
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            value: _selectedMobileProvider,
            items: mobileProviders
                .map((provider) => DropdownMenuItem(
              value: provider,
              child: Row(
                children: [
                  Image.asset(
                    'assets/${provider.toLowerCase()}.png',
                    width: 30,
                    height: 30,
                  ),
                  const SizedBox(width: 10),
                  Text(provider),
                ],
              ),
            ))
                .toList(),
            onChanged: (value) =>
                setState(() => _selectedMobileProvider = value!),
            decoration: const InputDecoration(labelText: 'Mobile Provider'),
          ),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              prefixText: '+263 ',
              icon: Icon(Icons.phone),
            ),
            validator: (value) =>
            value!.length != 9 ? 'Enter 9-digit number' : null,
          ),
          _buildAmountField(),
        ],
      ),
    );
  }

  Widget _buildBankTransferSection() {
    return Visibility(
      visible: _selectedMethod == 1,
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            value: _selectedBank,
            items: banks
                .map((bank) => DropdownMenuItem(
              value: bank,
              child: Row(
                children: [
                  Image.asset(
                    'assets/${bank.toLowerCase().replaceAll(' ', '_')}.png',
                    width: 30,
                    height: 30,
                  ),
                  const SizedBox(width: 10),
                  Text(bank),
                ],
              ),
            ))
                .toList(),
            onChanged: (value) => setState(() => _selectedBank = value!),
            decoration: const InputDecoration(labelText: 'Select Bank'),
          ),
          TextFormField(
            controller: _accountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Account Number',
              icon: Icon(Icons.numbers),
            ),
          ),
          TextFormField(
            controller: _branchController,
            decoration: const InputDecoration(
              labelText: 'Branch Code',
              icon: Icon(Icons.location_city),
            ),
          ),
          _buildAmountField(),
        ],
      ),
    );
  }

  Widget _buildCardSection() {
    return Visibility(
      visible: _selectedMethod == 2,
      child: Column(
        children: [
          TextFormField(
            controller: _cardNumberController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(19),
              CardNumberFormatter(),
            ],
            decoration: InputDecoration(
              labelText: 'Card Number',
              prefixIcon: _cardType.isNotEmpty
                  ? Image.asset(
                'assets/${_cardType.toLowerCase()}.png',
                width: 30,
                height: 30,
              )
                  : null,
              icon: const Icon(Icons.credit_card),
            ),
            onChanged: (value) => _detectCardType(value),
            validator: (value) => value!.length < 16 ? 'Invalid card' : null,
          ),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _expiryController,
                  keyboardType: TextInputType.datetime,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                    CardExpiryFormatter(),
                  ],
                  decoration: const InputDecoration(
                      labelText: 'MM/YY', icon: Icon(Icons.calendar_today)),
                ),
              ),
              Expanded(
                child: TextFormField(
                  controller: _cvvController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  decoration: const InputDecoration(
                      labelText: 'CVV', icon: Icon(Icons.lock)),
                  validator: (value) =>
                  value!.length != 3 ? 'Invalid CVV' : null,
                ),
              ),
            ],
          ),
          TextFormField(
            controller: _cardNameController,
            decoration: const InputDecoration(
                labelText: 'Cardholder Name', icon: Icon(Icons.person)),
          ),
          _buildAmountField(),
        ],
      ),
    );
  }

  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountController,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: 'Amount (USD)',
        prefixIcon: Icon(Icons.attach_money),
      ),
      validator: (value) => value!.isEmpty ? 'Enter amount' : null,
    );
  }

  Widget _buildTransactionSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Total to Pay:', style: TextStyle(fontSize: 16)),
            Text(
              '\$${_amountController.text.isEmpty ? '0.00' : _amountController.text}',
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPayButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 15),
          backgroundColor: Colors.blueAccent,
        ),
        onPressed: _processPayment,
        child: const Text('PAY NOW', style: TextStyle(fontSize: 18)),
      ),
    );
  }

  void _detectCardType(String number) {
    if (number.startsWith(RegExp(r'^4'))) {
      setState(() => _cardType = 'Visa');
    } else if (number.startsWith(RegExp(r'^5[1-5]'))) {
      setState(() => _cardType = 'Mastercard');
    } else {
      setState(() => _cardType = '');
    }
  }

  void _processPayment() {
    if (_formKey.currentState!.validate()) {
      final currentContext = context;

      showDialog(
        context: currentContext,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Processing Payment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Please wait while we process your payment...'),
            ],
          ),
        ),
      );

      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        Navigator.pop(currentContext);
        _showConfirmation(currentContext);
      });
    }
  }

  void _showConfirmation(BuildContext context) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment of \$${_amountController.text} successful!'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
    _clearFields();
  }

  void _clearFields() {
    _phoneController.clear();
    _amountController.clear();
    _accountController.clear();
    _branchController.clear();
    _cardNumberController.clear();
    _expiryController.clear();
    _cvvController.clear();
    _cardNameController.clear();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _amountController.dispose();
    _accountController.dispose();
    _branchController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _cardNameController.dispose();
    super.dispose();
  }
}

// Custom formatters
class CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text.replaceAll(RegExp(r'\D'), '');
    var formatted = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) formatted.write(' ');
      formatted.write(text[i]);
    }

    return TextEditingValue(
      text: formatted.toString(),
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class CardExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (text.length >= 3) {
      text = '${text.substring(0, 2)}/${text.substring(2)}';
    }
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}