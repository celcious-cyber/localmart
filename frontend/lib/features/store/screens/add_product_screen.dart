import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../../../core/services/api_service.dart';
import '../../../shared/models/home_data.dart';

class AddProductScreen extends StatefulWidget {
  final ProductModel? product;
  const AddProductScreen({super.key, this.product});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  
  // Basic Info
  String _name = '';
  String _description = '';
  double _price = 0;
  int _stock = 0;
  CategoryModel? _selectedCategory;
  
  // Dimensions & Weight
  double _weight = 0;
  int _length = 0;
  int _width = 0;
  int _height = 0;
  
  // Images
  final List<XFile> _selectedFiles = [];
  final Map<String, Uint8List> _imageBytesCache = {}; // Cache for web preview
  List<String> _existingUrls = [];
  
  List<CategoryModel> _categories = [];
  bool _isLoadingCategories = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _name = widget.product!.name;
      _description = widget.product!.description;
      _price = widget.product!.price;
      _stock = widget.product!.stock;
      _weight = widget.product!.weight;
      _length = widget.product!.length;
      _width = widget.product!.width;
      _height = widget.product!.height;
      _existingUrls = widget.product!.images.map((i) => i.imageUrl).toList();
    }
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    final cats = await ApiService().getCategories();
    if (mounted) {
      setState(() {
        _categories = cats;
        if (widget.product != null) {
          _selectedCategory = _categories.firstWhere(
            (c) => c.id == widget.product!.categoryId,
            orElse: () => _categories.first,
          );
        }
        _isLoadingCategories = false;
      });
    }
  }

  Future<void> _pickAndCropImage() async {
    if (_selectedFiles.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maksimal 5 foto per produk'))
      );
      return;
    }

    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      if (!mounted) return;
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1), // Lock to Square
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Sesuaikan Foto (1:1)',
            toolbarColor: Colors.orange,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Sesuaikan Foto (1:1)',
            aspectRatioLockEnabled: true,
          ),
          WebUiSettings(
            context: context,
            presentStyle: WebPresentStyle.dialog,
            size: const CropperSize(
              width: 520,
              height: 520,
            ),
          ),
        ],
      );

      if (croppedFile != null) {
        final bytes = await croppedFile.readAsBytes();
        setState(() {
          final xFile = XFile(croppedFile.path);
          _selectedFiles.add(xFile);
          _imageBytesCache[xFile.path] = bytes;
        });
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      final file = _selectedFiles.removeAt(index);
      _imageBytesCache.remove(file.path);
    });
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedFiles.isEmpty && _existingUrls.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Minimal unggah 1 foto produk'), backgroundColor: Colors.red),
        );
        return;
      }

      _formKey.currentState!.save();
      setState(() => _isSaving = true);

      try {
        // 1. Upload new images
        List<ProductImageModel> uploadedImages = [];
        
        // Add existing ones
        for (var url in _existingUrls) {
          uploadedImages.add(ProductImageModel(id: 0, imageUrl: url));
        }

        // Upload and add new ones
        for (int i = 0; i < _selectedFiles.length; i++) {
          final bytes = await _selectedFiles[i].readAsBytes();
          final fileName = _selectedFiles[i].path.split('/').last;
          
          final url = await ApiService().uploadImage(bytes, fileName);
          if (url != null) {
            uploadedImages.add(ProductImageModel(id: 0, imageUrl: url));
          }
        }

        String mainImageUrl = uploadedImages.isNotEmpty ? uploadedImages.first.imageUrl : '';

        // 2. Create/Update Product
        final product = ProductModel(
          id: widget.product?.id ?? 0,
          categoryId: _selectedCategory!.id,
          storeId: widget.product?.storeId ?? 0,
          name: _name,
          description: _description,
          price: _price,
          imageUrl: mainImageUrl,
          stock: _stock,
          sold: widget.product?.sold ?? 0,
          isActive: true,
          weight: _weight,
          length: _length,
          width: _width,
          height: _height,
          images: uploadedImages,
        );

        final result = widget.product == null 
            ? await ApiService().createStoreProduct(product)
            : await ApiService().updateStoreProduct(product);
        
        if (mounted) {
          setState(() => _isSaving = false);
          if (result['success']) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(result['message']), backgroundColor: Colors.green),
            );
            Navigator.pop(context, true);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(result['message']), backgroundColor: Colors.red),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Terjadi kesalahan: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Tambah Produk Baru',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: _isLoadingCategories 
        ? const Center(child: CircularProgressIndicator(color: Colors.orange))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildImageSection(),
                  const SizedBox(height: 32),
                  
                  _buildLabel('Nama Produk'),
                  TextFormField(
                    initialValue: _name,
                    decoration: _inputDecoration('Contoh: Kopi Tepal 200g'),
                    validator: (v) => v == null || v.isEmpty ? 'Nama wajib diisi' : null,
                    onSaved: (v) => _name = v ?? '',
                  ),
                  const SizedBox(height: 20),
                  
                  _buildLabel('Kategori'),
                  DropdownButtonFormField<CategoryModel>(
                    initialValue: _selectedCategory,
                    decoration: _inputDecoration('Pilih kategori produk'),
                    items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
                    onChanged: (v) => setState(() => _selectedCategory = v),
                    validator: (v) => v == null ? 'Kategori wajib dipilih' : null,
                  ),
                  const SizedBox(height: 20),
                  
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Harga (Rp)'),
                            TextFormField(
                              initialValue: _price > 0 ? _price.toInt().toString() : '',
                              keyboardType: TextInputType.number,
                              decoration: _inputDecoration('Contoh: 50000'),
                              validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                              onSaved: (v) => _price = double.tryParse(v ?? '0') ?? 0,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Stok Awal'),
                            TextFormField(
                              initialValue: _stock.toString(),
                              keyboardType: TextInputType.number,
                              decoration: _inputDecoration('Contoh: 10'),
                              validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                              onSaved: (v) => _stock = int.tryParse(v ?? '0') ?? 0,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  _buildDimensionSection(),
                  const SizedBox(height: 20),
                  
                  _buildLabel('Deskripsi Produk'),
                  TextFormField(
                    initialValue: _description,
                    maxLines: 4,
                    decoration: _inputDecoration('Jelaskan detail produk Anda...'),
                    validator: (v) => v == null || v.isEmpty ? 'Deskripsi wajib diisi' : null,
                    onSaved: (v) => _description = v ?? '',
                  ),
                  const SizedBox(height: 48),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: _isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Simpan Produk',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildLabel('Foto Produk (Maks 5)'),
            Text(
              '${_selectedFiles.length}/5',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _existingUrls.length + _selectedFiles.length + 1,
            itemBuilder: (context, index) {
              if (index < _existingUrls.length) {
                return _buildExistingImageItem(index);
              } else if (index < _existingUrls.length + _selectedFiles.length) {
                return _buildImageItem(index - _existingUrls.length);
              } else if (_existingUrls.length + _selectedFiles.length < 5) {
                return _buildAddImageButton();
              }
              return const SizedBox.shrink();
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '* Gunakan foto rasio 1:1 untuk tampilan terbaik',
          style: GoogleFonts.poppins(fontSize: 10, color: Colors.orange, fontStyle: FontStyle.italic),
        ),
      ],
    );
  }

  Widget _buildImageItem(int index) {
    final file = _selectedFiles[index];
    final bytes = _imageBytesCache[file.path];

    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[100],
      ),
      child: Stack(
        children: [
          // Preview
          if (bytes != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(bytes, width: 100, height: 100, fit: BoxFit.cover),
            ),
          
          Positioned(
            right: 4,
            top: 4,
            child: GestureDetector(
              onTap: () => _removeImage(index),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                child: const Icon(Icons.close, color: Colors.white, size: 14),
              ),
            ),
          ),
          if (_existingUrls.isEmpty && index == 0)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
                ),
                child: Text(
                  'Utama',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExistingImageItem(int index) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: DecorationImage(
          image: NetworkImage(ApiService().getImageUrl(_existingUrls[index])),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: 4,
            top: 4,
            child: GestureDetector(
              onTap: () => setState(() => _existingUrls.removeAt(index)),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                child: const Icon(Icons.close, color: Colors.white, size: 14),
              ),
            ),
          ),
          if (index == 0)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
                ),
                child: Text(
                  'Utama',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAddImageButton() {
    return GestureDetector(
      onTap: _pickAndCropImage,
      child: Container(
        width: 100,
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
        ),
        child: const Icon(Icons.add_a_photo_outlined, color: Colors.grey, size: 30),
      ),
    );
  }

  Widget _buildDimensionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Berat (Gram)'),
        TextFormField(
          initialValue: _weight > 0 ? _weight.toInt().toString() : '',
          keyboardType: TextInputType.number,
          decoration: _inputDecoration('Contoh: 500'),
          onSaved: (v) => _weight = double.tryParse(v ?? '0') ?? 0,
        ),
        const SizedBox(height: 16),
        _buildLabel('Dimensi (Optional - CM)'),
        Row(
          children: [
            Expanded(child: _buildSmallTextField('P', _length, (v) => _length = int.tryParse(v ?? '0') ?? 0)),
            const SizedBox(width: 8),
            Expanded(child: _buildSmallTextField('L', _width, (v) => _width = int.tryParse(v ?? '0') ?? 0)),
            const SizedBox(width: 8),
            Expanded(child: _buildSmallTextField('T', _height, (v) => _height = int.tryParse(v ?? '0') ?? 0)),
          ],
        ),
      ],
    );
  }

  Widget _buildSmallTextField(String hint, int initialValue, Function(String?) onSaved) {
    return TextFormField(
      initialValue: initialValue > 0 ? initialValue.toString() : '',
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      decoration: _inputDecoration(hint).copyWith(
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      ),
      onSaved: onSaved,
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text,
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[400]),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      filled: true,
      fillColor: const Color(0xFFF8F9FA),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.orange, width: 2),
      ),
    );
  }
}
