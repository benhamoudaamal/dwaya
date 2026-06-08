import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

Map<String, Map<String, String>> fpTranslations = {
  "fr": {
    "title": "Mot de passe oublié",
    "subtitle": "Entrez votre email pour réinitialiser votre mot de passe",
    "email": "Adresse e-mail",
    "send": "Envoyer le lien",
    "back": "Retour à la connexion",
    "successTitle": "Email envoyé !",
    "successMsg": "Un lien de réinitialisation a été envoyé à votre adresse e-mail.",
    "errorInvalid": "Adresse e-mail invalide ou introuvable.",
    "errorEmpty": "Veuillez saisir votre adresse e-mail.",
  },
  "en": {
    "title": "Forgot Password",
    "subtitle": "Enter your email to reset your password",
    "email": "Email address",
    "send": "Send reset link",
    "back": "Back to login",
    "successTitle": "Email sent!",
    "successMsg": "A reset link has been sent to your email address.",
    "errorInvalid": "Invalid or unknown email address.",
    "errorEmpty": "Please enter your email address.",
  },
  "ar": {
    "title": "نسيت كلمة المرور",
    "subtitle": "أدخل بريدك الإلكتروني لإعادة تعيين كلمة المرور",
    "email": "البريد الإلكتروني",
    "send": "إرسال الرابط",
    "back": "العودة إلى تسجيل الدخول",
    "successTitle": "تم الإرسال!",
    "successMsg": "تم إرسال رابط إعادة التعيين إلى بريدك الإلكتروني.",
    "errorInvalid": "عنوان البريد الإلكتروني غير صالح أو غير موجود.",
    "errorEmpty": "يرجى إدخال عنوان بريدك الإلكتروني.",
  },
};

class ForgotPasswordPage extends StatefulWidget {
  final String lang;

  const ForgotPasswordPage({super.key, this.lang = "fr"});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage>
    with SingleTickerProviderStateMixin {
  final emailController = TextEditingController();

  bool isLoading = false;
  bool emailSent = false;
  String? errorMessage;

  late String lang;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  String t(String key) => fpTranslations[lang]![key]!;

  @override
  void initState() {
    super.initState();
    lang = widget.lang;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    emailController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    final emailText = emailController.text.trim();

    // Validate locally first
    if (emailText.isEmpty) {
      setState(() => errorMessage = t("errorEmpty"));
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // 1. Vérifier l'adresse e-mail via Firebase Auth
      // 2. Envoyer une demande de réinitialisation à Firebase Firestore/Auth
      await FirebaseAuth.instance.sendPasswordResetEmail(email: emailText);

      // [Adresse e-mail valide] → Lien de réinitialisation envoyé → Afficher message de confirmation
      setState(() {
        emailSent = true;
        isLoading = false;
      });
    } on FirebaseAuthException catch (e) {
      // [Adresse e-mail invalide] → Échec de réinitialisation → Afficher un message d'erreur
      setState(() {
        isLoading = false;
        errorMessage = t("errorInvalid");
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = t("errorInvalid");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // ─── HEADER ───────────────────────────────────────────
                  Container(
                    height: 220,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF0EA5E9), Color(0xFF14B8A6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(40),
                        bottomRight: Radius.circular(40),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.lock_reset,
                            size: 50,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          t("title"),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            t("subtitle"),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ─── CARD ─────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 25,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: emailSent
                          ? _buildSuccessState()
                          : _buildFormState(),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ─── BACK TO LOGIN ─────────────────────────────────────
                  TextButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new,
                        size: 14, color: Color(0xFF14B8A6)),
                    label: Text(
                      t("back"),
                      style: const TextStyle(
                        color: Color(0xFF14B8A6),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── FORM STATE ──────────────────────────────────────────────────────────
  Widget _buildFormState() {
    return Column(
      children: [
        // Email field
        TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: t("email"),
            prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF0EA5E9)),
            filled: true,
            fillColor: const Color(0xFFF1F5F9),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Color(0xFF0EA5E9), width: 1.5),
            ),
          ),
        ),

        // Error message
        if (errorMessage != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 22),

        // Send button
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0EA5E9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 6,
            ),
            onPressed: isLoading ? null : _sendResetEmail,
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    t("send"),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  // ─── SUCCESS STATE ────────────────────────────────────────────────────────
  Widget _buildSuccessState() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFE6FAF5),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF14B8A6), width: 2),
          ),
          child: const Icon(
            Icons.mark_email_read_outlined,
            size: 48,
            color: Color(0xFF14B8A6),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          t("successTitle"),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF14B8A6),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          t("successMsg"),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        // Resend option
        OutlinedButton.icon(
          onPressed: () => setState(() => emailSent = false),
          icon: const Icon(Icons.refresh, color: Color(0xFF0EA5E9)),
          label: const Text(
            "Renvoyer",
            style: TextStyle(color: Color(0xFF0EA5E9)),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFF0EA5E9)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}