import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:notes_hub/consts/validator.dart';
import 'package:notes_hub/screens/auth/forgot_password.dart';
import 'package:notes_hub/screens/auth/register.dart';
import 'package:notes_hub/screens/admin/admin_root_screen.dart';
import 'package:notes_hub/screens/root_screen.dart';
import 'package:notes_hub/services/admin_access_service.dart';
import 'package:notes_hub/services/my_app_functions.dart';
import 'package:notes_hub/widgets/auth/google_btn.dart';
import 'package:notes_hub/widgets/subtitle_text.dart';
import 'package:notes_hub/widgets/title_text.dart';
import 'package:notes_hub/widgets/uninotes_logo.dart';

class LoginScreen extends StatefulWidget {
  static const String routeName = "/LoginScreen";
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool obscureText = true;
  bool _isAdminMode = false;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final FocusNode _emailFocusNode;
  late final FocusNode _passwordFocusNode;
  final _formkey = GlobalKey<FormState>();
  bool _isLoading = false;
  final auth = FirebaseAuth.instance;

  @override
  void initState() {
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
// Focus Nodes
    _emailFocusNode = FocusNode();
    _passwordFocusNode = FocusNode();
    super.initState();
  }

  @override
  void dispose() {
    if (mounted) {
      _emailController.dispose();
      _passwordController.dispose();
// Focus Nodes
      _emailFocusNode.dispose();
      _passwordFocusNode.dispose();
    }
    super.dispose();
  }

  Future<void> _loginFct({bool requireAdmin = false}) async {
    final isValid = _formkey.currentState!.validate();
    FocusScope.of(context).unfocus();
    if (isValid) {
      try {
        setState(() {
          _isLoading = true;
        });

        await auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        if (requireAdmin) {
          final currentUser = auth.currentUser;
          if (currentUser == null) {
            throw FirebaseAuthException(
              code: 'user-not-found',
              message: 'Admin nalog nije dostupan.',
            );
          }
          await AdminAccessService.ensureAdminAccessForAllowedEmail(currentUser);
          final isAdmin = await AdminAccessService.isAdminUser(currentUser);
          if (!isAdmin) {
            await auth.signOut();
            throw FirebaseAuthException(
              code: 'insufficient-permission',
              message:
                  'Ovaj nalog nema admin pristup. Dodaj email u admin_access_config.dart, ili postavi isAdmin: true, role: admin, ili admins dokument.',
            );
          }
        }
        Fluttertoast.showToast(
          msg: requireAdmin ? "Admin login successful" : "Login Successful",
          textColor: Colors.white,
        );
        if (!mounted) return;
        Navigator.of(context).pushNamedAndRemoveUntil(
          requireAdmin ? AdminRootScreen.routeName : RootScreen.routeName,
          (route) => false,
        );
      } on FirebaseException catch (error) {
        await MyAppFunctions.showErrorOrWarningDialog(
          context: context,
          subtitle: error.message.toString(),
          fct: () {},
        );
      } catch (error) {
        await MyAppFunctions.showErrorOrWarningDialog(
          context: context,
          subtitle: error.toString(),
          fct: () {},
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _submitCurrentLoginMode() async {
    await _loginFct(requireAdmin: _isAdminMode);
  }

  void _toggleAdminMode() {
    FocusScope.of(context).unfocus();
    setState(() {
      _isAdminMode = !_isAdminMode;
    });
    _formkey.currentState?.reset();

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            _isAdminMode
                ? 'Admin login mode je ukljucen.'
                : 'Vracen je obican korisnicki login mode.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
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
                  height: 16,
                ),
                const Align(
                    alignment: Alignment.centerLeft,
                    child: TitelesTextWidget(label: "Welcome back!")),
                const SizedBox(
                  height: 16,
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: _isAdminMode
                        ? Colors.blue.withValues(alpha: 0.10)
                        : Colors.grey.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _isAdminMode
                          ? Colors.blueAccent
                          : Colors.grey.shade400,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isAdminMode
                            ? Icons.admin_panel_settings_rounded
                            : Icons.person_outline_rounded,
                        color: _isAdminMode ? Colors.blueAccent : Colors.grey[700],
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _isAdminMode
                              ? 'Admin login mode je aktivan. Dugme ispod vodi u admin panel.'
                              : 'Aktivan je obican korisnicki login.',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 16,
                ),
                Form(
                  key: _formkey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
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
                        obscureText: obscureText,
                        controller: _passwordController,
                        focusNode: _passwordFocusNode,
                        textInputAction: TextInputAction.done,
                        keyboardType: TextInputType.visiblePassword,
                        decoration: InputDecoration(
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
                          hintText: "***********",
                          prefixIcon: const Icon(
                            IconlyLight.lock,
                          ),
                        ),
                        onFieldSubmitted: (value) async {
                          await _submitCurrentLoginMode();
                        },
                        validator: (value) {
                          return MyValidators.passwordValidator(value);
                        },
                      ),
                      const SizedBox(
                        height: 16.0,
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context)
                                .pushNamed(ForgotPasswordScreen.routeName);
                          },
                          child: const SubtitleTextWidget(
                            label: "Forgot password?",
                            fontStyle: FontStyle.italic,
                            textDecoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 16.0,
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
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(
                                  _isAdminMode
                                      ? Icons.admin_panel_settings_outlined
                                      : Icons.login,
                                ),
                          label: Text(
                            _isLoading
                                ? "Please wait..."
                                : _isAdminMode
                                    ? "Continue as Admin"
                                    : "Login",
                          ),
                          onPressed: () async {
                            if (_isLoading) {
                              return;
                            }
                            await _submitCurrentLoginMode();
                          },
                        ),
                      ),
                      const SizedBox(
                        height: 12.0,
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.all(12.0),
                            backgroundColor: _isAdminMode
                                ? Colors.blue.withValues(alpha: 0.08)
                                : null,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                          ),
                          icon: Icon(
                            _isAdminMode
                                ? Icons.close_rounded
                                : Icons.admin_panel_settings_outlined,
                          ),
                          label: Text(
                            _isAdminMode
                                ? "Exit Admin Mode"
                                : "Login as Admin",
                          ),
                          onPressed: () {
                            if (_isLoading) {
                              return;
                            }
                            _toggleAdminMode();
                          },
                        ),
                      ),
                      const SizedBox(
                        height: 16.0,
                      ),
                      SubtitleTextWidget(
                        label: "Or connect using".toUpperCase(),
                      ),
                      const SizedBox(
                        height: 16.0,
                      ),
                      SizedBox(
                        height: kBottomNavigationBarHeight + 10,
                        child: Row(
                          children: [
                            const Expanded(
                              flex: 2,
                              child: SizedBox(
                                height: kBottomNavigationBarHeight,
                                child: FittedBox(
                                  child: GoogleButton(),
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: 8,
                            ),
                            Expanded(
                              child: SizedBox(
                                height: kBottomNavigationBarHeight,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.all(12.0),
// backgroundColor: Colors.red,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        12.0,
                                      ),
                                    ),
                                  ),
                                  child: const Text("Guest?"),
                                  onPressed: () async {
                                    Navigator.of(context)
                                        .pushNamed(RootScreen.routeName);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 16.0,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SubtitleTextWidget(label: "New here?"),
                          TextButton(
                            child: const SubtitleTextWidget(
                              label: "Sign up",
                              fontStyle: FontStyle.italic,
                              textDecoration: TextDecoration.underline,
                            ),
                            onPressed: () {
                              Navigator.of(context)
                                  .pushNamed(RegisterScreen.routName);
                            },
                          ),
                        ],
                      )
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
