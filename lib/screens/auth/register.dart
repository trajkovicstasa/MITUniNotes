import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:notes_hub/consts/validator.dart';
import 'package:notes_hub/screens/root_screen.dart';
import 'package:notes_hub/services/cloudinary_service.dart';
import 'package:notes_hub/services/my_app_functions.dart';
import 'package:notes_hub/widgets/subtitle_text.dart';
import 'package:notes_hub/widgets/title_text.dart';
import 'package:notes_hub/widgets/uninotes_logo.dart';

class RegisterScreen extends StatefulWidget {
  static const routName = "/RegisterScreen";
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool obscureText = true;
  late final TextEditingController _nameController,
      _emailController,
      _passwordController,
      _repeatPasswordController;
  late final FocusNode _nameFocusNode,
      _emailFocusNode,
      _passwordFocusNode,
      _repeatPasswordFocusNode;
  final _formkey = GlobalKey<FormState>();
  XFile? _pickedImage;
  bool _isLoading = false;
  final auth = FirebaseAuth.instance;
  @override
  void initState() {
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _repeatPasswordController = TextEditingController();
// Focus Nodes
    _nameFocusNode = FocusNode();
    _emailFocusNode = FocusNode();
    _passwordFocusNode = FocusNode();
    _repeatPasswordFocusNode = FocusNode();
    super.initState();
  }

  @override
  void dispose() {
    if (mounted) {
      _nameController.dispose();
      _emailController.dispose();
      _passwordController.dispose();
      _repeatPasswordController.dispose();
// Focus Nodes
      _nameFocusNode.dispose();
      _emailFocusNode.dispose();
      _passwordFocusNode.dispose();
      _repeatPasswordFocusNode.dispose();
    }
    super.dispose();
  }

  Future<void> _registerFCT() async {
    if (_isLoading) {
      return;
    }

    final isValid = _formkey.currentState!.validate();
    FocusScope.of(context).unfocus();

    if (isValid) {
      UserCredential? userCredential;
      try {
        setState(() {
          _isLoading = true;
        });

        userCredential = await auth
            .createUserWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _passwordController.text.trim(),
            )
            .timeout(const Duration(seconds: 15));
        final User? user = userCredential.user;
        final String uid = user!.uid;
        String userImageUrl = '';
        if (_pickedImage != null) {
          userImageUrl = await CloudinaryService.uploadImage(
            File(_pickedImage!.path),
          );
        }
        try {
          await FirebaseFirestore.instance
              .collection("users")
              .doc(uid)
              .set({
                "userId": uid,
                "userName": _nameController.text.trim(),
                "userImage": userImageUrl,
                "userEmail": _emailController.text.trim(),
                "createdAt": Timestamp.now(),
                "userCart": [],
                "userWish": [],
              })
              .timeout(const Duration(seconds: 30));
        } on FirebaseException catch (error) {
          await user.delete();
          await auth.signOut();
          if (!mounted) return;
          await MyAppFunctions.showErrorOrWarningDialog(
            context: context,
            subtitle: "Firestore: ${error.code} | ${error.message}",
            fct: () {},
          );
          return;
        } on TimeoutException {
          await user.delete();
          await auth.signOut();
          if (!mounted) return;
          await MyAppFunctions.showErrorOrWarningDialog(
            context: context,
            subtitle: "Firestore timeout. Check Firestore setup/rules and try again.",
            fct: () {},
          );
          return;
        }
        Fluttertoast.showToast(
          msg: "An account has been created",
          textColor: Colors.white,
        );
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, RootScreen.routeName);
      } on FirebaseException catch (error) {
        if (userCredential?.user != null) {
          await userCredential!.user!.delete();
          await auth.signOut();
        }
        if (!mounted) return;
        await MyAppFunctions.showErrorOrWarningDialog(
          context: context,
          subtitle: error.message.toString(),
          fct: () {},
        );
      } on TimeoutException {
        if (userCredential?.user != null) {
          await userCredential!.user!.delete();
          await auth.signOut();
        }
        if (!mounted) return;
        await MyAppFunctions.showErrorOrWarningDialog(
          context: context,
          subtitle: "Request timed out. Check internet connection and try again.",
          fct: () {},
        );
      } catch (error) {
        if (userCredential?.user != null) {
          await userCredential!.user!.delete();
          await auth.signOut();
        }
        if (!mounted) return;
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
  }

  Future<void> localImagePicker() async {
    final ImagePicker imagePicker = ImagePicker();
    await MyAppFunctions.imagePickerDialog(
      context: context,
      cameraFCT: () async {
        _pickedImage = await imagePicker.pickImage(source: ImageSource.camera);
        setState(() {});
      },
      galleryFCT: () async {
        _pickedImage = await imagePicker.pickImage(source: ImageSource.gallery);
        setState(() {});
      },
      removeFCT: () async {
        setState(() {
          _pickedImage = null;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
// const BackButton(),
                const SizedBox(
                  height: 60,
                ),
                 const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    UniNotesLogo(size: 60),
                    SizedBox(width: 12),
                    Text(
                      "UniNotes",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 30,
                ),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TitelesTextWidget(label: "Napravi nalog"),
                      SubtitleTextWidget(
                        label: "Dodaj podatke i opciono postavi profilnu sliku.",
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 30,
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).scaffoldBackgroundColor,
                          border: Border.all(
                            color: Theme.of(context).dividerColor,
                          ),
                        ),
                        child: ClipOval(
                          child: _pickedImage == null
                              ? Icon(
                                  Icons.person_rounded,
                                  size: 36,
                                  color: Theme.of(context).colorScheme.primary,
                                )
                              : Image.file(
                                  File(_pickedImage!.path),
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const TitelesTextWidget(
                              label: "Profilna slika",
                              fontSize: 18,
                            ),
                            const SizedBox(height: 4),
                            const SubtitleTextWidget(
                              label:
                                  "Moze odmah pri registraciji ili kasnije sa profila.",
                              maxLines: 2,
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () async {
                                    await localImagePicker();
                                  },
                                  icon: const Icon(Icons.add_a_photo_outlined),
                                  label: Text(
                                    _pickedImage == null
                                        ? "Dodaj sliku"
                                        : "Promeni sliku",
                                  ),
                                ),
                                if (_pickedImage != null)
                                  TextButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        _pickedImage = null;
                                      });
                                    },
                                    icon: const Icon(Icons.delete_outline),
                                    label: const Text("Ukloni"),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 30,
                ),
                Form(
                  key: _formkey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        focusNode: _nameFocusNode,
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.name,
                        decoration: const InputDecoration(
                          hintText: 'Full Name',
                          prefixIcon: Icon(
                            Icons.person,
                          ),
                        ),
                        onFieldSubmitted: (value) {
                          FocusScope.of(context).requestFocus(_emailFocusNode);
                        },
                        validator: (value) {
                          return MyValidators.displayNamevalidator(value);
                        },
                      ),
                      const SizedBox(
                        height: 16.0,
                      ),
                      TextFormField(
                        controller: _emailController,
                        focusNode: _emailFocusNode,
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          hintText: "Email address",
                          prefixIcon: Icon(
                            IconlyLight.message,
                          ),
                        ),
                        onFieldSubmitted: (value) {
                          FocusScope.of(context)
                              .requestFocus(_passwordFocusNode);
                        },
                        validator: (value) {
                          return MyValidators.emailValidator(value);
                        },
                      ),
                      const SizedBox(
                        height: 16.0,
                      ),
                      TextFormField(
                        controller: _passwordController,
                        focusNode: _passwordFocusNode,
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.visiblePassword,
                        obscureText: obscureText,
                        decoration: InputDecoration(
                          hintText: "***********",
                          prefixIcon: const Icon(
                            IconlyLight.lock,
                          ),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                obscureText = !obscureText;
                              });
                            },
                            icon: Icon(
                              obscureText
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                          ),
                        ),
                        onFieldSubmitted: (value) async {
                          FocusScope.of(context)
                              .requestFocus(_repeatPasswordFocusNode);
                        },
                        validator: (value) {
                          return MyValidators.passwordValidator(value);
                        },
                      ),
                      const SizedBox(
                        height: 16.0,
                      ),
                      TextFormField(
                        controller: _repeatPasswordController,
                        focusNode: _repeatPasswordFocusNode,
                        textInputAction: TextInputAction.done,
                        keyboardType: TextInputType.visiblePassword,
                        obscureText: obscureText,
                        decoration: InputDecoration(
                          hintText: "Repeat password",
                          prefixIcon: const Icon(
                            IconlyLight.lock,
                          ),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                obscureText = !obscureText;
                              });
                            },
                            icon: Icon(
                              obscureText
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                          ),
                        ),
                        onFieldSubmitted: (value) async {
                          await _registerFCT();
                        },
                        validator: (value) {
                          return MyValidators.repeatPasswordValidator(
                            value: value,
                            password: _passwordController.text,
                          );
                        },
                      ),
                      const SizedBox(
                        height: 36.0,
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(12.0),
// backgroundColor: Colors.red,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                12.0,
                              ),
                            ),
                          ),
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(IconlyLight.addUser),
                          label: Text(_isLoading ? "Please wait..." : "Sign up"),
                          onPressed: _isLoading
                              ? null
                              : () async {
                                  await _registerFCT();
                                },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
