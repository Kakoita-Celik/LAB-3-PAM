import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use GetMaterialApp for GetX navigation and dependency management
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'lab2',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'SF Pro',
      ),
      home: const HomeScreen(),
    );
  }
}

// Product Model (same as your original)
class Product {
  final String? id;
  final String title;
  final String? brand;
  final double? price;
  final double? oldPrice;
  final int? discount;
  final List<String> imageUrls;
  final double? rating;
  final int? reviews;
  final bool? isNew;
  final String? description;

  Product({
    this.id,
    required this.title,
    this.brand,
    this.price,
    this.oldPrice,
    this.discount,
    required this.imageUrls,
    this.rating,
    this.reviews,
    this.isNew,
    this.description,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      title: json['title'],
      brand: json['brand'],
      price: json['price']?.toDouble(),
      oldPrice: json['oldPrice']?.toDouble(),
      discount: json['discount'],
      imageUrls: List<String>.from(json['imageUrls']),
      rating: json['rating']?.toDouble(),
      reviews: json['reviews'],
      isNew: json['isNew'],
      description: json['description'],
    );
  }
}

// GetX Controller
class ProductController extends GetxController {
  final RxList<Product> allProducts = <Product>[].obs;
  final Rxn<Product> heroProduct = Rxn<Product>();
  final RxList<Product> saleProducts = <Product>[].obs;
  final RxList<Product> newProducts = <Product>[].obs;
  final RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadProducts();
  }

  Future<void> loadProducts() async {
    try {
      isLoading.value = true;
      final String jsonString = await rootBundle.loadString('assets/products.json');
      final dynamic decoded = json.decode(jsonString);

      List<dynamic> jsonData;
      if (decoded is List) {
        jsonData = decoded;
      } else if (decoded is Map && decoded['products'] is List) {
        jsonData = decoded['products'];
      } else {
        jsonData = [decoded];
      }

      final loaded = jsonData.map<Product>((j) {
        if (j is Map<String, dynamic>) return Product.fromJson(j);
        return Product.fromJson(Map<String, dynamic>.from(j));
      }).toList();

      allProducts.assignAll(loaded);

      heroProduct.value = allProducts.isNotEmpty ? allProducts[0] : null;

      saleProducts.assignAll(allProducts.where((p) => p.discount != null && p.discount! > 0).toList());
      newProducts.assignAll(allProducts.where((p) => p.isNew == true).toList());
    } catch (e) {
      // keep simple error logging
      debugPrint('Error loading products: $e');
    } finally {
      isLoading.value = false;
    }
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  // Create and register controller
  @override
  Widget build(BuildContext context) {

    final ProductController controller = Get.put(ProductController(), permanent: true);

    return Obx(() {
      if (controller.isLoading.value) {
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      final heroProduct = controller.heroProduct.value;

      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero Section
                if (heroProduct != null)
                  Stack(
                    children: [
                      Container(
                        height: 280,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage(heroProduct.imageUrls[0]),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Container(
                        height: 280,
                      ),
                      Positioned(
                        left: 24,
                        bottom: 40,
                        child: Text(
                          heroProduct.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 24),

                // Sale Section
                if (controller.saleProducts.isNotEmpty) ...[
                  _buildSectionHeader('Sale', 'Super summer sale'),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 320,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: controller.saleProducts.length,
                      itemBuilder: (context, index) {
                        final product = controller.saleProducts[index];
                        return ProductCard(
                          image: product.imageUrls[0],
                          badge: '-${product.discount}%',
                          badgeColor: const Color(0xFFDB3022),
                          rating: product.rating?.toInt() ?? 0,
                          reviewCount: product.reviews ?? 0,
                          brand: product.brand ?? '',
                          name: product.title,
                          originalPrice: '\$${product.oldPrice?.toStringAsFixed(0)}',
                          salePrice: '\$${product.price?.toStringAsFixed(0)}',
                          onTap: () {
                            // Use Get.to for navigation
                            Get.to(() => ProductDetailScreen(product: product));
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 32),
                ],

                // New Section
                if (controller.newProducts.isNotEmpty) ...[
                  _buildSectionHeader('New', 'You\'ve never seen it before!'),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 320,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: controller.newProducts.length,
                      itemBuilder: (context, index) {
                        final product = controller.newProducts[index];
                        return ProductCard(
                          image: product.imageUrls[0],
                          badge: 'NEW',
                          badgeColor: Colors.black,
                          rating: product.rating?.toInt() ?? 0,
                          reviewCount: product.reviews ?? 0,
                          brand: product.brand ?? '',
                          name: product.title,
                          price: '\$${product.price?.toStringAsFixed(0)}',
                          onTap: () {
                            Get.to(() => ProductDetailScreen(product: product));
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const Text(
            'View all',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

// ProductCard unchanged except for any minor null-safety adaptions
class ProductCard extends StatelessWidget {
  final String image;
  final String badge;
  final Color badgeColor;
  final int rating;
  final int reviewCount;
  final String brand;
  final String name;
  final String? originalPrice;
  final String? salePrice;
  final String? price;
  final VoidCallback onTap;

  const ProductCard({
    Key? key,
    required this.image,
    required this.badge,
    required this.badgeColor,
    required this.rating,
    required this.reviewCount,
    required this.brand,
    required this.name,
    this.originalPrice,
    this.salePrice,
    this.price,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    image,
                    height: 200,
                    width: 160,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 200,
                      width: 160,
                      color: Colors.grey[200],
                      child: const Icon(Icons.broken_image),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite_border,
                      color: Colors.grey,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ...List.generate(
                  5,
                      (index) => Icon(
                    Icons.star,
                    size: 14,
                    color: index < rating ? const Color(0xFFFFBA49) : Colors.grey[300],
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '($reviewCount)',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              brand,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
              ),
            ),
            Text(
              name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            if (salePrice != null)
              Row(
                children: [
                  Text(
                    originalPrice ?? '',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    salePrice!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFFDB3022),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            else if (price != null)
              Text(
                price!,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ProductDetailScreen extends StatelessWidget {
  final Product product;

  const ProductDetailScreen({Key? key, required this.product}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ProductController controller = Get.find<ProductController>();

    // derive similar products from controller's allProducts (exclude same id)
    final String? currentIdStr = product.id?.toString();
    final similarProducts = controller.allProducts
        .where((p) => p.id?.toString() != currentIdStr)
        .take(3)
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: Text(
          product.title,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Images
            SizedBox(
              height: 380,
              child: PageView.builder(
                itemCount: product.imageUrls.length,
                itemBuilder: (context, index) {
                  return Image.asset(
                    product.imageUrls[index],
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, st) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.broken_image),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Size and Color Selectors
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdown('Size'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDropdown('Black'),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.favorite_border,
                          color: Colors.grey,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Brand and Price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.brand ?? '',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            product.title,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 20),
                      Row(
                        children: [
                          if (product.oldPrice != null) ...[
                            Text(
                              '\$${product.oldPrice!.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 24,
                                color: Colors.grey,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            '\$${product.price?.toStringAsFixed(0) ?? '0'}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: product.oldPrice != null ? Colors.red : Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Rating
                  Row(
                    children: [
                      ...List.generate(
                        5,
                            (index) => Icon(
                          Icons.star,
                          size: 16,
                          color: index < (product.rating?.toInt() ?? 0)
                              ? const Color(0xFFFFBA49)
                              : Colors.grey[300],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${product.reviews ?? 0})',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Description
                  Text(
                    product.description ?? '',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Add to Cart Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDB3022),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'ADD TO CART',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Shipping Info & Support
                  Divider(color: Colors.grey[300]),
                  _buildListTile('Shipping info'),
                  Divider(color: Colors.grey[300]),
                  _buildListTile('Support'),
                  Divider(color: Colors.grey[300]),
                  const SizedBox(height: 24),

                  // You can also like this
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'You can also like this',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        '${similarProducts.length} items',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Similar Products
                  SizedBox(
                    height: 320,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: similarProducts.length,
                      itemBuilder: (context, index) {
                        final similarProduct = similarProducts[index];
                        return ProductCard(
                          image: similarProduct.imageUrls[0],
                          badge: similarProduct.discount != null
                              ? '-${similarProduct.discount}%'
                              : 'NEW',
                          badgeColor: similarProduct.discount != null
                              ? const Color(0xFFDB3022)
                              : Colors.black,
                          rating: similarProduct.rating?.toInt() ?? 0,
                          reviewCount: similarProduct.reviews ?? 0,
                          brand: similarProduct.brand ?? '',
                          name: similarProduct.title,
                          originalPrice: similarProduct.oldPrice != null
                              ? '\$${similarProduct.oldPrice!.toStringAsFixed(0)}'
                              : null,
                          salePrice: similarProduct.oldPrice != null
                              ? '\$${similarProduct.price?.toStringAsFixed(0)}'
                              : null,
                          price: similarProduct.oldPrice == null
                              ? '\$${similarProduct.price?.toStringAsFixed(0)}'
                              : null,
                          onTap: () {
                            Get.to(() => ProductDetailScreen(product: similarProduct));
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black,
            ),
          ),
          const Icon(Icons.keyboard_arrow_down, size: 20),
        ],
      ),
    );
  }

  Widget _buildListTile(String title) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.black),
      onTap: () {},
    );
  }
}
