import 'package:flutter/material.dart';

class ActionSlider extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color baseColor;
  final VoidCallback onComplete;

  const ActionSlider({
    super.key,
    required this.label,
    required this.icon,
    required this.baseColor,
    required this.onComplete,
  });

  @override
  State<ActionSlider> createState() => _ActionSliderState();
}

class _ActionSliderState extends State<ActionSlider> with TickerProviderStateMixin {
  double _dragValue = 0.0;
  bool _isFinished = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const double height = 60.0;
    const double padding = 4.0;
    const double knobSize = height - (padding * 2);

    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxDrag = constraints.maxWidth - knobSize - (padding * 2);

        return Container(
          height: height,
          width: double.infinity,
          padding: const EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: widget.baseColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(height / 2),
            border: Border.all(color: widget.baseColor.withOpacity(0.2)),
          ),
          child: Stack(
            children: [
              // Progress Fill
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: _dragValue + knobSize,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        widget.baseColor.withOpacity(0.4),
                        widget.baseColor.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(height / 2),
                  ),
                ),
              ),
              
              // Centered Label
              Center(
                child: Opacity(
                  opacity: (1 - (_dragValue / maxDrag)).clamp(0.0, 1.0),
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      color: widget.baseColor.withOpacity(0.8),
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
              ),

              // The Knob
              Positioned(
                left: _dragValue,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    if (_isFinished) return;
                    setState(() {
                      _dragValue += details.delta.dx;
                      _dragValue = _dragValue.clamp(0.0, maxDrag);
                    });
                  },
                  onHorizontalDragEnd: (details) {
                    if (_isFinished) return;
                    if (_dragValue >= maxDrag * 0.9) {
                      // Trigger complete
                      setState(() {
                        _dragValue = maxDrag;
                        _isFinished = true;
                      });
                      widget.onComplete();
                      
                      // Reset slightly later for loop if needed, but usually page refreshes
                    } else {
                      // Reset
                      setState(() {
                        _dragValue = 0.0;
                      });
                    }
                  },
                  child: Container(
                    width: knobSize,
                    height: knobSize,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(knobSize / 2),
                      boxShadow: [
                        BoxShadow(
                          color: widget.baseColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      _isFinished ? Icons.check_rounded : widget.icon,
                      color: widget.baseColor,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
