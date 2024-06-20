from flask import Flask, request, jsonify, Response
from flask_cors import CORS
from flask_pymongo import PyMongo
from pymongo import MongoClient
from collections import OrderedDict
import json
import random
import logging
from groq import Groq
from pymongo.server_api import ServerApi

app = Flask(__name__)
CORS(app)  # Enable CORS

groq_client = Groq(api_key="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")

# Initialize MongoDB connections and configurations
#app.config["MONGO_URI"] = "mongodb://localhost:27017/users_db"
#uri = "mongodb+srv://aryasuresh2719:dbuserpassword@cluster0.zg39ent.mongodb.net/"
#client = MongoClient('mongodb://localhost:27017/')
app.config['MONGO_URI'] = "mongodb+srv://aryasuresh2719:dbuserpassword@cluster0.zg39ent.mongodb.net/users_db?retryWrites=true&w=majority"
mongo = PyMongo(app)

client = MongoClient(app.config['MONGO_URI'] )
db = client['users_db']
recipes_collection = db['recipes']
collection=db['users']

# Setup logging
logging.basicConfig(level=logging.DEBUG)

# Utility function to order dish
def order_dish(dish):
    ingredients_list = [ingredient.strip() for ingredient in dish.get('ingredients', '').split(';')]
    return OrderedDict([
        ('title', dish.get('title', '')),
        ('ingredients', ingredients_list), 
        ('directions', dish.get('directions', '')),
        ('total_time', dish.get('total_time', '')),
        ('calories', str(dish.get('calories', ''))),
        ('carbohydrates_g', str(dish.get('carbohydrates_g', ''))),
        ('sugars_g', str(dish.get('sugars_g', ''))),
        ('fat_g', str(dish.get('fat_g', ''))),
        ('protein_g', str(dish.get('protein_g', ''))),
        ('image', dish.get('image', ''))
    ])

# Route for signup
@app.route('/signup', methods=['POST'])
def signup():
    data = request.json
    email = data.get('email')
    username = data.get('username')
    password = data.get('password')

    existing_user = collection.find_one({'username': username})
    if existing_user:
        return jsonify({'message': 'Username already exists'}), 400
    existing_email = collection.find_one({'email': email})
    if existing_email:
        return jsonify({'message': 'Email already registered'}), 400
    # Initialize favorites field for the new user
    collection.insert_one({'email': email,'username': username, 'password': password, 'favorites': [],'aifavorites':[]})
    return jsonify({'message': 'Signup successful'}), 201


# Route for login
@app.route('/', methods=['POST'])
def login():
    data = request.json
    username = data.get('username')
    password = data.get('password')

    user = collection.find_one({'username': username, 'password': password})
    if user:
        return jsonify({'message': 'Login successful'}), 200
    else:
        return jsonify({'message': 'Username or password is incorrect'}), 401

# Route for get_dish
@app.route("/get_dish", methods=["GET"])
def get_dish():
    dish_name = request.args.get("dishName", "").lower()
    if dish_name:
        dishes = list(mongo.db.recipes.find({"title": {"$regex": f".*{dish_name}.*", "$options": "i"}}))
        if dishes:
            ordered_dishes = [order_dish(dish) for dish in dishes]
            json_output = json.dumps(ordered_dishes, indent=4)
            return Response(json_output, content_type='application/json'), 200
        else:
            return Response(json.dumps({"error": f"No recipes found containing '{dish_name}'"}), content_type='application/json'), 404
    else:
        return Response(json.dumps({"error": "Please provide a dishname parameter"}), content_type='application/json'), 400

# Route for categories
#  @app.route("/categories")
# def get_categories():
#     categories = db.recipes.distinct("category")
#     return jsonify(categories)

# Route for category recipes
@app.route("/category/<category>")
def get_category_recipes(category):
    recipes = list(db.recipes.find({"category": category}))

    if recipes:
        random_recipes = random.sample(recipes, min(10, len(recipes)))

        for recipe in random_recipes:
            recipe.pop('_id', None)
            recipe.pop('ingredients', None)
            recipe.pop('directions', None)
            recipe.pop('total_time', None)
            recipe.pop('calories', None)
            recipe.pop('carbohydrates_g', None)
            recipe.pop('sugars_g', None)
            recipe.pop('fat_g', None)
            recipe.pop('protein_g', None)
            recipe.pop('category', None)
            
        return jsonify(random_recipes)
    else:
        return jsonify({'error': 'No recipes found for the category'}), 404

# Route for recipe_details
@app.route('/recipe_details/<recipe_title>', methods=['GET'])
def get_recipe_details(recipe_title):
    recipe = recipes_collection.find_one({'title': recipe_title})
    if recipe:
        # Split the ingredients string into a list
        ingredients_list = recipe.get('ingredients', '').split(';')
        # Remove empty strings from the list
        ingredients_list = [ingredient.strip() for ingredient in ingredients_list if ingredient.strip()]
        
        # Convert calories, total_time, carbohydrates_g, sugars_g, fat_g, and protein_g to strings
        calories_str = str(recipe.get('calories', ''))
        total_time_str = str(recipe.get('total_time', ''))
        carbohydrates_g_str = str(recipe.get('carbohydrates_g', ''))
        sugars_g_str = str(recipe.get('sugars_g', ''))
        fat_g_str = str(recipe.get('fat_g', ''))
        protein_g_str = str(recipe.get('protein_g', ''))

        recipe_details = {
            'title': recipe.get('title', ''),
            'calories': calories_str,
            'total_time': total_time_str,
            'image': recipe.get('image', ''),
            'ingredients': ingredients_list,
            'directions': recipe.get('directions', ''),
            'carbohydrates_g': carbohydrates_g_str,
            'sugars_g': sugars_g_str,
            'fat_g': fat_g_str,
            'protein_g': protein_g_str,
        }
        ordered_keys = [
            'title', 'image', 'ingredients', 'directions', 'total_time', 'calories', 'carbohydrates_g', 'sugars_g', 'fat_g', 'protein_g'
        ]
        ordered_recipe_details = {key: recipe_details[key] for key in ordered_keys}
        return json.dumps(ordered_recipe_details), 200
    else:
        return jsonify({'message': 'Recipe not found'}), 404

# Route for rate_recipe
@app.route('/rate_recipe', methods=['POST'])
def rate_recipe():
    data = request.json
    recipe_name = data.get('recipe_name')
    rating = data.get('rating')
    username = data.get('username')  # Added username field

    if not recipe_name or not rating or not username:
        return jsonify({'message': 'Recipe name, rating, and username are required'}), 400

    recipe = recipes_collection.find_one({'title': recipe_name})
    if not recipe:
        return jsonify({'message': 'Recipe not found'}), 404

    existing_rating = None
    for r in recipe.get('ratings', []):
        if r['username'] == username:
            existing_rating = r['rating']
            break

    if existing_rating is not None:
        # Update existing rating
        current_total_rating = recipe['rating'] * recipe['num_ratings']
        new_total_rating = current_total_rating - existing_rating + rating
        new_avg_rating = new_total_rating / recipe['num_ratings']
        
        recipes_collection.update_one(
            {'title': recipe_name, 'ratings.username': username},
            {'$set': {'rating': new_avg_rating, 'ratings.$.rating': rating}}
        )
    else:
        # Add new rating
        current_total_rating = recipe.get('rating', 0) * recipe.get('num_ratings', 0)
        new_total_rating = current_total_rating + rating
        new_num_ratings = recipe.get('num_ratings', 0) + 1
        new_avg_rating = new_total_rating / new_num_ratings

        recipes_collection.update_one(
            {'title': recipe_name},
            {'$set': {'rating': new_avg_rating, 'num_ratings': new_num_ratings},
             '$push': {'ratings': {'username': username, 'rating': rating}}}
        )

    return jsonify({'message': 'Recipe rated successfully'}), 200

# Route for get_recipe_rating
@app.route('/get_recipe_rating', methods=['GET'])
def get_recipe_rating():
    recipe_name = request.args.get('recipe_name')
    username = request.args.get('username')  # Added username

    if not recipe_name:
        return jsonify({'message': 'Recipe name is required'}), 400

    recipe = recipes_collection.find_one({'title': recipe_name})
    if not recipe:
        return jsonify({'message': 'Recipe not found'}), 404

    rating = recipe.get('rating', 0)
    num_ratings = recipe.get('num_ratings', 0)

    user_rating = None
    if username:
        for r in recipe.get('ratings', []):
            if r['username'] == username:
                user_rating = r['rating']
                break

    return jsonify({'rating': rating, 'num_ratings': num_ratings, 'user_rating': user_rating}), 200

# Route for add_comment
@app.route('/add_comment', methods=['POST'])
def add_comment():
    data = request.json
    recipe_name = data.get('recipe_name')
    comment = data.get('comment')
    username = data.get('username')

    if not recipe_name or not comment or not username:
        return jsonify({'message': 'Recipe name, comment, and username are required'}), 400

    recipe = recipes_collection.find_one({'title': recipe_name})
    if not recipe:
        return jsonify({'message': 'Recipe not found'}), 404

    recipes_collection.update_one(
        {'title': recipe_name},
        {'$push': {'comments': {'username': username, 'comment': comment}}}
    )

    return jsonify({'message': 'Comment added successfully'}), 200

# Route for get_comments
@app.route('/get_comments/<recipe_name>', methods=['GET'])
def get_comments(recipe_name):
    if not recipe_name:
        return jsonify({'message': 'Recipe name is required'}), 400

    recipe = recipes_collection.find_one({'title': recipe_name})
    if not recipe:
        return jsonify({'message': 'Recipe not found'}), 404

    comments = recipe.get('comments', [])

    return jsonify(comments), 200

# Route for add_favorite
@app.route('/add_favorite', methods=['POST'])
def add_favorite():
    data = request.json
    username = data.get('username')
    recipe_name = data.get('recipe_name')

    if not username or not recipe_name:
        return jsonify({'message': 'Username and recipe name are required'}), 400

    user = collection.find_one({'username': username})
    if not user:
        return jsonify({'message': 'User not found'}), 404

    if 'favourite' not in user or not isinstance(user['favourite'], list):
        # Log unexpected data
        app.logger.warning(f"Unexpected data for user '{username}': {user}")
        # Initialize favourite list if it's not a list
        user['favourite'] = []

    # Check if the recipe is already in favorites
    if any(isinstance(fav, dict) and fav.get('title') == recipe_name for fav in user['favourite']):
        return jsonify({'message': 'Recipe already in favorites'}), 400

    # Find the recipe in the recipes collection
    recipe = recipes_collection.find_one({'title': recipe_name})
    if not recipe:
        return jsonify({'message': 'Recipe not found'}), 404

    # Prepare recipe details to be added to favorites
    if isinstance(recipe, dict):
        ingredients_list = recipe.get('ingredients', '').split(';')
        # Remove empty strings from the list
        ingredients_list = [ingredient.strip() for ingredient in ingredients_list if ingredient.strip()]
        
        # Convert calories, total_time, carbohydrates_g, sugars_g, fat_g, and protein_g to strings
        calories_str = str(recipe.get('calories', ''))
        total_time_str = str(recipe.get('total_time', ''))
        carbohydrates_g_str = str(recipe.get('carbohydrates_g', ''))
        sugars_g_str = str(recipe.get('sugars_g', ''))
        fat_g_str = str(recipe.get('fat_g', ''))
        protein_g_str = str(recipe.get('protein_g', ''))

        recipe_details = {
            'title': recipe.get('title', ''),
            'calories': calories_str,
            'total_time': total_time_str,
            'image': recipe.get('image', ''),
            'ingredients': ingredients_list,
            'directions': recipe.get('directions', ''),
            'carbohydrates_g': carbohydrates_g_str,
            'sugars_g': sugars_g_str,
            'fat_g': fat_g_str,
            'protein_g': protein_g_str,
        }
    else:
        # Handle the case when recipe is not a dictionary
        return jsonify({'message': 'Invalid recipe data'}), 500

    # Add recipe details to user's favorites
    user['favourite'].append(recipe_details)

    # Update user's favorites in the database
    collection.update_one(
        {'username': username},
        {'$set': {'favourite': user['favourite']}}
    )

    return jsonify({'message': 'Recipe added to favorites'}), 200

@app.route('/favorites', methods=['GET'])
def get_favorites():
    username = request.args.get('username')
    if not username:
        return jsonify({'message': 'Username is required'}), 400

    user = collection.find_one({'username': username})
    if not user:
        return jsonify({'message': 'User not found'}), 404

    favourites = user.get('favourite', [])
    app.logger.debug(f'Favorites for user {username}: {favourites}')
    return jsonify(favourites), 200

@app.route('/remove_favorite', methods=['POST'])
def remove_favorite():
    data = request.json
    username = data.get('username')
    recipe_name = data.get('recipe_name')

    if not username or not recipe_name:
        return jsonify({'message': 'Username and recipe name are required'}), 400

    user = collection.find_one({'username': username})
    if not user:
        return jsonify({'message': 'User not found'}), 404

    if 'favourite' not in user or not isinstance(user['favourite'], list):
        # Log unexpected data
        app.logger.warning(f"Unexpected data for user '{username}': {user}")
        return jsonify({'message': 'Invalid user data'}), 500

    # Remove the recipe from favorites
    user['favourite'] = [fav for fav in user['favourite'] if fav.get('title') != recipe_name]

    # Update user's favorites in the database
    collection.update_one(
        {'username': username},
        {'$set': {'favourite': user['favourite']}}
    )

    return jsonify({'message': 'Recipe removed from favorites'}), 200

@app.route('/is_favorite', methods=['GET'])
def check_favorite():
    username = request.args.get('username')
    recipe_name = request.args.get('recipe_name')

    if not username or not recipe_name:
        return jsonify({'message': 'Username and recipe name are required'}), 400

    user = collection.find_one({'username': username})
    if not user:
        return jsonify({'message': 'User not found'}), 404

    favorites = user.get('favourite', [])
    is_favorite = any(fav.get('title') == recipe_name for fav in favorites)

    return jsonify({'is_favorite': is_favorite}), 200

@app.route('/generate_recipe', methods=['POST'])
def generate_recipe():
    data = request.json
    ingredients = data.get('ingredients')
    preference = data.get('preference')
    cooktime = data.get('cooktime')
    
    if not ingredients or not preference or not cooktime:
        return jsonify({"error": "Missing required parameters"}), 400
    
    try:
        completion = groq_client.chat.completions.create(
            model="llama3-8b-8192",
            messages=[
                {
                    "role": "system",
                    "content": f"generate a {preference} recipe with the given ingredients which will take {cooktime} mins to cook. Give title, ingredients with measurement, steps in detail, and also the nutritional info."
                },
                {
                    "role": "user",
                    "content": ingredients
                },
            ],
            temperature=1,
            max_tokens=1024,
            top_p=1,
            stream=False,
            stop=None,
        )
        
        # Extract response text from completion
        response_text = completion.choices[0].message.content.strip()
        return jsonify({"recipe": response_text})
    
    except Exception as e:
        app.logger.error("Error generating recipe: %s", e)
        return jsonify({"error": str(e)}), 500

@app.route('/add_aifavorite', methods=['POST'])
def add_aifavorite():
    data = request.json
    username = data.get('username')
    recipe = data.get('recipe')
    
    if not username or not recipe:
        return jsonify({"error": "Missing required parameters"}), 400

    user = collection.find_one({"username": username})
    if user:
        aifavorites = user.get('aifavorites', [])
        aifavorites.append(recipe)
        collection.update_one(
            {"username": username},
            {"$set": {"aifavorites": aifavorites}}
        )
        return jsonify({"message": "Recipe added to AI favorites"}), 200
    else:
        return jsonify({"error": "User not found"}), 404

@app.route('/get_aifavorites', methods=['GET'])
def get_aifavorites():
    username = request.args.get('username')
    
    if not username:
        return jsonify({"error": "Missing username parameter"}), 400
    
    user = collection.find_one({"username": username})
    if user:
        return jsonify({"aifavorites": user.get('aifavorites', [])}), 200
    else:
        return jsonify({"error": "User not found"}), 404
@app.route('/delete_aifavorite', methods=['POST'])
def delete_aifavorite():
    data = request.json
    username = data.get('username')
    recipe = data.get('recipe')
    
    if not username or not recipe:
        return jsonify({"error": "Missing required parameters"}), 400

    user = collection.find_one({"username": username})
    if user:
        aifavorites = user.get('aifavorites', [])
        if recipe in aifavorites:
            aifavorites.remove(recipe)
            collection.update_one(
                {"username": username},
                {"$set": {"aifavorites": aifavorites}}
            )
            return jsonify({"message": "Recipe removed from AI favorites"}), 200
        else:
            return jsonify({"error": "Recipe not found in AI favorites"}), 404
    else:
        return jsonify({"error": "User not found"}), 404


# if __name__ == '__main__':
#     app.run(debug=True, port=5000)
