// import 'package:flutter/material.dart';

// void main() {
//   runApp(MyApp());
// }

// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Test Dropdown Fix',
//       home: TestDropdownPage(),
//     );
//   }
// }

// class TestDropdownPage extends StatefulWidget {
//   @override
//   _TestDropdownPageState createState() => _TestDropdownPageState();
// }

// class _TestDropdownPageState extends State<TestDropdownPage> {
//   String? _selectedValue;
//   List<String> _items = ['admin', 'manager', 'cashier', 'stock_manager'];

//   @override
//   void initState() {
//     super.initState();
//     // Simuler le cas où la valeur initiale n'existe pas dans la liste
//     _selectedValue = 'non_existent_value';
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Test Dropdown Fix')),
//       body: Padding(
//         padding: EdgeInsets.all(16),
//         child: Column(
//           children: [
//             Text('Test du fix du dropdown avec valeur invalide'),
//             SizedBox(height: 20),

//             // Version avec fix
//             Text('Avec fix:'),
//             Builder(builder: (context) {
//               // S'assurer que la valeur sélectionnée existe dans la liste
//               final validSelectedValue = _items.contains(_selectedValue) ? _selectedValue : _items.first;

//               // Mettre à jour la sélection si nécessaire
//               if (_selectedValue != validSelectedValue) {
//                 WidgetsBinding.instance.addPostFrameCallback((_) {
//                   setState(() => _selectedValue = validSelectedValue);
//                 });
//               }

//               return DropdownButtonFormField<String>(
//                 value: validSelectedValue,
//                 decoration: InputDecoration(
//                   labelText: 'Rôle avec fix',
//                   border: OutlineInputBorder(),
//                 ),
//                 items: _items.map((item) {
//                   return DropdownMenuItem(
//                     value: item,
//                     child: Text(item),
//                   );
//                 }).toList(),
//                 onChanged: (value) => setState(() => _selectedValue = value),
//               );
//             }),

//             SizedBox(height: 20),
//             Text('Valeur actuelle: $_selectedValue'),

//             SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: () {
//                 setState(() {
//                   _selectedValue = 'another_invalid_value';
//                 });
//               },
//               child: Text('Tester avec valeur invalide'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
