import 'dart:convert';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:growup_agro/models/product_details_model.dart';
import 'package:growup_agro/utils/api_constants.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_html/flutter_html.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/product_order_model.dart';

class ProductDetailsPage extends StatefulWidget {
  final String slug;

  const ProductDetailsPage({super.key, required this.slug});

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  late Future<ProductDetailsResponse> _futureProduct;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _futureProduct = fetchProductDetails();
  }

  Future<ProductDetailsResponse> fetchProductDetails() async {

    final url = Uri.parse(ApiConstants.productDetails(widget.slug)); // ✅ use constant
    // final response = await http.get(
    //   Uri.parse("https://growupagro.tech/api/product-details/${widget.slug}"),
    // );
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return ProductDetailsResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Failed to load product details");
    }
  }

  Future<void> placeOrder(Product product) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      final investorCode = prefs.getString('investor_code') ?? '';

      final totalPrice = (int.tryParse(product.sellingPrice.toString()) ?? 0) * _quantity;

      final url = Uri.parse(ApiConstants.placeOrder()); // ✅ use constant

      final response = await http.post(
        // Uri.parse("https://growupagro.tech/api/place-order"),
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "investor_code": investorCode,
          "product_id": product.id,
          "quantity": _quantity,
          "total_price": totalPrice,
          "comment": "Deliver between 9am–12pm"
        }),
      );

      final jsonData = jsonDecode(response.body);

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          jsonData['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Order placed successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${jsonData['message'] ?? response.body}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Product Details",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<ProductDetailsResponse>(
        future: _futureProduct,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData) {
            return const Center(child: Text("No product found"));
          }

          final product = snapshot.data!.data.product;
          final cleanedPriceString = product.sellingPrice.replaceAll(',', '');
          final unitPrice = double.tryParse(cleanedPriceString) ?? 0.0;
          final isAvailable = unitPrice > 0.0 && product.inStock > 0;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image carousel
                    if (product.imageUrls.isNotEmpty)
                      CarouselSlider(
                        options: CarouselOptions(
                          height: 250,
                          enlargeCenterPage: true,
                          enableInfiniteScroll: false,
                          viewportFraction: 0.9,
                        ),
                        items: product.imageUrls.map((url) {
                          return ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                            child: Image.network(
                              "https://growupagro.tech$url",
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          );
                        }).toList(),
                      ),

                    // Product info
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Center(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              product.productName,
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Category: ${product.categoryName}",
                              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                            ),
                            const SizedBox(height: 12),
                            Html(data: product.metaDescription),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),

                    const Divider(),

                    // Card footer
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Center(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [


                            Text(
                              "Product: ${product.productName}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                                fontSize: 16,
                              ),
                            ),
                            Text("Category: ${product.categoryName}"),

                            // 🏆 FIX 1: Display the parsed, formatted price (or 'Upcoming')
                            Text(
                              isAvailable
                                  ? "Price: ৳ ${unitPrice.toStringAsFixed(2)}"
                                  : "Price: Upcoming",
                              style: TextStyle(
                                fontSize: 16,
                                color: isAvailable ? Colors.black : Colors.amber.shade800,
                                fontWeight: isAvailable ? FontWeight.normal : FontWeight.bold,
                              ),
                            ),

                            Text("Available: ${product.inStock} ${product.stockUnit}"),
                            const SizedBox(height: 12),

                            // 🏆 FIX 2: CONDITIONAL Quantity selector
                            if (isAvailable) ...[
                              // Quantity selector
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle, color: Colors.red),
                                    onPressed: () {
                                      setState(() {
                                        if (_quantity > 1) _quantity--;
                                      });
                                    },
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '$_quantity',
                                      style: const TextStyle(
                                          fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle, color: Colors.green),
                                    onPressed: () {
                                      setState(() {
                                        if (_quantity < product.inStock) {
                                          _quantity++;
                                        }
                                      });
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                            ],

                            // 🏆 FIX 3: CONDITIONAL Book Now button / Upcoming Status
                            isAvailable
                                ? SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: () {
                                  // Use the clean 'unitPrice' calculated above
                                  final totalPrice = unitPrice * _quantity;

                                  showDialog(
                                    context: context,
                                    builder: (context) => Dialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 8,
                                      child: Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(16),
                                          color: Colors.white,
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            // ... (Dialog Header) ...
                                            Container(
                                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                              decoration: BoxDecoration(
                                                color: Colors.green[700],
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: const Center(
                                                child: Text(
                                                  "Place Your Order",
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 18,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            Row(
                                              children: [
                                                const Icon(Icons.shopping_bag, color: Colors.green),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    product.productName,
                                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),

                                            // Dialogue Unit Price (using formatted price)
                                            Row(
                                              children: [
                                                const Icon(Icons.attach_money, color: Colors.green),
                                                const SizedBox(width: 8),
                                                Text("Unit Price: ৳ ${unitPrice.toStringAsFixed(2)}", style: const TextStyle(fontSize: 16)),
                                              ],
                                            ),
                                            const SizedBox(height: 8),

                                            // ... (Quantity and Total Price) ...
                                            Row(
                                              children: [
                                                const Icon(Icons.format_list_numbered, color: Colors.green),
                                                const SizedBox(width: 8),
                                                Text("Quantity: $_quantity", style: const TextStyle(fontSize: 16)),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            Row(
                                              children: [
                                                const Icon(Icons.price_check, color: Colors.green),
                                                const SizedBox(width: 8),
                                                // Dialogue Total Price (using formatted price)
                                                Text(
                                                  "Total Price: ৳ ${totalPrice.toStringAsFixed(2)}",
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.green,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 20),

                                            // ... (Dialog buttons) ...
                                            Row(
                                              children: [
                                                // Cancel Button
                                                Expanded(
                                                  child: ElevatedButton.icon(
                                                    icon: const Icon(Icons.cancel, color: Colors.white, size: 20),
                                                    label: const Text("Cancel", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                                    onPressed: () => Navigator.of(context).pop(),
                                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red[600], padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 4),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                // Place Order Button
                                                Expanded(
                                                  child: ElevatedButton.icon(
                                                    icon: const Icon(Icons.shopping_cart_checkout, color: Colors.white, size: 20),
                                                    label: const Text("Place Order", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                                    onPressed: () async {
                                                      Navigator.of(context).pop();
                                                      await placeOrder(product);
                                                    },
                                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 4),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'Book Now',
                                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ),
                            )
                                : Container(
                              width: double.infinity,
                              height: 50,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.amber.shade100,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.amber.shade300),
                              ),
                              child: Text(
                                'Product Upcoming',
                                style: TextStyle(
                                  color: Colors.amber.shade800,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
