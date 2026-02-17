import 'package:flutter/material.dart';

void main() {
  runApp(const TestApp());
}

class TestApp extends StatelessWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test Period Selector',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const TestPeriodSelector(),
    );
  }
}

class TestPeriodSelector extends StatefulWidget {
  const TestPeriodSelector({super.key});

  @override
  State<TestPeriodSelector> createState() => _TestPeriodSelectorState();
}

class _TestPeriodSelectorState extends State<TestPeriodSelector> {
  String selectedPeriod = 'thisMonth';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Period Selector'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: Colors.blue.shade700,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Période d\'analyse',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            
            // Test des chips de période
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildPeriodChip('today', 'Aujourd\'hui'),
                _buildPeriodChip('thisWeek', 'Cette semaine'),
                _buildPeriodChip('thisMonth', 'Ce mois'),
                _buildPeriodChip('lastMonth', 'Mois dernier'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodChip(String period, String label) {
    final isSelected = selectedPeriod == period;
    
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.blue.shade700 : Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            selectedPeriod = period;
          });
        }
      },
      backgroundColor: Colors.white.withOpacity(0.1),
      selectedColor: Colors.white,
      checkmarkColor: Colors.blue.shade700,
      side: BorderSide(
        color: isSelected ? Colors.white : Colors.white.withOpacity(0.3),
      ),
      showCheckmark: true,
    );
  }
}