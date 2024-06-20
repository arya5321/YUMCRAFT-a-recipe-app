import 'package:flutter/material.dart';
import 'recipe.dart';
import 'recipe_details_page.dart';
import 'dart:convert'; // Import for jsonDecode
import 'package:http/http.dart' as http;

class FavoritesPage extends StatefulWidget {
  final String username; // Add the username parameter

  FavoritesPage({required this.username});

  @override
  _FavoritesPageState createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  List<Recipe> favoriteRecipes = [];

  @override
  void initState() {
    super.initState();
    fetchFavoriteRecipes();
  }

  Future<void> fetchFavoriteRecipes() async {
    final response = await http.get(Uri.parse(
        'http://127.0.0.1:5000/favorites?username=${widget.username}'));
    if (response.statusCode == 200) {
      List<dynamic> recipeList = jsonDecode(response.body);
      setState(() {
        favoriteRecipes = recipeList.map((e) => Recipe.fromJson(e)).toList();
        print(favoriteRecipes);
      });
    } else {
      // Handle error
      print('Failed to load favorites');
    }
  }

  Future<void> deleteFromFavorites(String recipeName) async {
    final response = await http.post(
      Uri.parse('http://127.0.0.1:5000/remove_favorite'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': widget.username, 'recipe_name': recipeName}),
    );

    if (response.statusCode == 200) {
      setState(() {
        favoriteRecipes.removeWhere((recipe) => recipe.title == recipeName);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Recipe removed from favorites')),
      );
    } else {
      print('Failed to remove from favorites: ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Favorite Recipes'),
      ),
      body: ListView.builder(
        itemCount: favoriteRecipes.length,
        itemBuilder: (context, index) {
          final recipe = favoriteRecipes[index];
          return ListTile(
            leading: Image.network(recipe.image),
            title: Text(recipe.title),
            trailing: IconButton(
              icon: Icon(Icons.delete),
              color: Colors.red,
              onPressed: () {
                deleteFromFavorites(recipe.title);
              },
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RecipeDetailsPage(
                      recipe: recipe, username: widget.username),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
