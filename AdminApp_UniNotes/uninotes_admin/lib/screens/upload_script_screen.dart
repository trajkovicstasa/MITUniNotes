import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uninotes_admin/services/cloudinary_service.dart';
import 'package:uninotes_admin/services/my_app_functions.dart';
import 'package:uninotes_admin/widgets/section_card.dart';
import 'package:uuid/uuid.dart';

class UploadScriptScreen extends StatefulWidget {
  const UploadScriptScreen({super.key});

  @override
  State<UploadScriptScreen> createState() => _UploadScriptScreenState();
}

class _UploadScriptScreenState extends State<UploadScriptScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool isEditing = false;
  String? productNetworkImage;
  bool _isLoading = false;
  String productImageUrl = "";
  XFile? _pickedImage;
  String? _categoryValue = 'Matematika';

  final List<String> _categories = const [
    'Matematika',
    'Programiranje',
    'Elektronika',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) {
      return;
    }
    setState(() {
      _pickedImage = image;
    });
  }

  void clearForm() {
    _titleController.clear();
    _priceController.clear();
    _quantityController.clear();
    _descriptionController.clear();
    setState(() {
      _pickedImage = null;
      _categoryValue = _categories.first;
      productImageUrl = '';
    });
  }

  Future<void> _uploadProduct() async {
    final isValid = _formKey.currentState!.validate();
    FocusScope.of(context).unfocus();

    if (_pickedImage == null) {
      await MyAppFunctions.showErrorOrWarningDialog(
        context: context,
        subtitle: "Make sure to pick up an image",
        fct: () {},
      );
      return;
    }

    if (!isValid) {
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      productImageUrl =
          await CloudinaryService.uploadImage(File(_pickedImage!.path));

      final productId = const Uuid().v4();
      await FirebaseFirestore.instance.collection("products").doc(productId).set({
        'productId': productId,
        'productTitle': _titleController.text.trim(),
        'productPrice': _priceController.text.trim(),
        'productImage': productImageUrl,
        'productCategory': _categoryValue,
        'productDescription': _descriptionController.text.trim(),
        'productQuantity': _quantityController.text.trim(),
        'createdAt': Timestamp.now(),
      });

      Fluttertoast.showToast(
        msg: "Product has been added",
        textColor: Colors.white,
      );

      if (!mounted) {
        return;
      }

      await MyAppFunctions.showErrorOrWarningDialog(
        isError: false,
        context: context,
        subtitle: "Clear Form?",
        fct: clearForm,
      );
    } on FirebaseException catch (error) {
      if (!mounted) {
        return;
      }
      await MyAppFunctions.showErrorOrWarningDialog(
        context: context,
        subtitle: error.message.toString(),
        fct: () {},
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      await MyAppFunctions.showErrorOrWarningDialog(
        context: context,
        subtitle: error.toString(),
        fct: () {},
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: SectionCard(
        title: 'Dodaj skriptu',
        subtitle:
            'Upload cover slike na Cloudinary i cuvanje proizvoda u Firestore po dokumentu sa vezbi.',
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Theme.of(context).dividerColor,
                      width: 1.2,
                    ),
                  ),
                  child: _pickedImage == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined, size: 42),
                            SizedBox(height: 8),
                            Text('Pick Product Image'),
                          ],
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.file(
                            File(_pickedImage!.path),
                            fit: BoxFit.cover,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 18),
              DropdownButtonFormField<String>(
                initialValue: _categoryValue,
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _categoryValue = value;
                  });
                },
                decoration: const InputDecoration(
                  hintText: 'Product category',
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: 'Product title',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Title is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: 'Price',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Price is required';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: 'Qty',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Qty is required';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _descriptionController,
                maxLines: 6,
                decoration: const InputDecoration(
                  hintText: 'Product description',
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Description is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: clearForm,
                    icon: const Icon(Icons.clear_rounded),
                    label: const Text('Clear'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _uploadProduct,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.cloud_upload_outlined),
                    label: Text(_isLoading ? 'Uploading...' : 'Upload Product'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
