import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:growup_agro/utils/api_constants.dart';
import 'package:growup_agro/views/product_details.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:share_plus/share_plus.dart';

import '../models/all_products_model.dart';

class AllProductsPage extends StatefulWidget {
  const AllProductsPage({super.key});

  @override
  State<AllProductsPage> createState() => _AllProductsPageState();
}

class _AllProductsPageState extends State<AllProductsPage> {
  List<Product> products = [];
  bool isLoading = true;
  final ScrollController _scrollController = ScrollController();
  bool _showBackToTopButton = false;

  @override
  void initState() {
    super.initState();
    fetchProducts();

    _scrollController.addListener(() {
      if (_scrollController.offset >= 300 && !_showBackToTopButton) {
        setState(() => _showBackToTopButton = true);
      } else if (_scrollController.offset < 300 && _showBackToTopButton) {
        setState(() => _showBackToTopButton = false);
      }
    });
  }

  Future<void> fetchProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    final investorCode = prefs.getString('investor_code') ?? '';

    final url = Uri.parse(ApiConstants.products(investorCode));
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      final List productsData = jsonData['data']['products'];
      setState(() {
        products = productsData.map((e) => Product.fromJson(e)).toList();
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Failed to load products')));
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Product Lists",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(10),
        itemCount: products.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // 2 per row
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          // 🏆 REDESIGN: Adjusted childAspectRatio for a slightly squatter, cleaner card
          childAspectRatio: 0.65,
        ),
        itemBuilder: (context, index) {
          final product = products[index];
          return _buildProductGridItem(context, product);
        },
      ),
      floatingActionButton: _showBackToTopButton
          ? FloatingActionButton(
        onPressed: _scrollToTop,
        backgroundColor: Colors.orange,
        child: const Icon(Icons.arrow_upward, color: Colors.white),
      )
          : null,
    );
  }

// -----------------------------------------------------------
// 🏆 REDESIGNED PRODUCT GRID ITEM WIDGET
// -----------------------------------------------------------

  Widget _buildProductGridItem(BuildContext context, Product product) {
    // Ensure sellingPrice is treated as a number for comparison
    final num price = product.numericSellingPrice;
    final bool isAvailable = price > 0;

    return Card(
      elevation: 3.0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0), // Slightly less rounded
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- IMAGE SECTION (Less Vertical Space) ---
          Expanded(
            flex: 4, // 🏆 REDESIGN: Reduced flex to 4 (from 6) to shorten image height
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Product Image
                // Image.network(
                //   'https://growupagro.tech${product.imageUrl}',
                //   fit: BoxFit.cover,
                //   errorBuilder: (context, error, stack) => Container(
                //     color: Colors.grey.shade200,
                //     child: Icon(Icons.image_not_supported, color: Colors.grey.shade400, size: 40),
                //   ),
                // ),
                Image.network(
                  ApiConstants.getProductImage(product.imageUrl),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => Container(
                    color: Colors.grey.shade200,
                    child: Icon(Icons.image_not_supported, color: Colors.grey.shade400, size: 40),
                  ),
                ),


                // Sale Banner
                if (isAvailable) // Only show discount if product is available
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3), // Reduced padding
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        '15% OFF',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10, // Smaller font
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                // Share Button (Moved to right side for modern alignment)
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: GestureDetector(
                    // onTap: () { Share.share(...) },
                    child: Container(
                      padding: const EdgeInsets.all(4), // Square padding
                      decoration: BoxDecoration(
                        color: Colors.black54, // Dark overlay for better contrast
                        borderRadius: BorderRadius.circular(100), // Circular background
                      ),
                      child: const Icon(Icons.share, size: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- CONTENT SECTION (More Vertical Space) ---
          Expanded(
            flex: 5, // 🏆 REDESIGN: Increased flex to 5 (from 5, but relative gain due to image change)
            child: Padding(
              padding: const EdgeInsets.all(8.0), // Reduced padding for compactness
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Title, Category, and Price
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.productName,
                        style: const TextStyle(
                          fontSize: 14, // Slightly smaller
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                        maxLines: 2, // Allow for 2 lines now
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        product.categoryName,
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500), // Lighter secondary color
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "৳ ${isAvailable ? price.toString() : 'Upcoming'}",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isAvailable ? Colors.green.shade800 : Colors.amber.shade800, // Price color changes based on status
                        ),
                      ),
                    ],
                  ),

                  // 🏆 REDESIGN: Conditional Action Button/Status
                  isAvailable
                      ? SizedBox(
                    width: double.infinity,
                    height: 30, // Slightly smaller button
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductDetailsPage(slug: product.slug),
                          ),
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      icon: const Icon(Icons.shopping_cart_outlined, size: 13),
                      label: const Text(
                        'Book Now',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12, // Slightly smaller font
                        ),
                      ),
                    ),
                  )
                      : Container(
                    height: 30,
                    width: double.infinity,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.amber.shade300, width: 0.8),
                    ),
                    child: Text(
                      'UPCOMING',
                      style: TextStyle(
                        color: Colors.amber.shade800,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
