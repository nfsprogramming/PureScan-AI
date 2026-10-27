// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mobile/features/community/presentation/screens/product_community_screen.dart';
import '../../data/community_repository.dart';

class CommunitySearchScreen extends ConsumerStatefulWidget {
  const CommunitySearchScreen({super.key});

  @override
  ConsumerState<CommunitySearchScreen> createState() => _CommunitySearchScreenState();
}

class _CommunitySearchScreenState extends ConsumerState<CommunitySearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  List<dynamic> _searchResults = [];
  String _errorMessage = '';

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _errorMessage = '';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final supabaseResponse = await Supabase.instance.client
          .from('products')
          .select()
          .ilike('name', '%$query%')
          .limit(20);

      setState(() {
        _searchResults = supabaseResponse;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Community Database', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.onSurface,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            color: Theme.of(context).colorScheme.onSurface,
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: TextField(
              controller: _searchController,
              onSubmitted: _performSearch,
              decoration: InputDecoration(
                hintText: 'Search products by name or barcode...',
                fillColor: Colors.white,
                filled: true,
                prefixIcon: const Icon(Icons.search, color: Color(0xFF3F6653)),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    _performSearch('');
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          
          Expanded(
            child: _searchController.text.isEmpty 
              ? Consumer(
                  builder: (context, ref, child) {
                    final productsAsync = ref.watch(communityProductsProvider(1));
                    return productsAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF2E8B57))),
                      error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
                      data: (products) {
                        if (products.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                                const SizedBox(height: 16),
                                const Text('No products in the community database yet.', style: TextStyle(color: Colors.grey, fontSize: 16)),
                              ],
                            ),
                          );
                        }
                        return ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: products.length,
                          itemBuilder: (context, index) {
                            final product = products[index];
                            return _buildProductCard(product);
                          },
                        );
                      }
                    );
                  },
                )
              : _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF2E8B57)))
                : _errorMessage.isNotEmpty
                    ? Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red)))
                    : _searchResults.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.search_off, size: 64, color: Colors.grey),
                                const SizedBox(height: 16),
                                const Text(
                                  'No products found',
                                  style: TextStyle(color: Colors.grey, fontSize: 16),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final product = _searchResults[index];
                              return _buildProductCard(product);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(dynamic product) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.inventory_2, color: Color(0xFF2E8B57)),
        ),
        title: Text(
          product['name'] ?? 'Unknown',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Barcode: ${product['barcode'] ?? 'N/A'}'),
            if (product['ingredients_text'] != null && product['ingredients_text'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(Icons.science, size: 14, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 4),
                    Text(
                      'Ingredient analysis available',
                      style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductCommunityScreen(
                barcode: product['barcode']?.toString() ?? 'unknown',
                productName: product['name'] ?? 'Unknown',
                averageRating: ((product['trust_score'] ?? 0) / 20.0).toDouble(),
                ingredientsText: product['ingredients_text']?.toString(),
              ),
            ),
          );
        },
      ),
    );
  }
}
