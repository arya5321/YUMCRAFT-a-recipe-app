import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'recipe.dart';
import 'star_rating.dart';

class RecipeDetailsPage extends StatefulWidget {
  final Recipe recipe;
  final String username;

  RecipeDetailsPage({required this.recipe, required this.username});

  @override
  _RecipeDetailsPageState createState() => _RecipeDetailsPageState();
}

class _RecipeDetailsPageState extends State<RecipeDetailsPage> {
  double averageRating = 0;
  double userRating = 0;
  bool isFavorite = false; // Added isFavorite variable
  TextEditingController _reviewController = TextEditingController();
  List<Map<String, String>> userComments = [];

  @override
  void initState() {
    super.initState();
    fetchRecipeRating();
    checkIfFavorite(); // Check if the recipe is already in favorites
    fetchComments(); // Fetch comments when the page loads
  }

  Future<void> fetchRecipeRating() async {
    final response = await http.get(
      Uri.parse(
          'http://127.0.0.1:5000/get_recipe_rating?recipe_name=${widget.recipe.title}&username=${widget.username}'),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      setState(() {
        averageRating = data['rating'] ?? 0;
        userRating = data['user_rating']?.toDouble() ?? 0;
      });
    } else {
      print('Failed to fetch recipe rating: ${response.body}');
    }
  }

  Future<void> checkIfFavorite() async {
    final response = await http.get(
      Uri.parse(
          'http://127.0.0.1:5000/is_favorite?username=${widget.username}&recipe_name=${widget.recipe.title}'),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      setState(() {
        isFavorite = data['is_favorite'] ?? false;
      });
      print('checkIfFavorite: Recipe isFavorite = $isFavorite');
    } else {
      print('Failed to check if favorite: ${response.body}');
    }
  }

  Future<void> addToFavorites(String username, String recipeName) async {
    if (isFavorite) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('This recipe is already in your favorites')),
      );
      return;
    }

    final response = await http.post(
      Uri.parse('http://127.0.0.1:5000/add_favorite'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'recipe_name': recipeName}),
    );

    if (response.statusCode == 200) {
      setState(() {
        isFavorite = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Recipe added to favorites')),
      );
    } else {
      print('Failed to add to favorites: ${response.body}');
    }
  }

  Future<void> rateRecipe(String recipeName, double rating) async {
    final response = await http.post(
      Uri.parse('http://127.0.0.1:5000/rate_recipe'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'recipe_name': recipeName,
        'rating': rating,
        'username': widget.username
      }),
    );

    if (response.statusCode == 200) {
      print('Recipe rated successfully');
      fetchRecipeRating();
    } else {
      print('Failed to rate recipe: ${response.body}');
    }
  }

  void handleRatingChange(double rating) {
    rateRecipe(widget.recipe.title, rating);
    setState(() {
      userRating = rating;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Thanks for rating!')),
    );
    print('User selected rating: $rating');
  }

  Future<void> submitReview(String review) async {
    final response = await http.post(
      Uri.parse('http://127.0.0.1:5000/add_comment'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'recipe_name': widget.recipe.title,
        'comment': review,
        'username': widget.username
      }),
    );

    if (response.statusCode == 200) {
      print('Review submitted successfully');
      _reviewController.clear();
      // Show a popup indicating that the review was added successfully
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Review Added'),
            content: Text('Thanks for the review!'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
      // Refresh comments after submission
      fetchComments();
    } else {
      print('Failed to submit review: ${response.body}');
    }
  }

  Future<void> fetchComments() async {
    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:5000/get_comments/${widget.recipe.title}'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<Map<String, String>> fetchedComments = [];
        for (var comment in data) {
          fetchedComments.add({
            'user': comment['username'] != null
                ? comment['username'].toString()
                : 'Unknown User',
            'comment': comment['comment'] != null
                ? comment['comment'].toString()
                : 'No comment available',
          });
        }
        setState(() {
          userComments = fetchedComments;
        });
      } else {
        print(
            'Failed to fetch comments. Server returned status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching comments: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipe.title),
        actions: [
          IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.red : null,
            ),
            onPressed: () {
              addToFavorites(widget.username, widget.recipe.title);
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          Image.network(widget.recipe.image),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AverageStarRating(recipe: widget.recipe),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'Ingredients:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                for (var ingredient in widget.recipe.ingredients)
                  Text('- $ingredient'),
                SizedBox(height: 8),
                Text(
                  'Directions:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                Text(widget.recipe.directions),
                SizedBox(height: 8),
                Text(
                  'Nutritional Information:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                Text('Total Time: ${widget.recipe.total_time}'),
                Text('Calories: ${widget.recipe.calories}'),
                Text('Carbohydrates: ${widget.recipe.carbohydrates_g}g'),
                Text('Sugars: ${widget.recipe.sugars_g}g'),
                Text('Fat: ${widget.recipe.fat_g}g'),
                Text('Protein: ${widget.recipe.protein_g}g'),
                SizedBox(height: 8),
                Text(
                  'Rating and Review:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                StarRating(
                  rating: userRating,
                  onRatingChanged: handleRatingChange,
                ),
                SizedBox(height: 8),
                Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  child: TextField(
                    controller: _reviewController,
                    decoration: InputDecoration(
                      labelText: 'Write your review',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ),
                SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    submitReview(_reviewController.text);
                  },
                  child: Text('Submit Review'),
                ),
                SizedBox(height: 16),
                Text(
                  'View all reviews:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                SizedBox(height: 8),
                // Display user comments in a vertical list
                for (var comment in userComments)
                  ChatBox(
                    user: comment['user']!,
                    comment: comment['comment']!,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatBox extends StatelessWidget {
  final String user;
  final String comment;

  ChatBox({required this.user, required this.comment});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'User: ${user.toUpperCase()}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(comment),
        ],
      ),
    );
  }
}

class AverageStarRating extends StatefulWidget {
  final Recipe recipe;

  AverageStarRating({required this.recipe});

  @override
  _AverageStarRatingState createState() => _AverageStarRatingState();
}

class _AverageStarRatingState extends State<AverageStarRating> {
  double averageRating = 0;
  int numReviews = 0;

  @override
  void initState() {
    super.initState();
    fetchRecipeRating();
  }

  Future<void> fetchRecipeRating() async {
    final response = await http.get(
      Uri.parse(
          'http://127.0.0.1:5000/get_recipe_rating?recipe_name=${widget.recipe.title}'),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      setState(() {
        averageRating = data['rating'] ?? 0;
        numReviews = data['num_ratings'] ?? 0;
      });
    } else {
      print('Failed to fetch recipe rating: ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Row(
          children: List.generate(
            5,
            (index) => Icon(
              index < averageRating.floor()
                  ? Icons.star
                  : index < averageRating
                      ? Icons.star_half
                      : Icons.star_border,
              color: index < averageRating ? Colors.amber : Colors.grey,
            ),
          ),
        ),
        SizedBox(width: 8),
        Text(
          averageRating.toStringAsFixed(1),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w300,
          ),
        ),
        SizedBox(width: 4),
        Text(
          '($numReviews users rating)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w300,
          ),
        ),
      ],
    );
  }
}
