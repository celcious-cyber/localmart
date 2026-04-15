import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../features/cart/controllers/cart_controller.dart';
import '../../features/cart/screens/cart_screen.dart';

class ReactiveCartIcon extends StatefulWidget {
  final Color iconColor;
  final Color? badgeColor;
  final double size;

  const ReactiveCartIcon({
    super.key,
    this.iconColor = Colors.white,
    this.badgeColor,
    this.size = 24,
  });

  @override
  State<ReactiveCartIcon> createState() => _ReactiveCartIconState();
}

class _ReactiveCartIconState extends State<ReactiveCartIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late CartController _cartController;
  Worker? _worker;

  @override
  void initState() {
    super.initState();
    
    // Safely get or put CartController
    _cartController = Get.isRegistered<CartController>() 
        ? Get.find<CartController>() 
        : Get.put(CartController());

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3).chain(CurveTween(curve: Curves.easeOut)), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0).chain(CurveTween(curve: Curves.bounceIn)), weight: 60),
    ]).animate(_animationController);

    // Trigger animation whenever cartUpdateSignal changes
    _worker = ever(_cartController.cartUpdateSignal, (_) {
      _animationController.reset();
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _worker?.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.to(() => const CartScreen()),
      child: Container(
        padding: const EdgeInsets.all(8),
        color: Colors.transparent, // Disable default highlights
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                Icons.shopping_cart_outlined,
                color: widget.iconColor,
                size: widget.size,
              ),
              Obx(() {
                final count = _cartController.totalItems;
                if (count == 0) return const SizedBox.shrink();

                return Positioned(
                  right: -6,
                  top: -6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: widget.badgeColor ?? Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Center(
                      child: Text(
                        count > 99 ? '99+' : count.toString(),
                        style: GoogleFonts.manrope(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
