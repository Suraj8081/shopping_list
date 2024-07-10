import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shopping_list/data/category.dart';
import 'package:shopping_list/data/grocery_item.dart';
import 'package:shopping_list/model/categories.dart';
import 'package:http/http.dart' as http;

class AddItem extends StatefulWidget {
  const AddItem({super.key});

  @override
  State<AddItem> createState() => _AddItemState();
}

class _AddItemState extends State<AddItem> {
  final _globalKey = GlobalKey<FormState>();
  String _enteredName = '';
  int _enteredQuantitiy = 1;
  Category _selectedcategory = categories[Categories.vegetables]!;
  bool isSending = false;

  void _saveItem() async {
    if (_globalKey.currentState!.validate()) {
      _globalKey.currentState!.save();
      setState(() {
        isSending = true;
      });
      final url = Uri.https('flutter-prep-f718c-default-rtdb.firebaseio.com',
          'shopping-list.json');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(
          {
            'name': _enteredName,
            'quantity': _enteredQuantitiy,
            'category': _selectedcategory.title,
          },
        ),
      );

      final resdata = json.decode(response.body);

      if (response.statusCode == 200) {
        if (!context.mounted) {
          return;
        }
        Navigator.pop(
          context,
          GroceryItem(
              id: resdata['name'],
              name: _enteredName,
              quantity: _enteredQuantitiy,
              category: _selectedcategory),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Item'),
      ),
      body: Form(
        key: _globalKey,
        child: Column(
          children: [
            TextFormField(
              maxLength: 50,
              decoration: const InputDecoration(
                label: Text('Name'),
              ),
              validator: (value) {
                if (value == null ||
                    value.isEmpty ||
                    value.trim().length == 1 ||
                    value.trim().length > 50) {
                  return 'Must be between 1 and 50 characters';
                }
                return null;
              },
              onSaved: (newValue) {
                _enteredName = newValue!;
              },
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      label: Text('Quantity'),
                    ),
                    initialValue: '1',
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null ||
                          value.isEmpty ||
                          int.tryParse(value) == null ||
                          int.tryParse(value)! <= 0) {
                        return 'Must be a valid positive number';
                      }
                      return null;
                    },
                    onSaved: (newValue) {
                      _enteredQuantitiy = int.tryParse(newValue!)!;
                    },
                  ),
                ),
                const SizedBox(
                  width: 8,
                ),
                Expanded(
                  child: DropdownButtonFormField(
                    value: _selectedcategory,
                    items: [
                      for (final category in categories.entries)
                        DropdownMenuItem(
                            value: category.value,
                            child: Row(
                              children: [
                                Container(
                                  height: 16,
                                  width: 16,
                                  color: category.value.color,
                                ),
                                const SizedBox(
                                  width: 8,
                                ),
                                Text(category.value.title),
                              ],
                            ))
                    ],
                    onChanged: (value) {
                      _selectedcategory = value!;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 20,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                    onPressed: isSending
                        ? null
                        : () {
                            _globalKey.currentState!.reset();
                          },
                    child: const Text('Reset')),
                ElevatedButton(
                  onPressed: isSending ? null : _saveItem,
                  child: isSending
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(),
                        )
                      : const Text('Add Item'),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
