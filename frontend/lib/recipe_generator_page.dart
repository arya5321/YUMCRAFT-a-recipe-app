import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RecipeGeneratorPage extends StatefulWidget {
  final String ingredients;
  final String username; // Accept username from the constructor

  RecipeGeneratorPage({required this.ingredients, required this.username});

  @override
  _RecipeGeneratorPageState createState() => _RecipeGeneratorPageState();
}

class _RecipeGeneratorPageState extends State<RecipeGeneratorPage> {
  final TextEditingController _preferenceController = TextEditingController();
  final TextEditingController _cooktimeController = TextEditingController();
  String _recipe = '';
  String _error = '';
  bool _isAddedToFavorites = false;

  Future<void> _generateRecipe() async {
    final preference = _preferenceController.text;
    final cooktime = _cooktimeController.text;

    if (preference.isEmpty || cooktime.isEmpty) {
      setState(() {
        _error = 'Please fill in all fields.';
        _recipe = '';
      });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:5000/generate_recipe'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'ingredients': widget.ingredients,
          'preference': preference,
          'cooktime': cooktime,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _recipe = data['recipe'];
          _error = '';
          _isAddedToFavorites = false; // Reset the favorites icon state
        });
      } else {
        final data = jsonDecode(response.body);
        setState(() {
          _error = 'Error generating recipe: ${data['error']}';
          _recipe = '';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _recipe = '';
      });
    }
  }

  Future<void> _addAIFavorite() async {
    if (_recipe.isEmpty) {
      setState(() {
        _error = 'No recipe to add to AI favorites.';
      });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:5000/add_aifavorite'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': widget.username, 'recipe': _recipe}),
      );

      if (response.statusCode == 200) {
        setState(() {
          _isAddedToFavorites = true; // Update the favorites icon state
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Recipe added to AI favorites!'),
          ),
        );
      } else {
        final data = jsonDecode(response.body);
        setState(() {
          _error = 'Error adding favorite: ${data['error']}';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Generate Recipe'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _preferenceController,
              decoration: InputDecoration(labelText: 'Preference'),
            ),
            TextField(
              controller: _cooktimeController,
              decoration: InputDecoration(labelText: 'Cook Time (mins)'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _generateRecipe,
              child: Text('Generate Recipe'),
            ),
            SizedBox(height: 20),
            if (_error.isNotEmpty) ...[
              Text(
                _error,
                style: TextStyle(color: Colors.red),
              ),
              SizedBox(height: 20),
            ],
            Expanded(
              child: SingleChildScrollView(
                child: Text(_recipe),
              ),
            ),
            IconButton(
              icon: Icon(
                _isAddedToFavorites ? Icons.favorite : Icons.favorite_border,
                color: _isAddedToFavorites ? Colors.red : null,
              ),
              onPressed: _addAIFavorite,
            ),
          ],
        ),
      ),
    );
  }
}
