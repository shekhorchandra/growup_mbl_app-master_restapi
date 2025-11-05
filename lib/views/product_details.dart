import 'dart:convert';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:growup_agro/models/product_details_model.dart';
import 'package:growup_agro/utils/api_constants.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/custom_button.dart';

class ProductDetailsPage extends StatefulWidget {
  final String slug;
  const ProductDetailsPage({super.key, required this.slug});

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  late Future<ProductDetailsResponse> _futureProduct;
  int _quantity = 1;
  bool _isPlacingOrder = false;

  @override
  void initState() {
    super.initState();
    _futureProduct = fetchProductDetails();
  }

  Future<ProductDetailsResponse> fetchProductDetails() async {
    final url = Uri.parse(ApiConstants.productDetails(widget.slug));
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return ProductDetailsResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Failed to load product details");
    }
  }

  Future<void> placeOrder(Product product) async {
    setState(() => _isPlacingOrder = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      final investorCode = prefs.getString('investor_code') ?? '';

      final totalPrice =
          (int.tryParse(product.sellingPrice.toString()) ?? 0) * _quantity;

      final url = Uri.parse(ApiConstants.placeOrder());

      final response = await http.post(
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
          "comment": "Deliver between 9am–12pm",
        }),
      );

      final jsonData = jsonDecode(response.body);
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          jsonData['success'] == true) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("✅ Order placed successfully!"),
              backgroundColor: Colors.green,
            ),
          );
        }
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
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isPlacingOrder = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          "Product Details",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF2E7D32),
      ),
      body: FutureBuilder<ProductDetailsResponse>(
        future: _futureProduct,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text("No product found"));
          }

          final product = snapshot.data!.data.product;
          final cleanedPriceString = product.sellingPrice.replaceAll(',', '');
          final unitPrice = double.tryParse(cleanedPriceString) ?? 0.0;
          final isAvailable = unitPrice > 0.0 && product.inStock > 0;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (product.imageUrls.isNotEmpty)
                  CarouselSlider(
                    options: CarouselOptions(
                      height: 260,
                      enlargeCenterPage: true,
                      enableInfiniteScroll: false,
                      viewportFraction: 1,
                    ),
                    items: product.imageUrls.map((url) {
                      return Image.network(
                        "https://growupagro.tech$url",
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, _, __) => Container(
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.image_not_supported,
                              size: 50, color: Colors.grey),
                        ),
                      );
                    }).toList(),
                  ),


                //Product Title & Info
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.productName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Category: ${product.categoryName} | Available: ${product.inStock} ${product.stockUnit}",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        isAvailable
                            ? "৳ ${unitPrice.toStringAsFixed(2)}"
                            : "Upcoming Product",
                        style: TextStyle(
                          fontSize: 18,
                          color: isAvailable
                              ? Colors.green.shade700
                              : Colors.amber.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Html(
                        data: product.metaDescription,
                        style: {
                          "body": Style(
                            fontSize: FontSize(14),
                            color: Colors.grey.shade800,
                            margin: Margins.zero,
                          ),
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                //Quantity Selector
                if (isAvailable)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          )
                        ],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text(
                            "Select Quantity",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline,
                                    color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    if (_quantity > 1) _quantity--;
                                  });
                                },
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 8),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '$_quantity',
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline,
                                    color: Colors.green),
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
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 20),

                //Action Button (Sticky Bottom Style)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: CustomButton(
                      icon: Icons.shopping_cart_checkout_rounded,
                      text: isAvailable
                          ? (_isPlacingOrder ? "Processing..." : "Book Now")
                          : "Upcoming Product",
                      loading: _isPlacingOrder,
                      backgroundColor: isAvailable
                          ? const Color(0xFF2E7D32)
                          : Colors.amber.shade700,
                      height: 45,
                      fontSize: 16,
                      borderRadius: 10,
                      onPressed: isAvailable && !_isPlacingOrder
                          ? () {
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
                                  // Header
                                  const Center(
                                    child: Text(
                                      "Order Summary",
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  Row(
                                    children: [
                                      const Icon(Icons.shopping_bag,
                                          color: Colors.green, size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          product.productName,
                                          style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  Row(
                                    children: [
                                      const Icon(Icons.attach_money,
                                          color: Colors.green, size: 16,),
                                      const SizedBox(width: 8),
                                      Text(
                                        "Unit Price: ৳ ${unitPrice.toStringAsFixed(2)}",
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),

                                  Row(
                                    children: [
                                      const Icon(Icons.format_list_numbered,
                                          color: Colors.green, size: 16,),
                                      const SizedBox(width: 8),
                                      Text("Quantity: $_quantity",
                                          style: const TextStyle(fontSize: 14)),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  Row(
                                    children: [
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

                                  // Action Buttons
                                  Row(
                                    children: [
                                      Expanded(
                                        child: CustomButton(
                                          text: "Cancel",
                                          backgroundColor: Colors.red[600]!,
                                          height: 44,
                                          fontSize: 14,
                                          borderRadius: 10,
                                          onPressed: () =>
                                              Navigator.of(context).pop(),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: CustomButton(
                                          text: "Place Order",
                                          backgroundColor: Colors.green[700]!,
                                          height: 44,
                                          fontSize: 14,
                                          borderRadius: 10,
                                          onPressed: () async {
                                            Navigator.of(context).pop();
                                            await placeOrder(product);
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }
                          : null,
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}
