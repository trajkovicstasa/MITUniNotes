import 'dart:io';

import 'package:file_picker/file_picker.dart';
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
  String productPdfUrl = "";
  XFile? _pickedImage;
  String? _pickedPdfPath;
  String? _pickedPdfName;
  bool _isFree = false;

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
      productPdfUrl = product.pdfUrl;
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
      productPdfUrl = '';
      _pickedPdfPath = null;
      _pickedPdfName = null;
      _isFree = false;
    });
  }

  Future<void> pickPdfFile() async {
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
          subtitle: "Potrebno je da izaberes cover sliku",
          fct: () {},
        );
      return;
    }

    if (!isValid) {
      return;
    }

    if (_pickedPdfPath == null) {
      await MyAppFunctions.showErrorOrWarningDialog(
        context: context,
        subtitle: "Potrebno je da izaberes PDF skriptu",
        fct: () {},
      );
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      productImageUrl =
          await CloudinaryService.uploadImage(File(_pickedImage!.path));
      productPdfUrl = await CloudinaryService.uploadPdf(File(_pickedPdfPath!));

      final productId = const Uuid().v4();
      await FirebaseFirestore.instance.collection("products").doc(productId).set({
        'productId': productId,
        'productTitle': _titleController.text.trim(),
        'productPrice': _priceController.text.trim(),
        'productImage': productImageUrl,
        'productCategory': _categoryController.text.trim(),
        'productDescription': _descriptionController.text.trim(),
        'productQuantity': _quantityController.text.trim(),
        'pdfUrl': productPdfUrl,
        'pdfFileName': _pickedPdfName ?? '',
        'isFree': _isFree,
        'status': 'approved',
        'authorId': 'admin',
        'authorName': 'Admin',
        'createdAt': Timestamp.now(),
      });

      Fluttertoast.showToast(
        msg: "Skripta je uspesno dodata",
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
        subtitle: "Potrebno je da izaberes cover sliku",
        fct: () {},
      );
      return;
    }

    if (!isValid) {
      return;
    }

    if (_pickedPdfPath == null && productPdfUrl.isEmpty) {
      await MyAppFunctions.showErrorOrWarningDialog(
        context: context,
        subtitle: "Potrebno je da izaberes PDF skriptu",
        fct: () {},
      );
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
      if (_pickedPdfPath != null) {
        productPdfUrl = await CloudinaryService.uploadPdf(File(_pickedPdfPath!));
      }

      final imageToSave = productImageUrl.isNotEmpty
          ? productImageUrl
          : (productNetworkImage ?? "");
      final pdfToSave = productPdfUrl;

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
        'pdfUrl': pdfToSave,
        'pdfFileName': _pickedPdfName ?? widget.productModel!.pdfFileName,
        'isFree': _isFree,
        'status': widget.productModel!.status,
        'authorId': widget.productModel!.authorId,
        'authorName': widget.productModel!.authorName,
        'createdAt': widget.productModel!.createdAt,
      });

      Fluttertoast.showToast(
        msg: "Skripta je uspesno izmenjena",
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
            ? 'Azuriranje postojece skripte iz baze uz opcionu izmenu cover slike.'
            : 'Dodavanje nove skripte uz upload cover slike na Cloudinary i cuvanje podataka u Firestore.',
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
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
                  ),
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
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: pickPdfFile,
                          icon: const Icon(Icons.picture_as_pdf_outlined),
                          label: Text(
                            _pickedPdfName == null && productPdfUrl.isEmpty
                                ? 'Dodaj PDF'
                                : 'Promeni PDF',
                          ),
                        ),
                        if (_pickedPdfName != null || productPdfUrl.isNotEmpty) ...[
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _pickedPdfPath = null;
                                _pickedPdfName = null;
                                productPdfUrl = '';
                              });
                            },
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Ukloni'),
                          ),
                        ],
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
                decoration: const InputDecoration(
                  hintText: 'Predmet ili kategorija',
                ),
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
                decoration: const InputDecoration(
                  hintText: 'Naslov skripte',
                ),
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
                      decoration: const InputDecoration(
                        hintText: 'Cena',
                      ),
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
                      decoration: const InputDecoration(
                        hintText: 'Broj strana / kolicina',
                      ),
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
                      onPressed: clearForm,
                      icon: const Icon(Icons.clear_rounded),
                      label: const Text('Ocisti'),
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
                          ? (isEditing ? 'Cuvanje...' : 'Dodavanje...')
                          : (isEditing ? 'Sacuvaj izmene' : 'Dodaj skriptu'),
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
