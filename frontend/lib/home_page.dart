import 'package:flutter/material.dart';
import 'package:frontend/aifav.dart';
import 'recipe.dart';
import 'recipe_list_page.dart';
import 'recipe_details_page.dart';
import 'recipe_generator_page.dart';
import 'favorites_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomePage extends StatefulWidget {
  final String username; // Add the username parameter

  HomePage({required this.username});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final TextEditingController _dishNameController =
      TextEditingController();
  late final TextEditingController _ingredientsController =
      TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Discover Best Recipes'),
      ),
      body: HomePageContent(
        dishNameController: _dishNameController,
        ingredientsController: _ingredientsController,
        username: widget.username, // Pass the username to HomePageContent
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'AI Favorites',
          ),
        ],
        currentIndex: 0,
        selectedItemColor: Colors.blue,
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FavoritesPage(username: widget.username),
              ),
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AIFavPage(
                    username: widget.username), // Navigate to AIFav.dart
              ),
            );
          }
        },
      ),
    );
  }
}

class HomePageContent extends StatelessWidget {
  final TextEditingController? dishNameController;
  final TextEditingController? ingredientsController;
  final String username; // Add the username parameter

  const HomePageContent({
    Key? key,
    this.dishNameController,
    this.ingredientsController,
    required this.username,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: dishNameController,
            decoration: InputDecoration(hintText: 'Enter recipe name'),
            onSubmitted: (value) {
              if (dishNameController != null &&
                  dishNameController!.text.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RecipeListPage(
                      dishName: value,
                      username: username,
                    ),
                  ),
                );
              }
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: ingredientsController,
            decoration: InputDecoration(hintText: 'Enter ingredients'),
            onSubmitted: (value) {
              if (ingredientsController != null &&
                  ingredientsController!.text.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RecipeGeneratorPage(
                      ingredients: ingredientsController!.text,
                      username: username,
                    ),
                  ),
                );
              }
            },
          ),
        ),
        _buildCategory(context, 'Main Dish', 'main-dish'),
        _buildCategory(context, 'Breakfast and Brunch', 'breakfast-and-brunch'),
        _buildCategory(context, 'Meat and Poultry', 'meat-and-poultry'),
        _buildCategory(context, 'Bread', 'bread'),
        _buildCategory(context, 'World Cuisine', 'world-cuisine'),
        _buildCategory(context, 'Trusted Brands Recipes and Tips',
            'trusted-brands-recipes-and-tips'),
        _buildCategory(context, 'Desserts', 'desserts'),
        _buildCategory(context, 'Side Dish', 'side-dish'),
        _buildCategory(context, 'Everyday Cooking', 'everyday-cooking'),
        _buildCategory(context, 'Salad', 'salad'),
        _buildCategory(context, 'Drinks', 'drinks'),
        _buildCategory(
            context, 'Soups, Stews, and Chili', 'soups-stews-and-chili'),
        _buildCategory(
            context, 'Appetizers and Snacks', 'appetizers-and-snacks'),
        _buildCategory(
            context, 'Fruits and Vegetables', 'fruits-and-vegetables'),
        _buildCategory(context, 'Seafood', 'seafood'),
        _buildCategory(context, 'Pasta and Noodles', 'pasta-and-noodles'),
        _buildCategory(context, 'Holidays and Events', 'holidays-and-events'),
        // Add other categories similarly
      ],
    );
  }

  Future<List<Map<String, dynamic>>> fetchRecipesForCategory(
      String category) async {
    try {
      final response =
          await http.get(Uri.parse('http://127.0.0.1:5000/category/$category'));

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          return List<Map<String, dynamic>>.from(data);
        } else {
          throw Exception('No recipes found');
        }
      } else {
        throw Exception('Failed to load recipes');
      }
    } catch (e) {
      print('Error fetching recipes for category $category: $e');
      throw e;
    }
  }

  Widget _buildCategory(
      BuildContext context, String category, String categoryKey) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: fetchRecipesForCategory(categoryKey),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('No recipes found for $category'));
        } else {
          List<Map<String, dynamic>> recipes = snapshot.data!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  category,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                height: 200, // Adjust height as needed
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: recipes.length,
                  itemBuilder: (context, index) {
                    final recipeData = recipes[index];
                    return GestureDetector(
                      onTap: () async {
                        final recipeName =
                            Uri.encodeComponent(recipeData['title']);
                        final url =
                            'http://127.0.0.1:5000/recipe_details/$recipeName';
                        final response = await http.get(Uri.parse(url));
                        if (response.statusCode == 200) {
                          final Map<String, dynamic> data =
                              json.decode(response.body);
                          print(
                              data); // Print the data received from the backend
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RecipeDetailsPage(
                                recipe: Recipe.fromJson(data),
                                username: username,
                              ),
                            ),
                          );
                        } else {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('Error'),
                              content: Text(
                                  'Failed to load recipe details! Status code: ${response.statusCode}\nURL: $url'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text('OK'),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Container(
                              width: 150, // Adjust width as needed
                              height: 150, // Adjust height as needed
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: recipeData['image'] != null
                                    ? DecorationImage(
                                        image:
                                            NetworkImage(recipeData['image']),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(recipeData['title'] ?? 'No Title'),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        }
      },
    );
  }
}
