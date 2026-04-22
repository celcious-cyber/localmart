class ModuleSpecModel {
  final int id;
  final String moduleCode;
  final String label;
  final String key;
  final String inputType; // text, number, select, boolean
  final String options; // Comma separated for select
  final bool isRequired;
  final int sortOrder;

  ModuleSpecModel({
    required this.id,
    required this.moduleCode,
    required this.label,
    required this.key,
    required this.inputType,
    required this.options,
    required this.isRequired,
    required this.sortOrder,
  });

  factory ModuleSpecModel.fromJson(Map<String, dynamic> json) {
    return ModuleSpecModel(
      id: json['id'] ?? 0,
      moduleCode: json['module_code'] ?? '',
      label: json['label'] ?? '',
      key: json['key'] ?? '',
      inputType: json['input_type'] ?? 'text',
      options: json['options'] ?? '',
      isRequired: json['is_required'] ?? false,
      sortOrder: json['sort_order'] ?? 0,
    );
  }

  List<String> get optionsList {
    if (options.isEmpty) return [];
    return options.split(',').map((e) => e.trim()).toList();
  }
}
