import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sultan/features/category/domain/models/category.dart';
import 'package:sultan/features/category/presentation/controllers/category_controller.dart';

class CategoryFormDialog extends ConsumerStatefulWidget {
  final Category? existing;
  final String? parentId;
  final String? parentName;
  final List<Category> categories;

  const CategoryFormDialog({
    super.key,
    this.existing,
    this.parentId,
    this.parentName,
    required this.categories,
  });

  @override
  ConsumerState<CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends ConsumerState<CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  String? _selectedParentId;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.name ?? '');
    _descriptionController = TextEditingController(
      text: widget.existing?.description ?? '',
    );
    _selectedParentId = widget.parentId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final notifier = ref.read(categoryControllerProvider.notifier);
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim().isEmpty
        ? null
        : _descriptionController.text.trim();

    bool success;
    if (_isEdit) {
      success = await notifier.update(
        widget.existing!.id,
        CategoryUpdateRequest(
          name: name,
          description: description,
          parentId: _selectedParentId,
        ),
      );
    } else {
      success = await notifier.create(
        CategoryCreateRequest(
          name: name,
          description: description,
          parentId: _selectedParentId,
        ),
      );
    }

    if (mounted) {
      setState(() => _saving = false);
      if (success) Navigator.pop(context);
    }
  }

  List<DropdownMenuEntry<String?>> _parentEntries() {
    final entries = <DropdownMenuEntry<String?>>[
      const DropdownMenuEntry(value: null, label: 'None (top-level)'),
    ];
    for (final cat in widget.categories) {
      if (widget.existing == null || cat.id != widget.existing!.id) {
        entries.add(DropdownMenuEntry(value: cat.id, label: cat.name));
      }
    }
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? 'Edit Category' : 'Add Category'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.parentName != null) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.subdirectory_arrow_right),
                  title: Text('Under: ${widget.parentName}'),
                  dense: true,
                ),
                const SizedBox(height: 8),
              ],
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name *'),
                textInputAction: TextInputAction.next,
                enabled: !_saving,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                ),
                textInputAction: TextInputAction.done,
                maxLines: 2,
                enabled: !_saving,
              ),
              const SizedBox(height: 12),
              if (widget.parentName == null)
                DropdownMenu<String?>(
                  label: const Text('Parent category'),
                  initialSelection: _selectedParentId,
                  enabled: !_saving,
                  width: double.infinity,
                  dropdownMenuEntries: _parentEntries(),
                  onSelected: (value) =>
                      setState(() => _selectedParentId = value),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_isEdit ? 'Save' : 'Add'),
        ),
      ],
    );
  }
}
