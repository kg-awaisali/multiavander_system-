import 'dart:ui';
import 'package:flutter/material.dart';
import '../data/models/review_model.dart';
import 'animated_rating_bar.dart';
import 'package:intl/intl.dart';

class GlassReviewCard extends StatelessWidget {
  final ReviewModel review;
  final bool isMine;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  final VoidCallback? onHelpful;
  final bool isSeller; // If current user is the seller of this product
  final Function(String)? onReply;

  const GlassReviewCard({
    super.key, 
    required this.review, 
    this.isMine = false,
    this.isSeller = false,
    this.onEdit,
    this.onDelete,
    this.onHelpful,
    this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildReviewBody(context),
          if (review.sellerReply != null) _buildSellerReply(),
          if (isSeller && review.sellerReply == null) _buildReplyAction(context),
        ],
      ),
    );
  }

  Widget _buildReviewBody(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.12),
                Colors.white.withValues(alpha: 0.06),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildUserAvatar(),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildUserHeader(),
                        const SizedBox(height: 6),
                        _buildRatingAndBadge(),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                review.comment,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.5,
                  letterSpacing: 0.3,
                ),
              ),
              if (review.images.isNotEmpty) _buildImageGallery(context),
              const SizedBox(height: 16),
              _buildActionToolbar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserAvatar() {
    return CircleAvatar(
      radius: 24,
      backgroundColor: Colors.cyanAccent.withValues(alpha: 0.2),
      child: Text(
        review.userName.isNotEmpty ? review.userName[0].toUpperCase() : 'U',
        style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 18),
      ),
    );
  }

  Widget _buildUserHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          review.userName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        if (isMine)
          _buildMineActions()
      ],
    );
  }

  Widget _buildMineActions() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.edit_outlined, color: Colors.cyanAccent, size: 20),
          onPressed: onEdit,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 12),
        IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
          onPressed: onDelete,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  Widget _buildRatingAndBadge() {
    return Row(
      children: [
        AnimatedRatingBar(rating: review.rating, size: 14),
        const SizedBox(width: 12),
        if (review.isVerified)
          _buildVerifiedBadge(),
        const Spacer(),
        Text(
          DateFormat('dd MMM yyyy').format(review.createdAt),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildVerifiedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.greenAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified_user, color: Colors.greenAccent, size: 10),
          const SizedBox(width: 4),
          Text(
            'Verified Buyer',
            style: TextStyle(color: Colors.greenAccent.withValues(alpha: 0.9), fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGallery(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: review.images.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: InkWell(
                  onTap: () => _showImagePreview(context, review.images[index]),
                  child: Hero(
                    tag: review.images[index],
                    child: Container(
                      width: 90,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          review.images[index],
                          width: 90,
                          height: 90,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              width: 90,
                              height: 90,
                              color: Colors.white.withValues(alpha: 0.1),
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                      : null,
                                  color: Colors.cyanAccent,
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            debugPrint('❌ Review Image Load Error: ${review.images[index]}');
                            debugPrint('❌ Error: $error');
                            return Container(
                              width: 90,
                              height: 90,
                              color: Colors.white.withValues(alpha: 0.1),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.broken_image, color: Colors.white24, size: 30),
                                  SizedBox(height: 4),
                                  Text('Failed', style: TextStyle(color: Colors.white24, fontSize: 10)),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionToolbar() {
    return Row(
      children: [
        InkWell(
          onTap: onHelpful,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: review.isHelpful ? Colors.cyanAccent.withOpacity(0.2) : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: review.isHelpful ? Colors.cyanAccent.withOpacity(0.5) : Colors.white.withOpacity(0.1),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  review.isHelpful ? Icons.thumb_up : Icons.thumb_up_outlined,
                  color: review.isHelpful ? Colors.cyanAccent : Colors.white70,
                  size: 14,
                ),
                const SizedBox(width: 8),
                Text(
                  review.helpfulCount > 0 ? '${review.helpfulCount} Helpful' : 'Helpful',
                  style: TextStyle(
                    color: review.isHelpful ? Colors.cyanAccent : Colors.white70,
                    fontSize: 12,
                    fontWeight: review.isHelpful ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
        // Add more actions here if needed (e.g. Share)
      ],
    );
  }

  Widget _buildSellerReply() {
    return Container(
      margin: const EdgeInsets.only(top: 12, left: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.cyanAccent.withOpacity(0.05),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        border: Border.all(color: Colors.cyanAccent.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.storefront, color: Colors.cyanAccent, size: 16),
              const SizedBox(width: 8),
              const Text(
                'Seller Response',
                style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const Spacer(),
              if (review.sellerReplyAt != null)
                Text(
                  DateFormat('dd MMM yyyy').format(review.sellerReplyAt!),
                  style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            review.sellerReply!,
            style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyAction(BuildContext context) {
    final controller = TextEditingController();
    return Container(
      margin: const EdgeInsets.only(top: 12, left: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          TextField(
            controller: controller,
            maxLines: 2,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Add a response to this customer...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          TextButton(
            onPressed: () => onReply?.call(controller.text),
            child: const Text('Send Reply', style: TextStyle(color: Colors.cyanAccent)),
          ),
        ],
      ),
    );
  }

  void _showImagePreview(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
