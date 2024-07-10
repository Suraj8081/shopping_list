import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shopping_list/data/category.dart';
import 'package:shopping_list/data/grocery_item.dart';
import 'package:shopping_list/screen/add_item.dart';
import 'package:http/http.dart' as http;

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItem = [];


  @override
  void initState() {
    super.initState();
   _loadItem();
  }

  Future<List<GroceryItem>> _loadItem() async {
    final url = Uri.https(
        'flutter-prep-f718c-default-rtdb.firebaseio.com', 'shopping-list.json');
    final response = await http.get(url);

    if (response.statusCode >= 400) {
      throw Exception('Failed to fetch grocery item.Please try again later');
    }

    final Map<String, dynamic> listData = json.decode(response.body);

    final List<GroceryItem> lodedItem = [];

    for (final item in listData.entries) {
      final category = categories.entries
          .firstWhere(
              (element) => element.value.title == item.value['category'])
          .value;
      lodedItem.add(
        GroceryItem(
          id: item.key,
          name: item.value['name'],
          quantity: item.value['quantity'],
          category: category,
        ),
      );
    }
    return lodedItem;
  }

  void _addItem() async {
    final item = await Navigator.push<GroceryItem>(
      context,
      MaterialPageRoute(
        builder: (ctx) => const AddItem(),
      ),
    );
    if (item == null) {
      return;
    }
    setState(() {
      _groceryItem.add(item);
    });
  }

  void _removeItem(GroceryItem item) async {
    var index = _groceryItem.indexOf(item);
    setState(() {
      _groceryItem.remove(item);
    });
    final url = Uri.https('flutter-prep-f718c-default-rtdb.firebaseio.com',
        'shopping-list/${item.id}.json');

    final response = await http.delete(url);

    if (response.statusCode >= 400) {
      setState(() {
        _groceryItem.insert(index, item);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Grocery'),
        actions: [
          IconButton(
            onPressed: _addItem,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: FutureBuilder(
        future: _loadItem(),
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.waiting:
              return const Center(
                child: CircularProgressIndicator(),
              );

            case ConnectionState.done:
              if (snapshot.hasError) {
                return Center(
                  child: Text(snapshot.error.toString()),
                );
              } else {
                if (snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('No Items Added yet.'),
                  );
                } else {
                  return ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      return Dismissible(
                        onDismissed: (direction) {
                          _removeItem(snapshot.data![index]);
                        },
                        key: ValueKey(snapshot.data![index].id),
                        child: ListTile(
                          title: Text(snapshot.data![index].name),
                          leading: Container(
                            height: 24,
                            width: 24,
                            color: snapshot.data![index].category.color,
                          ),
                          trailing: Text(
                            snapshot.data![index].quantity.toString(),
                          ),
                        ),
                      );
                    },
                  );
                }
              }
            default:
              return const Center(
                child: SizedBox(),
              );
          }
        },
      ),
    );
  }
}
