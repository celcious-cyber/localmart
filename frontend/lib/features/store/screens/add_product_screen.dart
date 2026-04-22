import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/utils/app_alert.dart';
import 'package:image_cropper/image_cropper.dart';
import '../../../core/services/api_service.dart';
import '../../../shared/models/home_data.dart';
import '../../../shared/models/store_models.dart';
import '../../../shared/models/module_spec_model.dart';
import '../../../core/theme/app_colors.dart';
import 'package:get/get.dart';
import '../controllers/add_product_controller.dart';

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
  final AddProductController _prodController = Get.put(
    AddProductController(),
    permanent: true,
  );

  late String _productType;
  String _serviceType = 'mart';
  bool _isFetchingCategories = false;
  List<String> _storeModules = [];
  List<Map<String, String>> _allModules = [];

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
  
  // Dynamic Form State
  List<ModuleSpecModel> _moduleSpecs = [];
  final Map<String, TextEditingController> _dynamicControllers = {};
  final Map<String, dynamic> _dynamicValues = {};
  bool _isFetchingSpecs = false;

  final _picker = ImagePicker();
  String _condition = 'Baru';
  CategoryModel? _selectedCategory;

  final List<XFile> _selectedFiles = [];
  final Map<String, Uint8List> _imageBytesCache = {};
  List<String> _existingUrls = [];
  List<CategoryModel> _categories = [];
  List<ProductVariantModel> _variants = [];

  // Store Categories (Etalase) Logic
  List<StoreCategoryModel> _selectedStoreCategories = [];
  List<StoreCategoryModel> _storeCategories = [];

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isModuleSelected = false;

  @override
  void initState() {
    super.initState();

    // Check if we are editing or continuing from previous state
    if (widget.product != null) {
      _prodController.setFromProduct(widget.product!);
    }

    _productType = widget.initialType ?? _prodController.productType.value;
    _serviceType = _prodController.serviceType.value;

    // Sync UI controllers with GetX state
    _nameController.text = _prodController.name.value;
    _priceController.text = _prodController.price.value;
    _descriptionController.text = _prodController.description.value;
    _selectedCategory = _prodController.selectedCategory.value;
    _selectedStoreCategories = List.from(
      _prodController.selectedStoreCategories,
    );

    // Listeners for persistence
    _nameController.addListener(
      () => _prodController.name.value = _nameController.text,
    );
    _priceController.addListener(
      () => _prodController.price.value = _priceController.text,
    );
    _descriptionController.addListener(
      () => _prodController.description.value = _descriptionController.text,
    );

    // If we're coming from a specific screen (e.g. LocalFood), we might want to pre-select serviceType
    // This will be handled by the caller or inferred from type if needed.
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
          _fasilitasController.text = meta['fasilitas'] is List
              ? (meta['fasilitas'] as List).join(', ')
              : '';
        } catch (_) {}
      }
    }
    _fetchData();
  }

  Future<void> _fetchModuleSpecs() async {
    setState(() => _isFetchingSpecs = true);
    try {
      final specs = await _api.getModuleSpecifications(_serviceType);
      
      // Initialize controllers/values for new specs
      for (var spec in specs) {
        if (!_dynamicControllers.containsKey(spec.key)) {
          if (spec.inputType == 'boolean') {
            _dynamicValues[spec.key] = false;
          } else if (spec.inputType == 'select') {
            _dynamicValues[spec.key] = spec.optionsList.isNotEmpty ? spec.optionsList.first : '';
          } else {
            _dynamicControllers[spec.key] = TextEditingController();
          }
        }
      }

      // If editing, fill with existing metadata
      if (widget.product != null) {
        try {
          final Map<String, dynamic> meta = jsonDecode(widget.product!.metadata);
          meta.forEach((key, value) {
            if (_dynamicControllers.containsKey(key)) {
              _dynamicControllers[key]!.text = value.toString();
            } else {
              _dynamicValues[key] = value;
            }
          });
        } catch (_) {}
      }

      setState(() {
        _moduleSpecs = specs;
        _isFetchingSpecs = false;
      });
    } catch (e) {
      setState(() => _isFetchingSpecs = false);
    }
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);

    // Fetch store modules from dashboard
    final dashboard = await _api.getStoreDashboard();
    if (dashboard != null) {
      _storeModules = dashboard.store.businessModules;
      
      // Filter modules based on initialType if provided
      List<String> filteredStoreModules = _storeModules;
      if (widget.initialType != null && widget.product == null) {
        filteredStoreModules = _storeModules.where((mCode) {
          if (widget.initialType == 'BARANG') {
            return ['mart', 'food', 'umkm', 'bumi', 'second'].contains(mCode);
          } else if (widget.initialType == 'JASA') {
            return ['jasa', 'transport'].contains(mCode);
          } else if (widget.initialType == 'RENTAL') {
            return ['rental', 'kost'].contains(mCode);
          } else if (widget.initialType == 'WISATA') {
            return ['wisata'].contains(mCode);
          } else if (widget.initialType == 'LAYANAN') {
            return ['jasa', 'transport', 'rental', 'kost', 'wisata'].contains(mCode);
          }
          return true;
        }).toList();
      }

      // Auto-set serviceType if only one module matches and it's a new product
      if (widget.product != null) {
        _isModuleSelected = true;
        _serviceType = widget.product!.serviceType;
      } else if (filteredStoreModules.length == 1) {
        _serviceType = filteredStoreModules.first;
        _isModuleSelected = true;
      } else if (filteredStoreModules.isEmpty && _storeModules.isNotEmpty) {
         // Fallback if no match but store has modules
         // (Keep _isModuleSelected false to show choice)
      }
      
      if (_isModuleSelected) {
        _fetchModuleSpecs(); // Initial fetch
      }
    }

    // Fetch all module constants for labels
    final modules = await _api.getStoreConstants();
    _allModules = modules;

    // Fetch store categories (etalase)
    final storeCats = await _api.getStoreCategories();
    _storeCategories = storeCats;

    // Fetch module categories
    final cats = await _api.getCategories(serviceType: _serviceType);

    if (mounted) {
      setState(() {
        _categories = cats;
        if (widget.product != null) {
          _selectedCategory = _categories.firstWhere(
            (c) => c.id == widget.product!.categoryId,
            orElse: () => _categories.isNotEmpty
                ? _categories.first
                : CategoryModel(
                    id: 0,
                    name: 'Pilih Kategori',
                    slug: '',
                    iconName: '',
                    type: 'BARANG',
                    serviceType: 'mart',
                    sortOrder: 0,
                    isActive: true,
                    products: [],
                  ),
          );

          if (widget.product!.storeCategories.isNotEmpty) {
            _selectedStoreCategories = List.from(
              widget.product!.storeCategories,
            );
          }
        } else if (_categories.isNotEmpty) {
          _selectedCategory = null;
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _onServiceTypeChanged(String? val) async {
    if (val == null || val == _serviceType) return;

    setState(() {
      _serviceType = val;
      _prodController.serviceType.value = val;
      _isFetchingCategories = true;
      _selectedCategory = null;
      _prodController.selectedCategory.value = null;

      // Auto-map productType to show correct fields
      if (['mart', 'food', 'umkm', 'bumi', 'second'].contains(val)) {
        _productType = 'BARANG';
      } else if (['jasa', 'transport'].contains(val)) {
        _productType = 'JASA';
      } else if (['rental', 'kost'].contains(val)) {
        _productType = 'RENTAL';
      } else if (['wisata'].contains(val)) {
        _productType = 'WISATA';
      }
      _prodController.productType.value = _productType;
      _fetchModuleSpecs(); // Re-fetch specs for new service
    });

    try {
      final cats = await _api.getCategories(serviceType: val);
      if (mounted) {
        setState(() {
          _categories = cats;
          _isFetchingCategories = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isFetchingCategories = false);
        AppAlert.error('Gagal', 'Gagal memuat kategori untuk modul ini');
      }
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

  void _confirmReset() {
    AppAlert.confirm(
      Get.context!,
      'Reset Form?',
      'Semua data yang sudah Anda isi akan dihapus dan kembali kosong.',
      confirmText: 'Ya, Reset',
      onConfirm: () {
        _prodController.clear();
        setState(() {
          _nameController.clear();
          _priceController.clear();
          _descriptionController.clear();
          _stockController.text = '0';
          _brandController.clear();
          _skuController.clear();
          _minOrderController.text = '1';
          _weightController.text = '0';
          _lengthController.text = '0';
          _widthController.text = '0';
          _heightController.text = '0';
          _condition = 'Baru';
          _selectedCategory = null;
          _selectedFiles.clear();
          _imageBytesCache.clear();
          _variants.clear();
          _selectedStoreCategories.clear();
        });
      },
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_existingUrls.isEmpty && _selectedFiles.isEmpty) {
      AppAlert.info(
        'Foto Produk',
        'Unggah minimal 1 foto produk agar pembeli tertarik',
      );
      return;
    }
    if (_selectedCategory == null) return;

    setState(() => _isSaving = true);

    try {
      // 1. Metadata construction
      final Map<String, dynamic> meta = {};
      
      // Collect Dynamic Metadata
      for (var spec in _moduleSpecs) {
        if (spec.inputType == 'boolean' || spec.inputType == 'select') {
          meta[spec.key] = _dynamicValues[spec.key];
        } else {
          meta[spec.key] = _dynamicControllers[spec.key]?.text ?? '';
        }
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
        'service_type': _serviceType,
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

      if (_selectedStoreCategories.isNotEmpty) {
        productData['store_category_ids'] = _selectedStoreCategories
            .map((sc) => sc.id.toString())
            .toList();
      } else {
        productData['store_category_ids'] = []; // For backend to clear
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
        result = await _api.updateStoreProductMulti(
          widget.product!.id,
          productData,
          newImageBytes,
        );
      }

      if (mounted) {
        // Close loading
        Navigator.pop(context);

        if (result['success']) {
          AppAlert.success(
            widget.product == null ? 'Produk Ditambahkan' : 'Produk Diperbarui',
            result['message'],
          );

          // RESET LOGIC: Clear controller state only on success
          _prodController.clear();

          Navigator.pop(context, true);
        } else {
          AppAlert.error(
            'Gagal',
            result['message'] ?? 'Terjadi kesalahan saat menyimpan produk',
          );
        }
      }
    } catch (e) {
      if (mounted) AppAlert.error('Terjadi Kesalahan', e.toString());
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.orange)),
      );
    }

    if (!_isModuleSelected) {
      return _buildModuleSelection();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.product != null
              ? 'Edit ${_getTypeLabel()}'
              : 'Tambah ${_getTypeLabel()}',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          if (widget.product == null)
            TextButton(
              onPressed: _confirmReset,
              child: Text(
                'Reset',
                style: GoogleFonts.poppins(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
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

                    _buildLabel(
                      'Modul / Layanan (Terkunci jika hanya memiliki 1 modul)',
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: _serviceType,
                      isExpanded: true,
                      decoration: _inputDecoration('Pilih Modul'),
                      items: _allModules
                          .where((m) => _storeModules.contains(m['code']))
                          .map(
                            (m) => DropdownMenuItem(
                              value: m['code'],
                              child: Text(
                                m['name']!,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      // Tampilkan semua jika data modulenya belum termuat (fallback)
                      onChanged: _storeModules.length <= 1
                          ? null
                          : _onServiceTypeChanged,
                      validator: (v) => v == null ? 'Wajib dipilih' : null,
                    ),
                    const SizedBox(height: 20),

                    _buildLabel('Kategori'),
                    DropdownButtonFormField<CategoryModel>(
                      initialValue: _selectedCategory,
                      isExpanded: true,
                      decoration: _inputDecoration(
                        _isFetchingCategories
                            ? 'Memuat kategori...'
                            : 'Pilih kategori',
                      ),
                      items: _categories
                          .map(
                            (c) => DropdownMenuItem(
                              value: c,
                              child: Text(
                                c.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: _isFetchingCategories
                          ? null
                          : (v) {
                              setState(() => _selectedCategory = v);
                              _prodController.selectedCategory.value = v;
                            },
                      validator: (v) => v == null ? 'Wajib dipilih' : null,
                      hint: _isFetchingCategories
                          ? const SizedBox(
                              height: 12,
                              width: 12,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Pilih kategori'),
                    ),
                    const SizedBox(height: 20),

                    _buildLabel('Pilih Etalase Toko (Bisa lebih dari satu)'),
                    const SizedBox(height: 8),
                    if (_storeCategories.isEmpty)
                      Text(
                        'Anda belum membuat etalase khusus.',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _storeCategories.map((sc) {
                          final isSelected = _selectedStoreCategories.any(
                            (s) => s.id == sc.id,
                          );
                          return FilterChip(
                            label: Text(
                              sc.name,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedStoreCategories.add(sc);
                                  _prodController.selectedStoreCategories.add(
                                    sc,
                                  );
                                } else {
                                  _selectedStoreCategories.removeWhere(
                                    (s) => s.id == sc.id,
                                  );
                                  _prodController.selectedStoreCategories
                                      .removeWhere((s) => s.id == sc.id);
                                }
                              });
                            },
                            backgroundColor: Colors.grey[100],
                            selectedColor: AppColors.primary,
                            checkmarkColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 20),

                    if (_productType == 'BARANG') ...[
                      ..._buildGoodsFields(),
                      const SizedBox(height: 32),
                      _buildVariantSection(),
                    ] else ...[
                      _buildDynamicFields(),
                    ],

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
                                validator: (v) => v == null || v.isEmpty
                                    ? 'Wajib diisi'
                                    : null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel(
                                _productType == 'BARANG' ? 'Stok' : 'Kuota',
                              ),
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
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 48),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isSaving
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : Text(
                                'Simpan ${_getTypeLabel()}',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
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
      TextFormField(
        controller: _brandController,
        decoration: _inputDecoration('Contoh: Indomie'),
      ),
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
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: _getConditionOptions()
                        .map(
                          (opt) => Expanded(child: _buildConditionButton(opt)),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel('SKU'),
                TextFormField(
                  controller: _skuController,
                  decoration: _inputDecoration('Kode'),
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 20),
      _buildLabel('Berat (Gram)'),
      TextFormField(
        controller: _weightController,
        keyboardType: TextInputType.number,
        decoration: _inputDecoration('0'),
      ),
    ];
  }

  Widget _buildDynamicFields() {
    if (_isFetchingSpecs) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_moduleSpecs.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _moduleSpecs.map((spec) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel(spec.label + (spec.isRequired ? ' *' : '')),
              _buildFieldWidget(spec),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFieldWidget(ModuleSpecModel spec) {
    switch (spec.inputType) {
      case 'boolean':
        return SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(spec.label, style: GoogleFonts.poppins(fontSize: 13)),
          value: _dynamicValues[spec.key] ?? false,
          activeThumbColor: AppColors.primary,
          onChanged: (val) => setState(() => _dynamicValues[spec.key] = val),
        );
      case 'select':
        return DropdownButtonFormField<String>(
          initialValue: _dynamicValues[spec.key],
          isExpanded: true,
          decoration: _inputDecoration('Pilih ${spec.label}'),
          items: spec.optionsList
              .map((opt) => DropdownMenuItem(value: opt, child: Text(opt)))
              .toList(),
          onChanged: (val) => setState(() => _dynamicValues[spec.key] = val),
          validator: (v) =>
              spec.isRequired && (v == null || v.isEmpty) ? 'Wajib dipilih' : null,
        );
      case 'number':
        return TextFormField(
          controller: _dynamicControllers[spec.key],
          keyboardType: TextInputType.number,
          decoration: _inputDecoration(spec.label),
          validator: (v) =>
              spec.isRequired && (v == null || v.isEmpty) ? 'Wajib diisi' : null,
        );
      default:
        return TextFormField(
          controller: _dynamicControllers[spec.key],
          decoration: _inputDecoration(spec.label),
          validator: (v) =>
              spec.isRequired && (v == null || v.isEmpty) ? 'Wajib diisi' : null,
        );
    }
  }

  Widget _buildLabel(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      t,
      style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
    ),
  );
  InputDecoration _inputDecoration(String h) => InputDecoration(
    hintText: h,
    filled: true,
    fillColor: const Color(0xFFF8F9FA),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
  );

  String _getTypeLabel() => _productType == 'BARANG'
      ? 'Barang'
      : _productType == 'JASA'
      ? 'Jasa'
      : _productType == 'RENTAL'
      ? 'Sewa'
      : 'Wisata';

  Widget _buildConditionButton(String label) {
    bool isSelected = _condition == label;
    return GestureDetector(
      onTap: () => setState(() => _condition = label),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(4),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  String _getConditionLabel() {
    if (_selectedCategory?.name == 'Hasil Bumi') return 'Status Panen';
    if (_selectedCategory?.name == 'Pangan Lokal') return 'Kesegaran';
    return 'Kondisi';
  }

  List<String> _getConditionOptions() {
    if (_selectedCategory?.name == 'Hasil Bumi') {
      return ['Panen Baru', 'Kering', 'Bibit'];
    }
    if (_selectedCategory?.name == 'Pangan Lokal') {
      return ['Siap Saji', 'Frozen', 'Kering'];
    }
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
              ..._existingUrls.asMap().entries.map(
                (e) => _buildImageItem(e.value, () => _removeImage(e.key)),
              ),
              ..._selectedFiles.asMap().entries.map(
                (e) => _buildImageItem(
                  e.value.path,
                  () => _removeImage(e.key, isLocal: true),
                  isLocal: true,
                ),
              ),
              if (_existingUrls.length + _selectedFiles.length < 5)
                _buildAddImageButton(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageItem(
    String url,
    VoidCallback onRemove, {
    bool isLocal = false,
  }) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[100],
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: isLocal
                ? Image.memory(
                    _imageBytesCache[url]!,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  )
                : Image.network(
                    _api.getImageUrl(url),
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
          ),
          Positioned(
            right: 4,
            top: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddImageButton() {
    return GestureDetector(
      onTap: () async {
        try {
          final f = await _picker.pickImage(source: ImageSource.gallery);
          if (f != null) {
            CroppedFile? cropped;
            
            // Ensure context is still valid
            if (!mounted) return;

            // On Web, image_cropper might need extra config or fail. 
            // We wrap it to ensure we still get the image.
            try {
              cropped = await ImageCropper().cropImage(
                sourcePath: f.path,
                aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
                uiSettings: [
                  AndroidUiSettings(
                    toolbarTitle: 'Potong Foto',
                    toolbarColor: AppColors.primary,
                    toolbarWidgetColor: Colors.white,
                    initAspectRatio: CropAspectRatioPreset.square,
                    lockAspectRatio: true,
                  ),
                  IOSUiSettings(title: 'Potong Foto'),
                  WebUiSettings(
                    context: context,
                    presentStyle: WebPresentStyle.dialog,
                    size: const CropperSize(width: 400, height: 400),
                  ),
                ],
              );
            } catch (e) {
              debugPrint('Image cropping error: $e');
            }

            Uint8List bytes;
            String path;

            if (cropped != null) {
              bytes = await cropped.readAsBytes();
              path = cropped.path;
            } else {
              bytes = await f.readAsBytes();
              path = f.path;
            }

            if (!mounted) return;
            
            setState(() {
              _selectedFiles.add(XFile(path));
              _imageBytesCache[path] = bytes;
            });
          }
        } catch (e) {
          debugPrint('Image picking error: $e');
          AppAlert.error('Gagal', 'Gagal memilih foto: $e');
        }
      },
      child: Container(
        width: 100,
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: const Icon(Icons.add_a_photo_outlined, color: Colors.grey),
      ),
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
              icon: const Icon(
                Icons.add_circle_outline,
                size: 18,
                color: AppColors.primary,
              ),
              label: Text(
                'Tambah Varian',
                style: GoogleFonts.poppins(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        if (_variants.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 18, color: Colors.grey),
                const SizedBox(width: 12),
                Text(
                  'Opsional: Ukuran/Kemasan berbeda',
                  style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        v.name,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Text(
                      'Rp ${v.price.toInt()}',
                      style: GoogleFonts.poppins(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () =>
                          setState(() => _variants.removeAt(index)),
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                    ),
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
        title: Text(
          'Tambah Varian',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: _inputDecoration('Nama (Contoh: XL / 500gr)'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              decoration: _inputDecoration('Harga Varian'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: stockCtrl,
              keyboardType: TextInputType.number,
              decoration: _inputDecoration('Stok Varian'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty && priceCtrl.text.isNotEmpty) {
                setState(() {
                  _variants.add(
                    ProductVariantModel(
                      id: 0,
                      productId: widget.product?.id ?? 0,
                      name: nameCtrl.text,
                      price: double.tryParse(priceCtrl.text) ?? 0.0,
                      stock: int.tryParse(stockCtrl.text) ?? 0,
                    ),
                  );
                });
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Simpan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleSelection() {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Pilih Modul Produk',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Apa yang ingin Anda jual hari ini?',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pilih kategori modul yang sesuai agar pembeli mudah menemukan produk Anda.',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
              ),
              itemCount: _allModules.where((m) {
                final mCode = m['code']!;
                if (!_storeModules.contains(mCode)) return false;
                if (widget.initialType == null) return true;
                
                if (widget.initialType == 'BARANG') {
                  return ['mart', 'food', 'umkm', 'bumi', 'second'].contains(mCode);
                } else if (widget.initialType == 'JASA') {
                  return ['jasa', 'transport'].contains(mCode);
                } else if (widget.initialType == 'RENTAL') {
                  return ['rental', 'kost'].contains(mCode);
                } else if (widget.initialType == 'WISATA') {
                  return ['wisata'].contains(mCode);
                } else if (widget.initialType == 'LAYANAN') {
                  return ['jasa', 'transport', 'rental', 'kost', 'wisata'].contains(mCode);
                }
                return true;
              }).length,
              itemBuilder: (context, index) {
                final filteredModules = _allModules.where((m) {
                  final mCode = m['code']!;
                  if (!_storeModules.contains(mCode)) return false;
                  if (widget.initialType == null) return true;
                  
                  if (widget.initialType == 'BARANG') {
                    return ['mart', 'food', 'umkm', 'bumi', 'second'].contains(mCode);
                  } else if (widget.initialType == 'JASA') {
                    return ['jasa', 'transport'].contains(mCode);
                  } else if (widget.initialType == 'RENTAL') {
                    return ['rental', 'kost'].contains(mCode);
                  } else if (widget.initialType == 'WISATA') {
                    return ['wisata'].contains(mCode);
                  }
                  return true;
                }).toList();

                final m = filteredModules[index];
                final code = m['code']!;
                final name = m['name']!;

                final Map<String, IconData> moduleIcons = {
                  'mart': Icons.shopping_bag,
                  'food': Icons.restaurant,
                  'kost': Icons.home,
                  'rental': Icons.directions_car,
                  'transport': Icons.local_taxi,
                  'jasa': Icons.build,
                  'umkm': Icons.storefront,
                  'bumi': Icons.agriculture,
                  'wisata': Icons.map,
                  'second': Icons.recycling,
                };

                final Map<String, Color> moduleColors = {
                  'mart': Colors.blue,
                  'food': Colors.red,
                  'kost': Colors.orange,
                  'rental': Colors.purple,
                  'transport': Colors.teal,
                  'jasa': Colors.brown,
                  'umkm': Colors.pink,
                  'bumi': Colors.green,
                  'wisata': Colors.indigo,
                  'second': Colors.grey,
                };

                return InkWell(
                  onTap: () => _onServiceTypeChanged(code).then((_) {
                    setState(() => _isModuleSelected = true);
                  }),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: (moduleColors[code] ?? Colors.grey)
                                .withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            moduleIcons[code] ?? Icons.category,
                            color: moduleColors[code] ?? Colors.grey,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            name,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
