import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:notes_hub/consts/app_colors.dart';
import 'package:notes_hub/models/user_model.dart';
import 'package:notes_hub/providers/theme_provider.dart';
import 'package:notes_hub/providers/user_provider.dart';
import 'package:notes_hub/screens/auth/login.dart';
import 'package:notes_hub/screens/inner_screen/orders/orders_screen.dart';
import 'package:notes_hub/screens/inner_screen/viewed_recently.dart';
import 'package:notes_hub/screens/inner_screen/wishlist.dart';
import 'package:notes_hub/services/assets_manager.dart';
import 'package:notes_hub/services/my_app_functions.dart';
import 'package:notes_hub/widgets/subtitle_text.dart';
import 'package:notes_hub/widgets/title_text.dart';
import 'package:notes_hub/widgets/uninotes_logo.dart';
import 'package:provider/provider.dart';

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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    user = FirebaseAuth.instance.currentUser;

    final themeProvider = Provider.of<ThemeProvider>(context);

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
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).cardColor,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.surface,
                          width: 3,
                        ),
                        image: DecorationImage(
                          image: NetworkImage(userModel!.userImage),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TitelesTextWidget(label: userModel!.userName),
                        SubtitleTextWidget(label: userModel!.userEmail),
                      ],
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
                  CustomListTile(
                    imagePath: "${AssetsManager.imagePath}/address.png",
                    text: "Podaci o nalogu",
                    function: () {},
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
