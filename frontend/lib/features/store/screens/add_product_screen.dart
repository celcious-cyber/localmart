import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../../../core/services/api_service.dart';
import '../../../shared/models/home_data.dart';
import '../../../core/theme/app_colors.dart';

class AddProductScreen extends StatefulWidget {
  final ProductModel? product;
  final String? initialType; // BARANG, JASA, RENTAL, WISATA

  const AddProductScreen({super.key, this.product, this.initialType});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _api = ApiService();
  late String _productType;
  
  // Controllers
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _stockController = TextEditingController(text: '0');
  final _brandController = TextEditingController();
  final _skuController = TextEditingController();
  final _minOrderController = TextEditingController(text: '1');
  final _weightController = TextEditingController(text: '0');
  final _lengthController = TextEditingController(text: '0');
  final _widthController = TextEditingController(text: '0');
  final _heightController = TextEditingController(text: '0');

  // Metadata Controllers
  final _areaLayananController = TextEditingController();
  final _jamOperasionalController = TextEditingController();
  final _fasilitasController = TextEditingController();
  final _meetingPointController = TextEditingController();
  final _depositController = TextEditingController();
  final _durasiSewaController = TextEditingController();

  final _picker = ImagePicker();
  String _condition = 'Baru';
  CategoryModel? _selectedCategory;
  
  final List<XFile> _selectedFiles = [];
  final Map<String, Uint8List> _imageBytesCache = {};
  List<String> _existingUrls = [];
  List<CategoryModel> _categories = [];
  List<ProductVariantModel> _variants = [];
  
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _productType = widget.initialType ?? widget.product?.productType ?? 'BARANG';
    
    if (widget.product != null) {
      final p = widget.product!;
      _nameController.text = p.name;
      _priceController.text = p.price.toInt().toString();
      _descriptionController.text = p.description;
      _stockController.text = p.stock.toString();
      _brandController.text = p.brand;
      _skuController.text = p.sku;
      _minOrderController.text = p.minOrder.toString();
      _weightController.text = p.weight.toInt().toString();
      _lengthController.text = p.length.toString();
      _widthController.text = p.width.toString();
      _heightController.text = p.height.toString();
      _condition = p.condition;
      _existingUrls = p.images.map((i) => i.imageUrl).toList();
      _variants = List.from(p.variants);

      // Parse Metadata
      if (p.metadata.isNotEmpty && p.metadata != '{}') {
        try {
          final Map<String, dynamic> meta = jsonDecode(p.metadata);
          _areaLayananController.text = meta['area_layanan'] ?? '';
          _jamOperasionalController.text = meta['jam_operasional'] ?? '';
          _durasiSewaController.text = meta['durasi_sewa'] ?? '';
          _depositController.text = meta['uang_jaminan']?.toString() ?? '';
          _meetingPointController.text = meta['meeting_point'] ?? '';
          _fasilitasController.text = meta['fasilitas'] is List ? (meta['fasilitas'] as List).join(', ') : '';
        } catch (_) {}
      }
    }
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final cats = await _api.getCategories(type: _productType);
    if (mounted) {
      setState(() {
        _categories = cats;
        if (widget.product != null) {
          _selectedCategory = _categories.firstWhere(
            (c) => c.id == widget.product!.categoryId, 
            orElse: () => _categories.isNotEmpty ? _categories.first : CategoryModel(id: 0, name: 'Pilih Kategori', slug: '', iconName: '', type: 'BARANG', sortOrder: 0, isActive: true, products: [])
          );
        } else if (_categories.isNotEmpty) {
           _selectedCategory = null; // Clear if adding new to prevent wrong cat
        }
        _isLoading = false;
      });
    }
  }

  void _removeImage(int index, {bool isLocal = false}) {
    setState(() {
      if (isLocal) {
        final f = _selectedFiles.removeAt(index);
        _imageBytesCache.remove(f.path);
      } else {
        _existingUrls.removeAt(index);
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_existingUrls.isEmpty && _selectedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unggah minimal 1 foto')));
      return;
    }
    if (_selectedCategory == null) return;

    setState(() => _isSaving = true);

    try {
      // 1. Metadata construction
      final Map<String, dynamic> meta = {};
      if (_productType == 'JASA') {
        meta['area_layanan'] = _areaLayananController.text;
        meta['jam_operasional'] = _jamOperasionalController.text;
      } else if (_productType == 'RENTAL') {
        meta['durasi_sewa'] = _durasiSewaController.text;
        meta['uang_jaminan'] = double.tryParse(_depositController.text) ?? 0;
      } else if (_productType == 'WISATA') {
        meta['meeting_point'] = _meetingPointController.text;
        meta['fasilitas'] = _fasilitasController.text.split(',').map((e) => e.trim()).toList();
      }

      // 2. Prepare Data
      final Map<String, dynamic> productData = {
        'category_id': _selectedCategory!.id.toString(),
        'name': _nameController.text,
        'description': _descriptionController.text,
        'price': _priceController.text,
        'stock': _stockController.text,
        'condition': _condition,
        'brand': _brandController.text,
        'sku': _skuController.text,
        'min_order': _minOrderController.text,
        'product_type': _productType,
        'metadata': jsonEncode(meta),
        'variants': jsonEncode(_variants),
        'existing_images': jsonEncode(_existingUrls),
      };

      if (_productType == 'BARANG') {
        productData['weight'] = _weightController.text;
        productData['length'] = _lengthController.text;
        productData['width'] = _widthController.text;
        productData['height'] = _heightController.text;
      }

      // 3. Image Upload
      List<Uint8List> newImageBytes = [];
      for (var f in _selectedFiles) {
        final bytes = _imageBytesCache[f.path];
        if (bytes != null) newImageBytes.add(bytes);
      }

      final dynamic result;
      if (widget.product == null) {
        result = await _api.createStoreProductMulti(productData, newImageBytes);
      } else {
        result = await _api.updateStoreProductMulti(widget.product!.id, productData, newImageBytes);
      }

      if (mounted) {
        if (result['success']) {
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? 'Gagal menyimpan')));
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.product != null ? 'Edit ${_getTypeLabel()}' : 'Tambah ${_getTypeLabel()}',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: _isLoading 
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
                  
                  _buildLabel('Nama ${_getTypeLabel()}'),
                  TextFormField(
                    controller: _nameController,
                    decoration: _inputDecoration('Contoh: ${_getNameExample()}'),
                    validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 20),
                  
                  _buildLabel('Kategori'),
                  DropdownButtonFormField<CategoryModel>(
                    initialValue: _selectedCategory,
                    decoration: _inputDecoration('Pilih kategori'),
                    items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
                    onChanged: (v) => setState(() => _selectedCategory = v),
                    validator: (v) => v == null ? 'Wajib dipilih' : null,
                  ),
                  const SizedBox(height: 20),

                  if (_productType == 'BARANG') ...[
                    ..._buildGoodsFields(),
                    const SizedBox(height: 32),
                    _buildVariantSection(),
                  ],
                  if (_productType == 'JASA') ..._buildServiceFields(),
                  if (_productType == 'RENTAL') ..._buildRentalFields(),
                  if (_productType == 'WISATA') ..._buildTourismFields(),

                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Harga (Rp)'),
                            TextFormField(
                              controller: _priceController,
                              keyboardType: TextInputType.number,
                              decoration: _inputDecoration('0'),
                              validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel(_productType == 'BARANG' ? 'Stok' : 'Kuota'),
                            TextFormField(
                              controller: _stockController,
                              keyboardType: TextInputType.number,
                              decoration: _inputDecoration('0'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  _buildLabel('Deskripsi'),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: _inputDecoration('Detail spesifikasi...'),
                    validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 48),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text('Simpan ${_getTypeLabel()}', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  List<Widget> _buildGoodsFields() {
    return [
      _buildLabel('Merek'),
      TextFormField(controller: _brandController, decoration: _inputDecoration('Contoh: Indomie')),
      const SizedBox(height: 20),
      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel(_getConditionLabel()),
                Container(
                  height: 56,
                  decoration: BoxDecoration(color: const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[200]!)),
                  child: Row(
                    children: _getConditionOptions().map((opt) => Expanded(child: _buildConditionButton(opt))).toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildLabel('SKU'), TextFormField(controller: _skuController, decoration: _inputDecoration('Kode'))])),
        ],
      ),
      const SizedBox(height: 20),
      _buildLabel('Berat (Gram)'),
      TextFormField(controller: _weightController, keyboardType: TextInputType.number, decoration: _inputDecoration('0')),
    ];
  }

  List<Widget> _buildServiceFields() {
    return [
      _buildLabel('Area Layanan'),
      TextFormField(controller: _areaLayananController, decoration: _inputDecoration('Contoh: Taliwang')),
      const SizedBox(height: 20),
      _buildLabel('Jam Operasional'),
      TextFormField(controller: _jamOperasionalController, decoration: _inputDecoration('08:00 - 17:00')),
    ];
  }

  List<Widget> _buildRentalFields() {
    return [
      _buildLabel('Durasi Sewa'),
      TextFormField(controller: _durasiSewaController, decoration: _inputDecoration('Per Hari / Per Jam')),
      const SizedBox(height: 20),
      _buildLabel('Uang Jaminan (Deposit)'),
      TextFormField(controller: _depositController, keyboardType: TextInputType.number, decoration: _inputDecoration('0')),
    ];
  }

  List<Widget> _buildTourismFields() {
    return [
      _buildLabel('Titik Kumpul'),
      TextFormField(controller: _meetingPointController, decoration: _inputDecoration('Lokasi pertemuan')),
      const SizedBox(height: 20),
      _buildLabel('Fasilitas (Koma)'),
      TextFormField(controller: _fasilitasController, decoration: _inputDecoration('Guide, Makan, dll')),
    ];
  }

  Widget _buildLabel(String t) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(t, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)));
  InputDecoration _inputDecoration(String h) => InputDecoration(hintText: h, filled: true, fillColor: const Color(0xFFF8F9FA), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none));
  
  String _getTypeLabel() => _productType == 'BARANG' ? 'Barang' : _productType == 'JASA' ? 'Jasa' : _productType == 'RENTAL' ? 'Sewa' : 'Wisata';
  String _getNameExample() => _productType == 'BARANG' ? 'Kopi Tepal' : _productType == 'JASA' ? 'Service AC' : _productType == 'RENTAL' ? 'Rental Mobil' : 'Paket Tour';

  Widget _buildConditionButton(String label) {
    bool isSelected = _condition == label;
    return GestureDetector(
      onTap: () => setState(() => _condition = label),
      child: Container(
        decoration: BoxDecoration(color: isSelected ? AppColors.primary : Colors.transparent, borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(4),
        alignment: Alignment.center,
        child: Text(label, style: GoogleFonts.poppins(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Colors.white : Colors.grey[600])),
      ),
    );
  }

  String _getConditionLabel() {
    if (_selectedCategory?.name == 'Hasil Bumi') return 'Status Panen';
    if (_selectedCategory?.name == 'Pangan Lokal') return 'Kesegaran';
    return 'Kondisi';
  }

  List<String> _getConditionOptions() {
    if (_selectedCategory?.name == 'Hasil Bumi') return ['Panen Baru', 'Kering', 'Bibit'];
    if (_selectedCategory?.name == 'Pangan Lokal') return ['Siap Saji', 'Frozen', 'Kering'];
    return ['Baru', 'Bekas'];
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Foto (Maks 5)'),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              ..._existingUrls.asMap().entries.map((e) => _buildImageItem(e.value, () => _removeImage(e.key))),
              ..._selectedFiles.asMap().entries.map((e) => _buildImageItem(e.value.path, () => _removeImage(e.key, isLocal: true), isLocal: true)),
              if (_existingUrls.length + _selectedFiles.length < 5) _buildAddImageButton(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageItem(String url, VoidCallback onRemove, {bool isLocal = false}) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.grey[100]),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: isLocal ? Image.memory(_imageBytesCache[url]!, width: 100, height: 100, fit: BoxFit.cover) : Image.network(_api.getImageUrl(url), width: 100, height: 100, fit: BoxFit.cover),
          ),
          Positioned(right: 4, top: 4, child: GestureDetector(onTap: onRemove, child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), child: const Icon(Icons.close, color: Colors.white, size: 14)))),
        ],
      ),
    );
  }

  Widget _buildAddImageButton() {
    return GestureDetector(
      onTap: () async {
        final f = await _picker.pickImage(source: ImageSource.gallery);
        if (f != null) {
          final cropped = await ImageCropper().cropImage(sourcePath: f.path, aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1));
          if (cropped != null) {
            final bytes = await cropped.readAsBytes();
            setState(() {
              _selectedFiles.add(XFile(cropped.path));
              _imageBytesCache[cropped.path] = bytes;
            });
          }
        }
      },
      child: Container(width: 100, decoration: BoxDecoration(color: const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[300]!)), child: const Icon(Icons.add_a_photo_outlined, color: Colors.grey)),
    );
  }

  Widget _buildVariantSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildLabel('Varian Produk'),
            TextButton.icon(
              onPressed: _showAddVariantDialog,
              icon: const Icon(Icons.add_circle_outline, size: 18, color: AppColors.primary),
              label: Text('Tambah Varian', style: GoogleFonts.poppins(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ],
        ),
        if (_variants.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[200]!)),
            child: Row(children: [const Icon(Icons.info_outline, size: 18, color: Colors.grey), const SizedBox(width: 12), Text('Opsional: Ukuran/Kemasan berbeda', style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12))]),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _variants.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final v = _variants[index];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[200]!)),
                child: Row(
                  children: [
                    Expanded(child: Text(v.name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14))),
                    Text('Rp ${v.price.toInt()}', style: GoogleFonts.poppins(color: AppColors.primary, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    IconButton(onPressed: () => setState(() => _variants.removeAt(index)), icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20)),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  void _showAddVariantDialog() {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final stockCtrl = TextEditingController(text: '0');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Tambah Varian', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: _inputDecoration('Nama (Contoh: XL / 500gr)')),
            const SizedBox(height: 16),
            TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: _inputDecoration('Harga Varian')),
            const SizedBox(height: 16),
            TextField(controller: stockCtrl, keyboardType: TextInputType.number, decoration: _inputDecoration('Stok Varian')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty && priceCtrl.text.isNotEmpty) {
                setState(() {
                  _variants.add(ProductVariantModel(
                    id: 0,
                    productId: widget.product?.id ?? 0,
                    name: nameCtrl.text,
                    price: double.tryParse(priceCtrl.text) ?? 0.0,
                    stock: int.tryParse(stockCtrl.text) ?? 0,
                  ));
                });
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Simpan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
