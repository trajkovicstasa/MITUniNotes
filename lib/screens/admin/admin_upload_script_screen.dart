import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:notes_hub/models/product_model.dart';
import 'package:notes_hub/services/cloudinary_service.dart';
import 'package:notes_hub/services/my_app_functions.dart';
import 'package:notes_hub/widgets/admin/admin_section_card.dart';
import 'package:uuid/uuid.dart';

class AdminUploadScriptScreen extends StatefulWidget {
  const AdminUploadScriptScreen({super.key, this.productModel});

  final ProductModel? productModel;

  @override
  State<AdminUploadScriptScreen> createState() => _AdminUploadScriptScreenState();
}

class _AdminUploadScriptScreenState extends State<AdminUploadScriptScreen> {
  final _formKey = GlobalKey<FormState>();
  final _categoryController = TextEditingController();
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool get _isEditing => widget.productModel != null;

  String? _networkImage;
  String _imageUrl = '';
  String _pdfUrl = '';
  XFile? _pickedImage;
  String? _pickedPdfPath;
  String? _pickedPdfName;
  bool _isFree = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final product = widget.productModel;
    if (product != null) {
      _categoryController.text = product.productCategory;
      _titleController.text = product.productTitle;
      _priceController.text = product.productPrice;
      _quantityController.text = product.productQuantity;
      _descriptionController.text = product.productDescription;
      _networkImage = product.productImage;
      _pdfUrl = product.pdfUrl;
      _pickedPdfName = product.pdfFileName.isEmpty ? null : product.pdfFileName;
      _isFree = product.isFree;
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

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    await MyAppFunctions.imagePickerDialog(
      context: context,
      cameraFCT: () async {
        _pickedImage = await picker.pickImage(source: ImageSource.camera);
        if (!mounted) {
          return;
        }
        setState(() {
          _networkImage = null;
        });
      },
      galleryFCT: () async {
        _pickedImage = await picker.pickImage(source: ImageSource.gallery);
        if (!mounted) {
          return;
        }
        setState(() {
          _networkImage = null;
        });
      },
      removeFCT: () async {
        setState(() {
          _pickedImage = null;
          _networkImage = null;
        });
      },
    );
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      withData: false,
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final file = result.files.first;
    if (file.path == null) {
      if (!mounted) {
        return;
      }
      await MyAppFunctions.showErrorOrWarningDialog(
        context: context,
        subtitle: 'Izabrani PDF nema validnu putanju.',
        fct: () {},
      );
      return;
    }

    setState(() {
      _pickedPdfPath = file.path;
      _pickedPdfName = file.name;
    });
  }

  void _clearForm() {
    _categoryController.clear();
    _titleController.clear();
    _priceController.clear();
    _quantityController.clear();
    _descriptionController.clear();
    setState(() {
      _pickedImage = null;
      _networkImage = null;
      _imageUrl = '';
      _pdfUrl = '';
      _pickedPdfPath = null;
      _pickedPdfName = null;
      _isFree = false;
    });
  }

  Future<void> _saveProduct() async {
    final isValid = _formKey.currentState!.validate();
    FocusScope.of(context).unfocus();

    if (_pickedImage == null && _networkImage == null) {
      await MyAppFunctions.showErrorOrWarningDialog(
        context: context,
        subtitle: 'Potrebno je da izaberes cover sliku.',
        fct: () {},
      );
      return;
    }

    if (_pickedPdfPath == null && _pdfUrl.isEmpty) {
      await MyAppFunctions.showErrorOrWarningDialog(
        context: context,
        subtitle: 'Potrebno je da izaberes PDF skriptu.',
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
        _imageUrl = await CloudinaryService.uploadImage(File(_pickedImage!.path));
      }
      if (_pickedPdfPath != null) {
        _pdfUrl = await CloudinaryService.uploadPdf(File(_pickedPdfPath!));
      }

      final productId = widget.productModel?.productId ?? const Uuid().v4();
      await FirebaseFirestore.instance.collection('products').doc(productId).set({
        'productId': productId,
        'productTitle': _titleController.text.trim(),
        'productPrice': _priceController.text.trim(),
        'productImage': _imageUrl.isNotEmpty ? _imageUrl : (_networkImage ?? ''),
        'productCategory': _categoryController.text.trim(),
        'productDescription': _descriptionController.text.trim(),
        'productQuantity': _quantityController.text.trim(),
        'pdfUrl': _pdfUrl,
        'pdfFileName': _pickedPdfName ?? widget.productModel?.pdfFileName ?? '',
        'isFree': _isFree,
        'status': widget.productModel?.status ?? 'approved',
        'authorId': widget.productModel?.authorId ?? 'admin',
        'authorName': widget.productModel?.authorName ?? 'Admin',
        'rejectionReason': widget.productModel?.rejectionReason ?? '',
        'createdAt': widget.productModel?.createdAt ?? Timestamp.now(),
      }, SetOptions(merge: true));

      Fluttertoast.showToast(
        msg: _isEditing ? 'Skripta je uspesno izmenjena' : 'Skripta je uspesno dodata',
        textColor: Colors.white,
      );

      if (!mounted) {
        return;
      }
      Navigator.pop(context);
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
        : _networkImage != null
            ? Image.network(
                _networkImage!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.broken_image_outlined, size: 42);
                },
              )
            : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Izmeni skriptu' : 'Dodaj skriptu'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: AdminSectionCard(
          title: _isEditing ? 'Izmena skripte' : 'Nova skripta',
          subtitle: 'Dodavanje i izmena skripti iz glavne aplikacije kroz admin deo.',
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
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: currentImage == null
                        ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_outlined, size: 42),
                              SizedBox(height: 8),
                              Text('Izaberi cover sliku'),
                            ],
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: currentImage,
                          ),
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PDF skripta',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _pickedPdfName ??
                            (widget.productModel?.pdfFileName.isNotEmpty == true
                                ? widget.productModel!.pdfFileName
                                : 'PDF jos nije dodat'),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _pickPdf,
                            icon: const Icon(Icons.picture_as_pdf_outlined),
                            label: Text(
                              _pickedPdfName == null && _pdfUrl.isEmpty
                                  ? 'Dodaj PDF'
                                  : 'Promeni PDF',
                            ),
                          ),
                          if (_pickedPdfName != null || _pdfUrl.isNotEmpty)
                            OutlinedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _pickedPdfPath = null;
                                  _pickedPdfName = null;
                                  _pdfUrl = '';
                                });
                              },
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('Ukloni'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Besplatna skripta',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    _isFree
                        ? 'Korisnik moze odmah da preuzme PDF bez placanja.'
                        : 'PDF se otkljucava tek nakon kupovine.',
                  ),
                  value: _isFree,
                  onChanged: (value) {
                    setState(() {
                      _isFree = value;
                      if (_isFree) {
                        _priceController.text = '0';
                      }
                    });
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _categoryController,
                  decoration: const InputDecoration(hintText: 'Predmet ili kategorija'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Predmet je obavezan';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(hintText: 'Naslov skripte'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Naslov je obavezan';
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
                        readOnly: _isFree,
                        decoration: const InputDecoration(hintText: 'Cena'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Cena je obavezna';
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
                        decoration:
                            const InputDecoration(hintText: 'Broj strana / kolicina'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Ovo polje je obavezno';
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
                    hintText: 'Opis skripte',
                    alignLabelWithHint: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Opis je obavezan';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _clearForm,
                      icon: const Icon(Icons.clear_rounded),
                      label: const Text('Ocisti'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _saveProduct,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              _isEditing
                                  ? Icons.edit_outlined
                                  : Icons.cloud_upload_outlined,
                            ),
                      label: Text(
                        _isLoading
                            ? (_isEditing ? 'Cuvanje...' : 'Dodavanje...')
                            : (_isEditing ? 'Sacuvaj izmene' : 'Dodaj skriptu'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
