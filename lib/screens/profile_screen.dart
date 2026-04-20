import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:image_picker/image_picker.dart';
import 'package:notes_hub/consts/app_colors.dart';
import 'package:notes_hub/models/user_model.dart';
import 'package:notes_hub/providers/theme_provider.dart';
import 'package:notes_hub/providers/user_provider.dart';
import 'package:notes_hub/screens/auth/login.dart';
import 'package:notes_hub/screens/inner_screen/my_purchased_scripts_screen.dart';
import 'package:notes_hub/screens/inner_screen/my_unlocked_scripts_screen.dart';
import 'package:notes_hub/screens/inner_screen/my_submissions_screen.dart';
import 'package:notes_hub/screens/inner_screen/orders/orders_screen.dart';
import 'package:notes_hub/screens/inner_screen/submit_script_screen.dart';
import 'package:notes_hub/screens/inner_screen/viewed_recently.dart';
import 'package:notes_hub/screens/inner_screen/wishlist.dart';
import 'package:notes_hub/services/assets_manager.dart';
import 'package:notes_hub/services/cloudinary_service.dart';
import 'package:notes_hub/services/my_app_functions.dart';
import 'package:notes_hub/widgets/subtitle_text.dart';
import 'package:notes_hub/widgets/title_text.dart';
import 'package:notes_hub/widgets/uninotes_logo.dart';
import 'package:provider/provider.dart';
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  User? user = FirebaseAuth.instance.currentUser;
  UserModel? userModel;
  bool _isUpdatingImage = false;

  Future<void> fetchUserInfo() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    try {
      userModel = await userProvider.fetchUserInfo();
      if (mounted) {
        setState(() {});
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      await MyAppFunctions.showErrorOrWarningDialog(
        context: context,
        subtitle: error.toString(),
        fct: () {},
      );
    }
  }

  @override
  void initState() {
    fetchUserInfo();
    super.initState();
  }

  Future<void> _changeProfileImage() async {
    if (user == null || _isUpdatingImage) {
      return;
    }

    final imagePicker = ImagePicker();
    XFile? pickedImage;
    await MyAppFunctions.imagePickerDialog(
      context: context,
      cameraFCT: () async {
        pickedImage = await imagePicker.pickImage(source: ImageSource.camera);
      },
      galleryFCT: () async {
        pickedImage = await imagePicker.pickImage(source: ImageSource.gallery);
      },
      removeFCT: () async {
        setState(() {
          _isUpdatingImage = true;
        });
        try {
          await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
            'userImage': '',
          });
          await fetchUserInfo();
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
              _isUpdatingImage = false;
            });
          }
        }
      },
    );

    if (pickedImage == null || !mounted) {
      return;
    }

    try {
      setState(() {
        _isUpdatingImage = true;
      });
      final imageUrl = await CloudinaryService.uploadImage(
        File(pickedImage!.path),
      );
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
        'userImage': imageUrl,
      });
      await fetchUserInfo();
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
          _isUpdatingImage = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    user = FirebaseAuth.instance.currentUser;

    final themeProvider = Provider.of<ThemeProvider>(context);
    final profileImage = userModel?.userImage.trim() ?? '';
    final hasValidProfileImage = profileImage.startsWith('http');

    return Scaffold(
      appBar: AppBar(
        leading: const Padding(
          padding: EdgeInsets.all(8),
          child: UniNotesLogo(size: 34),
        ),
        title: const Text("Moj nalog"),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Visibility(
              visible: user == null,
              child: const Padding(
                padding: EdgeInsets.all(18),
                child: TitelesTextWidget(
                  label: "Prijavi se za pristup svojim beleskama i kupovinama",
                ),
              ),
            ),
            if (user != null && userModel != null)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Theme.of(context).cardColor,
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.surface,
                                  width: 3,
                                ),
                              ),
                              child: ClipOval(
                                child: !hasValidProfileImage
                                    ? Icon(
                                        Icons.person_rounded,
                                        size: 34,
                                        color:
                                            Theme.of(context).colorScheme.primary,
                                      )
                                    : Image.network(
                                        profileImage,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Icon(
                                            Icons.person_rounded,
                                            size: 34,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                          );
                                        },
                                      ),
                              ),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Material(
                                color: AppColors.lightPrimary,
                                shape: const CircleBorder(),
                                child: InkWell(
                                  customBorder: const CircleBorder(),
                                  onTap:
                                      _isUpdatingImage ? null : _changeProfileImage,
                                  child: Padding(
                                    padding: const EdgeInsets.all(7),
                                    child: _isUpdatingImage
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.camera_alt_rounded,
                                            size: 16,
                                            color: Colors.white,
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TitelesTextWidget(label: userModel!.userName),
                              SubtitleTextWidget(label: userModel!.userEmail),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _isUpdatingImage ? null : _changeProfileImage,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(
                        Icons.camera_alt_rounded,
                        size: 16,
                      ),
                      label: Text(
                        hasValidProfileImage
                            ? "Promeni profilnu sliku"
                            : "Dodaj profilnu sliku",
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const SizedBox(height: 10),
                  const TitelesTextWidget(label: "Pregled"),
                  const SizedBox(height: 10),
                  Visibility(
                    visible: user != null && userModel != null,
                    child: ListTile(
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          MyUnlockedScriptsScreen.routeName,
                        );
                      },
                      title: const SubtitleTextWidget(
                        label: "Moje otkljucane skripte",
                      ),
                      subtitle: const SubtitleTextWidget(
                        label:
                            "Jedna biblioteka za free skripte i premium skripte koje si kupila.",
                        color: AppColors.muted,
                        fontSize: 13,
                        maxLines: 2,
                      ),
                      leading: const Icon(
                        Icons.lock_open_rounded,
                        color: AppColors.lightPrimary,
                      ),
                      trailing: const Icon(IconlyLight.arrowRight2),
                    ),
                  ),
                  Visibility(
                    visible: user != null && userModel != null,
                    child: ListTile(
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          SubmitScriptScreen.routeName,
                        );
                      },
                      title: const SubtitleTextWidget(
                        label: "Posalji novu skriptu",
                      ),
                      subtitle: const SubtitleTextWidget(
                        label: "Skripta ide adminu na odobrenje pre objave.",
                        color: AppColors.muted,
                        fontSize: 13,
                        maxLines: 2,
                      ),
                      leading: const Icon(
                        Icons.upload_file_rounded,
                        color: AppColors.lightPrimary,
                      ),
                      trailing: const Icon(IconlyLight.arrowRight2),
                    ),
                  ),
                  Visibility(
                    visible: user != null && userModel != null,
                    child: ListTile(
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          MySubmissionsScreen.routeName,
                        );
                      },
                      title: const SubtitleTextWidget(
                        label: "Moje poslate skripte",
                      ),
                      subtitle: const SubtitleTextWidget(
                        label: "Pregled statusa: na cekanju, odobrena ili odbijena.",
                        color: AppColors.muted,
                        fontSize: 13,
                        maxLines: 2,
                      ),
                      leading: const Icon(
                        Icons.library_books_outlined,
                        color: AppColors.lightPrimary,
                      ),
                      trailing: const Icon(IconlyLight.arrowRight2),
                    ),
                  ),
                  Visibility(
                    visible: user != null && userModel != null,
                    child: ListTile(
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          MyPurchasedScriptsScreen.routeName,
                        );
                      },
                      title: const SubtitleTextWidget(
                        label: "Moje kupljene skripte",
                      ),
                      subtitle: const SubtitleTextWidget(
                        label:
                            "Brz pristup svim skriptama koje su ti otkljucane kupovinom.",
                        color: AppColors.muted,
                        fontSize: 13,
                        maxLines: 2,
                      ),
                      leading: const Icon(
                        Icons.workspace_premium_outlined,
                        color: AppColors.lightPrimary,
                      ),
                      trailing: const Icon(IconlyLight.arrowRight2),
                    ),
                  ),
                  Visibility(
                    visible: user != null && userModel != null,
                    child: CustomListTile(
                      imagePath: "${AssetsManager.imagePath}/bag/checkout.png",
                      text: "Moje kupovine",
                      function: () {
                        Navigator.pushNamed(context, OrdersScreen.routeName);
                      },
                    ),
                  ),
                  Visibility(
                    visible: user != null && userModel != null,
                    child: CustomListTile(
                      imagePath: "${AssetsManager.imagePath}/bag/wishlist.png",
                      text: "Sacuvane beleske",
                      function: () {
                        Navigator.pushNamed(context, WishlistScreen.routName);
                      },
                    ),
                  ),
                  CustomListTile(
                    imagePath: "${AssetsManager.imagePath}/profile/repeat.png",
                    text: "Nedavno pregledano",
                    function: () {
                      Navigator.pushNamed(
                        context,
                        ViewedRecentlyScreen.routName,
                      );
                    },
                  ),
                  const SizedBox(height: 6),
                  const Divider(),
                  const SizedBox(height: 10),
                  const TitelesTextWidget(label: "Settings"),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    secondary: Image.asset(
                      "${AssetsManager.imagePath}/profile/night-mode.png",
                      height: 34,
                    ),
                    title: Text(
                      themeProvider.getIsDarkTheme
                          ? "Tamna tema"
                          : "Svetla tema",
                    ),
                    value: themeProvider.getIsDarkTheme,
                    onChanged: (value) {
                      themeProvider.setDarkTheme(themeValue: value);
                    },
                  ),
                ],
              ),
            ),
            Center(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: Icon(
                  user == null ? Icons.login : Icons.logout,
                  color: Colors.white,
                ),
                label: Text(
                  user == null ? "Prijava" : "Odjava",
                  style: const TextStyle(color: Colors.white),
                ),
                onPressed: () async {
                  if (user == null) {
                    Navigator.pushNamed(context, LoginScreen.routeName);
                  } else {
                    await MyAppFunctions.showErrorOrWarningDialog(
                      context: context,
                      subtitle: "Da li sigurno zelis da se odjavis?",
                      isError: false,
                      fct: () async {
                        await FirebaseAuth.instance.signOut();
                        user = null;
                        userModel = null;
                        if (!context.mounted) {
                          return;
                        }
                        Navigator.pushReplacementNamed(
                          context,
                          LoginScreen.routeName,
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomListTile extends StatelessWidget {
  const CustomListTile({
    super.key,
    required this.imagePath,
    required this.text,
    required this.function,
  });

  final String imagePath;
  final String text;
  final VoidCallback function;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: function,
      title: SubtitleTextWidget(label: text),
      leading: Image.asset(
        imagePath,
        height: 34,
      ),
      trailing: const Icon(IconlyLight.arrowRight2),
    );
  }
}
