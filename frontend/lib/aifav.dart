import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AIFavPage extends StatefulWidget {
  final String username;

  AIFavPage({required this.username});

  @override
  _AIFavPageState createState() => _AIFavPageState();
}

class _AIFavPageState extends State<AIFavPage> {
  List<String> aiFavorites = [];

  @override
  void initState() {
    super.initState();
    _fetchAIFavorites();
  }

  Future<void> _fetchAIFavorites() async {
    final url =
        'http://localhost:5000/get_aifavorites?username=${widget.username}';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        aiFavorites = List<String>.from(data['aifavorites']);
      });
    } else {
      // Handle error
      print('Failed to fetch AI favorites');
    }
  }

  Future<void> _deleteAIFavorite(String recipe) async {
    final url = 'http://localhost:5000/delete_aifavorite';
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'username': widget.username, 'recipe': recipe}),
    );

    if (response.statusCode == 200) {
      setState(() {
        aiFavorites.remove(recipe);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Recipe deleted from AI favorites!'),
        ),
      );
    } else {
      // Handle error
      print('Failed to delete AI favorite');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AI Favorites'),
      ),
      body: aiFavorites.isEmpty
          ? Center(child: Text('No AI favorites found'))
          : ListView.builder(
              itemCount: aiFavorites.length,
              itemBuilder: (context, index) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[300], // Set the background color to grey
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  margin: EdgeInsets.all(8.0),
                  child: Stack(
                    children: [
                      ListTile(
                        title: Text(
                          aiFavorites[index],
                          style: TextStyle(color: Colors.black),
                        ),
                        // You can customize the ListTile as needed
                      ),
                      Positioned(
                        top: 8.0,
                        right: 8.0,
                        child: IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () async {
                            await _deleteAIFavorite(aiFavorites[index]);
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
