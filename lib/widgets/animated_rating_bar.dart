import 'package:flutter/material.dart';
import '../core/theme.dart';

class AnimatedRatingBar extends StatefulWidget {
  final double rating;
  final double size;
  final bool isInteractive;
  final Function(double)? onRatingChanged;

  const AnimatedRatingBar({
    super.key, 
    required this.rating, 
    this.size = 24, 
    this.isInteractive = false,
    this.onRatingChanged,
  });

  @override
  State<AnimatedRatingBar> createState() => _AnimatedRatingBarState();
}

class _AnimatedRatingBarState extends State<AnimatedRatingBar> with TickerProviderStateMixin {
  late double _currentRating;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.rating;
  }

  @override
  void didUpdateWidget(AnimatedRatingBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rating != widget.rating) {
      _currentRating = widget.rating;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return _buildStar(index + 1);
      }),
    );
  }

  Widget _buildStar(int position) {
    bool isFull = position <= _currentRating;
    bool isHalf = position > _currentRating && position - 0.5 <= _currentRating;

    IconData icon;
    if (isFull) {
      icon = Icons.star_rounded;
    } else if (isHalf) {
      icon = Icons.star_half_rounded;
    } else {
      icon = Icons.star_outline_rounded;
    }

    Color color = isFull || isHalf ? AppTheme.primaryColor : Colors.grey.shade400;

    return GestureDetector(
      onTap: widget.isInteractive ? () {
        setState(() {
          _currentRating = position.toDouble();
        });
        if (widget.onRatingChanged != null) {
          widget.onRatingChanged!(_currentRating);
        }
      } : null,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 1.0, end: isFull ? 1.2 : 1.0),
        duration: const Duration(milliseconds: 200),
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: Container(
              decoration: isFull ? BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  )
                ],
              ) : null,
              child: Icon(
                icon,
                color: color,
                size: widget.size,
              ),
            ),
          );
        },
      ),
    );
  }
}
