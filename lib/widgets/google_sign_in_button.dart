import 'package:flutter/material.dart';

class GoogleSignInButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;
  
  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: Theme.of(context).colorScheme.outline,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 24,
              width: 24,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: CustomPaint(
                    size: const Size(20, 20),
                    painter: GoogleLogoPainter(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            isLoading
                ? SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  )
                : Text(
                    'Sign in with Google',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Define colors for the Google logo
    final blue = const Color(0xFF4285F4);
    final red = const Color(0xFFEA4335);
    final yellow = const Color(0xFFFBBC05);
    final green = const Color(0xFF34A853);
    
    final paint = Paint()
      ..style = PaintingStyle.fill;
    
    // Calculate sizes
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = size.width < size.height ? size.width / 2 : size.height / 2;
    
    // Create the four arcs for the Google 'G'
    final rect = Rect.fromCircle(center: Offset(centerX, centerY), radius: radius);
    
    // Red arc (top-right)
    paint.color = red;
    canvas.drawArc(rect, -0.5 * 3.14, 0.5 * 3.14, true, paint);
    
    // Green arc (bottom-right)
    paint.color = green;
    canvas.drawArc(rect, 0, 0.5 * 3.14, true, paint);
    
    // Yellow arc (bottom-left)
    paint.color = yellow;
    canvas.drawArc(rect, 0.5 * 3.14, 0.5 * 3.14, true, paint);
    
    // Blue arc (top-left) and extension
    paint.color = blue;
    canvas.drawArc(rect, 3.14, 0.5 * 3.14, true, paint);
    
    // Create white center to make it look like a 'G'
    paint.color = Colors.white;
    canvas.drawCircle(
      Offset(centerX, centerY),
      radius * 0.6,
      paint,
    );
    
    // Draw blue rectangle on right side for the extension of the 'G'
    paint.color = blue;
    final bluePath = Path()
      ..moveTo(centerX + radius * 0.25, centerY - radius * 0.4)
      ..lineTo(centerX + radius, centerY - radius * 0.4)
      ..lineTo(centerX + radius, centerY + radius * 0.4)
      ..lineTo(centerX + radius * 0.25, centerY + radius * 0.4)
      ..close();
    canvas.drawPath(bluePath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 