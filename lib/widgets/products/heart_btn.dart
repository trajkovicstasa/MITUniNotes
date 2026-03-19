import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:notes_hub/consts/app_colors.dart';
import 'package:notes_hub/providers/wishlist_provider.dart';
import 'package:provider/provider.dart';

class HeartButtonWidget extends StatefulWidget {
  const HeartButtonWidget({
    super.key,
    this.bkgColor = Colors.transparent,
    this.size = 20,
    this.showLabel = false,
    this.label = 'Omiljeno',
    required this.productId,
  });
  final Color bkgColor;
  final double size;
  final bool showLabel;
  final String label;
  final String productId;
  @override
  State<HeartButtonWidget> createState() => _HeartButtonWidgetState();
}

class _HeartButtonWidgetState extends State<HeartButtonWidget> {
  @override
  Widget build(BuildContext context) {
    final wishlistsProvider = Provider.of<WishlistProvider>(context);
    final isFavorite = wishlistsProvider.isProdinWishlist(
      productId: widget.productId,
    );

    Future<void> toggleFavorite() async {
      if (wishlistsProvider.getWishlists.containsKey(widget.productId)) {
        await wishlistsProvider.removeWishlistItemFromFirestore(
          wishlistId: wishlistsProvider.getWishlists[widget.productId]!.wishlistId,
          productId: widget.productId,
        );
      } else {
        await wishlistsProvider.addToWishlistFirebase(
          productId: widget.productId,
          context: context,
        );
      }
      await wishlistsProvider.fetchWishlist();
    }

    if (widget.showLabel) {
      return Material(
        color: isFavorite
            ? AppColors.lightPrimary.withValues(alpha: 0.12)
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: toggleFavorite,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isFavorite ? IconlyBold.heart : IconlyLight.heart,
                  size: widget.size,
                  color: isFavorite
                      ? AppColors.lightPrimary
                      : AppColors.darkPrimary,
                ),
                const SizedBox(width: 6),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isFavorite
                        ? AppColors.lightPrimary
                        : AppColors.darkPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: widget.bkgColor,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        style: IconButton.styleFrom(elevation: 10),
        onPressed: toggleFavorite,
        icon: Icon(
          isFavorite ? IconlyBold.heart : IconlyLight.heart,
          size: widget.size,
          color: isFavorite ? AppColors.lightPrimary : AppColors.darkPrimary,
        ),
      ),
    );
  }
}
