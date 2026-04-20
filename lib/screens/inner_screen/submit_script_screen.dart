import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:notes_hub/models/product_model.dart';
import 'package:notes_hub/providers/user_provider.dart';
import 'package:notes_hub/services/cloudinary_service.dart';
import 'package:notes_hub/services/my_app_functions.dart';
import 'package:notes_hub/widgets/subtitle_text.dart';
import 'package:notes_hub/widgets/title_text.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class SubmitScriptScreen extends StatefulWidget {
  static const routeName = '/posalji-skriptu';

  const SubmitScriptScreen({super.key, this.productModel});

  final ProductModel? productModel;

  @override
  State<SubmitScriptScreen> createState() => _SubmitScriptScreenState();
}

class _SubmitScriptScreenState extends State<SubmitScriptScreen> {
  final _formKey = GlobalKey<FormState>();
  final _categoryController = TextEditingController();
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _descriptionController = TextEditingController();

  XFile? _pickedImage;
  String? _pickedPdfPath;
  String? _pickedPdfName;
  String? _existingImageUrl;
  String? _existingPdfUrl;
  bool _isFree = false;
  bool _isLoading = false;

  bool get _isEditing => widget.productModel != null;

  @override
  void initState() {
    super.initState();
    final existingProduct = widget.productModel;
    if (existingProduct != null) {
      _categoryController.text = existingProduct.productCategory;
      _titleController.text = existingProduct.productTitle;
      _priceController.text = existingProduct.productPrice;
      _quantityController.text = existingProduct.productQuantity;
      _descriptionController.text = existingProduct.productDescription;
      _pickedPdfName = existingProduct.pdfFileName.isNotEmpty
          ? existingProduct.pdfFileName
          : null;
      _existingPdfUrl = existingProduct.pdfUrl.isNotEmpty
          ? existingProduct.pdfUrl
          : null;
      _existingImageUrl = existingProduct.productImage.isNotEmpty
          ? existingProduct.productImage
          : null;
      _isFree = existingProduct.isFree;
      if (_isFree && _priceController.text.trim().isEmpty) {
        _priceController.text = '0';
      }
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

  Future<void> _pickCoverImage() async {
    final picker = ImagePicker();
    await MyAppFunctions.imagePickerDialog(
      context: context,
      cameraFCT: () async {
        _pickedImage = await picker.pickImage(source: ImageSource.camera);
        if (mounted) {
          setState(() {});
        }
      },
      galleryFCT: () async {
        _pickedImage = await picker.pickImage(source: ImageSource.gallery);
        if (mounted) {
          setState(() {});
        }
      },
      removeFCT: () async {
        if (mounted) {
          setState(() {
            _pickedImage = null;
          });
        }
      },
    );
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
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

  Future<void> _submitForApproval() async {
    final isValid = _formKey.currentState!.validate();
    FocusScope.of(context).unfocus();

    if (_pickedImage == null && (_existingImageUrl == null || _existingImageUrl!.isEmpty)) {
      await MyAppFunctions.showErrorOrWarningDialog(
        context: context,
        subtitle: 'Potrebno je da izaberes cover sliku.',
        fct: () {},
      );
      return;
    }

    if (_pickedPdfPath == null && (_existingPdfUrl == null || _existingPdfUrl!.isEmpty)) {
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

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      await MyAppFunctions.showErrorOrWarningDialog(
        context: context,
        subtitle: 'Prvo se prijavi na nalog.',
        fct: () {},
      );
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userModel = userProvider.getUserModel ?? await userProvider.fetchUserInfo();
      final authorName = userModel?.userName.isNotEmpty == true
          ? userModel!.userName
          : (currentUser.email?.split('@').first ?? 'Korisnik');

      final imageUrl = _pickedImage != null
          ? await CloudinaryService.uploadImage(
              File(_pickedImage!.path),
              folder: 'uninotes/covers',
            )
          : (_existingImageUrl ?? '');
      final pdfUrl = _pickedPdfPath != null
          ? await CloudinaryService.uploadPdf(File(_pickedPdfPath!))
          : (_existingPdfUrl ?? '');
      final productId = widget.productModel?.productId ?? const Uuid().v4();

      await FirebaseFirestore.instance.collection('products').doc(productId).set({
        'productId': productId,
        'productTitle': _titleController.text.trim(),
        'productPrice': _isFree ? '0' : _priceController.text.trim(),
        'productImage': imageUrl,
        'productCategory': _categoryController.text.trim(),
        'productDescription': _descriptionController.text.trim(),
        'productQuantity': _quantityController.text.trim(),
        'pdfUrl': pdfUrl,
        'pdfFileName': _pickedPdfName ?? '',
        'isFree': _isFree,
        'status': 'pending',
        'rejectionReason': '',
        'authorId': currentUser.uid,
        'authorName': authorName,
        'createdAt': widget.productModel?.createdAt ?? Timestamp.now(),
      }, SetOptions(merge: true));

      Fluttertoast.showToast(
        msg: _isEditing
            ? 'Izmenjena skripta je ponovo poslata adminu na odobrenje'
            : 'Skripta je poslata adminu na odobrenje',
        textColor: Colors.white,
      );

      if (!mounted) {
        return;
      }
      Navigator.pop(context);
    } on FirebaseException catch (error) {
      if (!mounted) {
        return;
      }
      await MyAppFunctions.showErrorOrWarningDialog(
        context: context,
        subtitle: error.message ?? 'Doslo je do Firebase greske.',
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
    final currentImage = _pickedImage == null
        ? (_existingImageUrl == null || _existingImageUrl!.isEmpty
            ? null
            : Image.network(
                _existingImageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox.shrink();
                },
              ))
        : Image.file(
            File(_pickedImage!.path),
            fit: BoxFit.cover,
          );

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Izmeni i posalji ponovo' : 'Posalji novu skriptu'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TitelesTextWidget(label: 'Slanje adminu na odobrenje'),
                    SizedBox(height: 8),
                    SubtitleTextWidget(
                      label:
                          'Skripta se ne objavljuje odmah. Prvo ide adminu na pregled, a tek nakon odobrenja postaje vidljiva u aplikaciji.',
                      maxLines: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: _pickCoverImage,
                child: Container(
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: currentImage == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined, size: 42),
                            SizedBox(height: 10),
                            Text('Izaberi cover sliku'),
                          ],
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: currentImage,
                        ),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const TitelesTextWidget(label: 'PDF skripta', fontSize: 17),
                    const SizedBox(height: 8),
                    SubtitleTextWidget(
                      label: _pickedPdfName ?? 'PDF jos nije dodat',
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
                            _pickedPdfName == null ? 'Dodaj PDF' : 'Promeni PDF',
                          ),
                        ),
                        if (_pickedPdfName != null)
                          OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _pickedPdfPath = null;
                                _pickedPdfName = null;
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
                      ? 'Skripta ce nakon odobrenja biti odmah dostupna za pregled i preuzimanje.'
                      : 'Skripta ce nakon odobrenja biti dostupna tek posle kupovine.',
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
                        hintText: 'Broj strana',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Broj strana je obavezan';
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
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _submitForApproval,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(
                    _isLoading
                        ? 'Slanje...'
                        : (_isEditing
                            ? 'Sacuvaj izmene i posalji ponovo'
                            : 'Posalji adminu na odobrenje'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
