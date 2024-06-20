import 'package:flutter/material.dart';

class StarRating extends StatefulWidget {
  final int starCount;
  final double rating;
  final void Function(double rating) onRatingChanged;

  StarRating({
    this.starCount = 5,
    this.rating = 0.0,
    required this.onRatingChanged,
  });

  @override
  _StarRatingState createState() => _StarRatingState();
}

class _StarRatingState extends State<StarRating> {
  late double _currentRating;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.rating; // Initialize with the passed rating
  }

  @override
  void didUpdateWidget(StarRating oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rating != widget.rating) {
      _currentRating = widget
          .rating; // Update the current rating if the passed rating changes
    }
  }

  Widget buildStar(BuildContext context, int index) {
    IconData icon;
    if (index >= _currentRating) {
      icon = Icons.star_border;
    } else if (index > _currentRating - 1 && index < _currentRating) {
      icon = Icons.star_half;
    } else {
      icon = Icons.star;
    }
    return InkResponse(
      onTap: () {
        setState(() {
          _currentRating = index + 1.0;
        });
        widget.onRatingChanged(_currentRating);
      },
      child: Icon(
        icon,
        color: index < _currentRating ? Colors.yellow : Colors.grey,
        size: 32.0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        widget.starCount,
        (index) => buildStar(context, index),
      ),
    );
  }
}
