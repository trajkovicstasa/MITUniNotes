import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uninotes_admin/models/product_model.dart';
import 'package:uninotes_admin/services/cloudinary_service.dart';
import 'package:uninotes_admin/services/my_app_functions.dart';
import 'package:uninotes_admin/widgets/section_card.dart';
import 'package:uninotes_admin/main.dart';
import 'package:uuid/uuid.dart';

class UploadScriptScreen extends StatefulWidget {
  const UploadScriptScreen({super.key, this.productModel});

  final ProductModel? productModel;

  @override
  State<UploadScriptScreen> createState() => _UploadScriptScreenState();
}

class _UploadScriptScreenState extends State<UploadScriptScreen> {
  final _formKey = GlobalKey<FormState>();
  final _categoryController = TextEditingController();
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool get isEditing => widget.productModel != null;

  String? productNetworkImage;
  bool _isLoading = false;
  String productImageUrl = "";
  XFile? _pickedImage;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      final product = widget.productModel!;
      _categoryController.text = product.productCategory;
      _titleController.text = product.productTitle;
      _priceController.text = product.productPrice;
      _quantityController.text = product.productQuantity;
      _descriptionController.text = product.productDescription;
      productNetworkImage = product.productImage;
    }
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _titleController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> localImagePicker() async {
    final picker = ImagePicker();
    await MyAppFunctions.imagePickerDialog(
      context: context,
      hasImage: _pickedImage != null || productNetworkImage != null,
      cameraFCT: () async {
        _pickedImage = await picker.pickImage(source: ImageSource.camera);
        if (!mounted) {
          return;
        }
        setState(() {
          productNetworkImage = null;
        });
      },
      galleryFCT: () async {
        _pickedImage = await picker.pickImage(source: ImageSource.gallery);
        if (!mounted) {
          return;
        }
        setState(() {
          productNetworkImage = null;
        });
      },
      removeFCT: () {
        setState(() {
          _pickedImage = null;
          productNetworkImage = null;
        });
      },
    );
  }

  void clearForm() {
    _categoryController.clear();
    _titleController.clear();
    _priceController.clear();
    _quantityController.clear();
    _descriptionController.clear();
    setState(() {
      _pickedImage = null;
      productNetworkImage = null;
      productImageUrl = '';
    });
  }

  void _returnToDashboard() {
    context.read<AdminNavigationController>().selectIndex(0);
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
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
        'productCategory': _categoryController.text.trim(),
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

      _returnToDashboard();
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

  Future<void> _editProduct() async {
    final isValid = _formKey.currentState!.validate();
    FocusScope.of(context).unfocus();

    if (_pickedImage == null && productNetworkImage == null) {
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

      if (_pickedImage != null) {
        productImageUrl =
            await CloudinaryService.uploadImage(File(_pickedImage!.path));
      }

      final imageToSave = productImageUrl.isNotEmpty
          ? productImageUrl
          : (productNetworkImage ?? "");

      await FirebaseFirestore.instance
          .collection("products")
          .doc(widget.productModel!.productId)
          .update({
        'productId': widget.productModel!.productId,
        'productTitle': _titleController.text.trim(),
        'productPrice': _priceController.text.trim(),
        'productImage': imageToSave,
        'productCategory': _categoryController.text.trim(),
        'productDescription': _descriptionController.text.trim(),
        'productQuantity': _quantityController.text.trim(),
        'createdAt': widget.productModel!.createdAt,
      });

      Fluttertoast.showToast(
        msg: "Product has been edited",
        textColor: Colors.white,
      );

      if (!mounted) {
        return;
      }

      _returnToDashboard();
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
    final currentImage = _pickedImage != null
        ? Image.file(File(_pickedImage!.path), fit: BoxFit.cover)
        : productNetworkImage != null
            ? Image.network(
                productNetworkImage!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.broken_image_outlined, size: 42);
                },
              )
            : null;

    return SingleChildScrollView(
      child: SectionCard(
        title: isEditing ? 'Izmeni skriptu' : 'Dodaj skriptu',
        subtitle: isEditing
            ? 'Azuriranje postojeceg proizvoda iz baze uz opcionu izmenu cover slike.'
            : 'Upload cover slike na Cloudinary i cuvanje proizvoda u Firestore po dokumentu sa vezbi.',
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: localImagePicker,
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
                  child: currentImage == null
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
                          child: currentImage,
                        ),
                ),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(
                  hintText: 'Subject or category',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Category is required';
                  }
                  return null;
                },
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
                    onPressed: _isLoading
                        ? null
                        : isEditing
                            ? _editProduct
                            : _uploadProduct,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            isEditing
                                ? Icons.edit_outlined
                                : Icons.cloud_upload_outlined,
                          ),
                    label: Text(
                      _isLoading
                          ? (isEditing ? 'Saving...' : 'Uploading...')
                          : (isEditing ? 'Edit Product' : 'Upload Product'),
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
}
