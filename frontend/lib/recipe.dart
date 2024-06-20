class Recipe {
  final String title;
  final List<String> ingredients;
  final String directions;
  final String total_time;
  final String image;
  final String calories;
  final String carbohydrates_g;
  final String sugars_g;
  final String fat_g;
  final String protein_g;

  Recipe({
    required this.title,
    required this.ingredients,
    required this.directions,
    required this.total_time,
    required this.image,
    required this.calories,
    required this.carbohydrates_g,
    required this.sugars_g,
    required this.fat_g,
    required this.protein_g,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      title: json['title'],
      ingredients: List<String>.from(json['ingredients']),
      directions: json['directions'],
      total_time: json['total_time'],
      image: json['image'],
      calories: json['calories'],
      carbohydrates_g: json['carbohydrates_g'],
      sugars_g: json['sugars_g'],
      fat_g: json['fat_g'],
      protein_g: json['protein_g'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'ingredients': ingredients,
      'directions': directions,
      'total_time': total_time,
      'image': image,
      'calories': calories,
      'carbohydrates_g': carbohydrates_g,
      'sugars_g': sugars_g,
      'fat_g': fat_g,
      'protein_g': protein_g,
    };
  }
}
