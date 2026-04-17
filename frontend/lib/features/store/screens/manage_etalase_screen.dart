import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/store_models.dart';
import '../controllers/store_controller.dart';
import '../../../core/services/api_service.dart';

class ManageEtalaseScreen extends StatefulWidget {
  final int storeId;
  const ManageEtalaseScreen({super.key, required this.storeId});

  @override
  State<ManageEtalaseScreen> createState() => _ManageEtalaseScreenState();
}

class _ManageEtalaseScreenState extends State<ManageEtalaseScreen> {
  late StoreController controller;
  
  @override
  void initState() {
    super.initState();
    // Use Get.find if it's already there, otherwise put it
    if (Get.isRegistered<StoreController>(tag: widget.storeId.toString())) {
      controller = Get.find<StoreController>(tag: widget.storeId.toString());
    } else {
      controller = Get.put(StoreController(storeId: widget.storeId), tag: widget.storeId.toString());
    }
    controller.fetchStoreCategories();
  }

  void _showAddEditSheet({StoreCategoryModel? category}) {
    final nameController = TextEditingController(text: category?.name);
    
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              category == null ? 'Tambah Etalase Baru' : 'Ubah Nama Etalase',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Contoh: Koleksi Ramadhan',
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: Obx(() => ElevatedButton(
                onPressed: controller.isProcessing.value ? null : () {
                  if (nameController.text.isNotEmpty) {
                    if (category == null) {
                      controller.createCategory(nameController.text);
                    } else {
                      controller.editCategory(category.id, nameController.text);
                    }
                    Get.back();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: controller.isProcessing.value 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Simpan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              )),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(StoreCategoryModel category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Hapus Etalase?', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text('Yakin ingin menghapus "${category.name}"? Produk di dalamnya akan dipindah ke "Semua Produk".'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.deleteCategory(category.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showProductPicker(StoreCategoryModel category) {
    // Multi-select products to assign to this category
    final RxSet<int> selectedIds = <int>{}.obs;
    
    // We filter products that belong to this store
    // Ensure controller.products is loaded
    if (controller.products.isEmpty) {
      controller.fetchStoreProducts();
    }

    // Set initial selection
    for (var p in controller.products) {
      if (p.storeCategories.any((sc) => sc.id == category.id)) {
        selectedIds.add(p.id);
      }
    }

    Get.to(() => Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Atur Produk: ${category.name}', style: GoogleFonts.poppins(fontSize: 16)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () {
                controller.assignProductsToCategory(category.id, selectedIds.toList());
                Get.back();
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Simpan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoadingProducts.value) return const Center(child: CircularProgressIndicator());
        if (controller.products.isEmpty) return const Center(child: Text('Tidak ada produk di toko ini'));
        
        return ListView.builder(
          itemCount: controller.products.length,
          itemBuilder: (context, index) {
            final p = controller.products[index];
            return Obx(() {
              final isSelected = selectedIds.contains(p.id);
              final otherCats = p.storeCategories.where((sc) => sc.id != category.id).toList();
              final isInCategory = p.storeCategories.any((sc) => sc.id == category.id);
              
              return CheckboxListTile(
                value: isSelected,
                activeColor: AppColors.primary,
                title: Text(p.name, style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  otherCats.isEmpty 
                    ? (isInCategory ? 'Ada di etalase ini' : 'Belum masuk etalase ini')
                    : 'Juga di: ${otherCats.map((c) => c.name).join(", ")}',
                  style: TextStyle(fontSize: 11, color: otherCats.isNotEmpty ? Colors.orange : Colors.grey),
                ),
                secondary: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    ApiService().getImageUrl(p.images.isNotEmpty ? p.images.first.imageUrl : ''),
                    width: 40, height: 40, fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(width: 40, height: 40, color: Colors.grey[200]),
                  ),
                ),
                onChanged: (v) {
                  if (v == true) {
                    selectedIds.add(p.id);
                  } else {
                    selectedIds.remove(p.id);
                  }
                },
              );
            });
          },
        );
      }),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Kelola Etalase', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditSheet(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Buat Etalase', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Obx(() {
        if (controller.storeCategories.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.category_outlined, size: 80, color: Colors.grey[200]),
                const SizedBox(height: 16),
                Text('Belum ada etalase', style: GoogleFonts.poppins(color: Colors.grey, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text('Kelompokkan produkmu agar pembeli mudah mencari koleksi terbaikmu.', 
                    textAlign: TextAlign.center,
                    style: GoogleFonts.manrope(color: Colors.grey, fontSize: 12),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: controller.storeCategories.length,
          itemBuilder: (context, index) {
            final cat = controller.storeCategories[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))
                ],
                border: Border.all(color: Colors.grey[100]!),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                title: Text(cat.name, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15)),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.inventory_2_outlined, size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text('Atur produk koleksi ini', style: GoogleFonts.manrope(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.playlist_add_circle_outlined, color: AppColors.primary),
                      onPressed: () => _showProductPicker(cat),
                      tooltip: 'Atur Produk',
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Colors.grey),
                      onPressed: () => _showAddEditSheet(category: cat),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: () => _showDeleteConfirmation(cat),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
