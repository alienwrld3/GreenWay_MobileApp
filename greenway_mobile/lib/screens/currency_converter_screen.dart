import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// ─── THEME CONSTANTS ────────────────────────────────────────────────────────
const _bg       = Color(0xFF081C0E);
const _surface  = Color(0xFF0D2B18);
const _card     = Color(0xFF122E1C);
const _accent   = Color(0xFF52B788);
const _accentDim= Color(0xFF2D6A4F);
const _textPrim = Colors.white;
// ────────────────────────────────────────────────────────────────────────────

class CurrencyConverterScreen extends StatefulWidget {
  const CurrencyConverterScreen({super.key});

  @override
  State<CurrencyConverterScreen> createState() => _CurrencyConverterScreenState();
}

class _CurrencyConverterScreenState extends State<CurrencyConverterScreen> {
  final TextEditingController _amountController = TextEditingController();
  
  String _fromCurrency = 'IDR';
  String _toCurrency = 'USD';
  double _result = 0.0;
  bool _isLoading = true;
  String _errorMessage = '';
  Map<String, dynamic> _rates = {};
  String _lastUpdate = '';

  final List<String> _currencies = ['IDR', 'USD', 'EUR', 'JPY', 'MYR', 'SGD', 'GBP', 'AUD'];

  @override
  void initState() {
    super.initState();
    _fetchRealTimeRates(); 
  }

  Future<void> _fetchRealTimeRates() async {
    setState(() { _isLoading = true; _errorMessage = ''; });
    try {
      final response = await http.get(Uri.parse('https://open.er-api.com/v6/latest/USD')).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _rates = data['rates'];
          _lastUpdate = data['time_last_update_utc'].toString().substring(0, 16);
          _isLoading = false;
        });
        _calculateConversion(); 
      } else {
        throw Exception('Gagal mengambil data.');
      }
    } catch (e) {
      setState(() { _errorMessage = 'Koneksi error. Pastikan internet aktif.'; _isLoading = false; });
    }
  }

  void _calculateConversion() {
    if (_rates.isEmpty) return; 
    double amount = double.tryParse(_amountController.text) ?? 0.0;
    setState(() {
      double amountInUSD = amount / _rates[_fromCurrency];
      _result = amountInUSD * _rates[_toCurrency];
    });
  }

  void _swapCurrencies() {
    setState(() {
      String temp = _fromCurrency; _fromCurrency = _toCurrency; _toCurrency = temp;
    });
    _calculateConversion();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Kurs Mata Uang', style: TextStyle(color: _textPrim, fontWeight: FontWeight.w700)),
        backgroundColor: _bg,
        elevation: 0,
        iconTheme: const IconThemeData(color: _textPrim),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded, color: _accent), onPressed: _fetchRealTimeRates)
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: _accent))
        : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_errorMessage.isNotEmpty) {
      return Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.redAccent)));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(shape: BoxShape.circle, color: _accent.withOpacity(0.15)),
            child: const Icon(Icons.currency_exchange_rounded, size: 60, color: _accent),
          ),
          const SizedBox(height: 16),
          const Text('Hitung Nilai Donasi Hijau', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _textPrim)),
          const SizedBox(height: 4),
          Text('Update: $_lastUpdate UTC', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
          const SizedBox(height: 32),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: _textPrim, fontSize: 18, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              labelText: 'Masukkan Jumlah',
              labelStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
              filled: true, fillColor: _surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: _accentDim.withOpacity(0.3))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: _accentDim.withOpacity(0.3))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: _accent, width: 1.5)),
            ),
            onChanged: (value) => _calculateConversion(), 
          ),
          const SizedBox(height: 24),
          _buildConverterControls(),
          const SizedBox(height: 24),
          _buildResultDisplay(),
        ],
      ),
    );
  }

  Widget _buildConverterControls() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(20), border: Border.all(color: _accentDim.withOpacity(0.2))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildDropdown(_fromCurrency, (val) => setState(() => _fromCurrency = val!)),
          IconButton(
            icon: const Icon(Icons.swap_horiz_rounded, color: _accent, size: 28),
            onPressed: _swapCurrencies,
            style: IconButton.styleFrom(backgroundColor: _accent.withOpacity(0.1)),
          ),
          _buildDropdown(_toCurrency, (val) => setState(() => _toCurrency = val!)),
        ],
      ),
    );
  }

  Widget _buildResultDisplay() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_accentDim, _accent], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: _accent.withOpacity(0.2), blurRadius: 15, spreadRadius: 1)],
      ),
      child: Column(
        children: [
          Text('Hasil Konversi', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
          const SizedBox(height: 8),
          Text('${_result.toStringAsFixed(2)} $_toCurrency', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildDropdown(String value, ValueChanged<String?> onChanged) {
    return DropdownButton<String>(
      value: value,
      dropdownColor: _surface,
      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _accent),
      underline: const SizedBox(),
      style: const TextStyle(color: _textPrim, fontSize: 18, fontWeight: FontWeight.w600),
      items: _currencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
      onChanged: (val) { onChanged(val); _calculateConversion(); },
    );
  }
}