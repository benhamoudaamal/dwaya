import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../doctor/doctor_home.dart';
import '../patient/patients_page.dart';
import '../family/family_member_page.dart';
import 'signup_page.dart';
import '/widgets/doctor_navbar.dart';
import '/widgets/patient_navbar.dart';
import '/widgets/family_navbar.dart';
import 'forgot_password_page.dart';
import 'package:google_fonts/google_fonts.dart';

// Translations map (partagé)
Map<String, Map<String, String>> translations = {
  "fr": {
    "welcome": "Bienvenue 👋",

    "login": "Se connecter",
    "email": "Email",
    "password": "Mot de passe",
    "remember": "Se souvenir de moi",
    "create": "Créer un compte",
    "forgot": "Mot de passe oublié ?"
  },
  "en": {
    "welcome": "Bienvenue 👋",
    "login": "Login",
    "email": "Email",
    "password": "Password",
    "remember": "Remember me",
    "create": "Create account",
    "forgot": "Forgot password?"
  },
  "ar": {
    "welcome": "مرحبا  👋",
    "login": "تسجيل الدخول",
    "email": "البريد الإلكتروني",
    "password": "كلمة المرور",
    "remember": "تذكرني",
    "create": "إنشاء حساب",
    "forgot": "نسيت كلمة المرور؟"
  },
};

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final email = TextEditingController();
  final pass = TextEditingController();
  bool isLoading = false;
  bool obscure = true;
  late AnimationController _controller;
  String lang = "fr";
  List<Map<String, dynamic>> users = [];

  String t(String key) => translations[lang]![key]!;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
  vsync: this,
  duration: const Duration(milliseconds: 800),
)..repeat(reverse: true);
    loadUsers();
  }

  Future<void> loadUsers() async {

  final snap =
      await FirebaseFirestore.instance
          .collection("users")
          .get();

  setState(() {

    users = snap.docs.map((e) => {

      "id": e.id,

      "email": e["email"],

      "photoUrl": e.data().containsKey("photoUrl")
          ? e["photoUrl"]
          : "",

    }).toList();

  });
}
  Future<void> login() async {
    FocusScope.of(context).unfocus();
    if (email.text.isEmpty || pass.text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Fill all fields")));
      return;
    }
    setState(() => isLoading = true);
    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.text.trim(),
        password: pass.text.trim(),
      );
      await FirebaseAuth.instance.currentUser!.reload();
      final user = FirebaseAuth.instance.currentUser;

      if (user != null && user.emailVerified) {
        await FirebaseFirestore.instance
            .collection("users")
            .doc(cred.user!.uid)
            .update({"lastLogin": FieldValue.serverTimestamp()});

        final doc = await FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .get();
        final data = doc.data();
        final role = data?["role"] ?? "patient";
        final nom = data?["nom"] ?? "";
        final patientId = data?["patientId"] ?? "";

        setState(() => isLoading = false);

        if (role == "docteur") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const DoctorNavBar(),
            ),
          );
        }

// 👤 Patient
        else if (role == "patient") {
          final prenom = data?["prenom"] ?? "";
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => PatientNavBar(
                patientId: user.uid,
                patientName: "$nom $prenom",
              ),
            ),
          );
        }

// 👨‍👩‍👧 Famille
        else if (role == "famille") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => FamilyNavBar(
                memberName: nom,
                patientId: patientId,
              ),
            ),
          );
        }
      } else {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("⚠️ Vérifiez votre email d'abord")));
        await FirebaseAuth.instance.signOut();
      }
    } on FirebaseAuthException catch (e) {
      setState(() => isLoading = false);
      String msg = "Error";
      if (e.code == "user-not-found")
        msg = "Email incorrect ❌";
      else if (e.code == "wrong-password")
        msg = "Password wrong ❌";
      else if (e.code == "invalid-email") msg = "Invalid email ❌";
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> deleteAccount(String id) async {
    await FirebaseFirestore.instance.collection("users").doc(id).delete();
    await loadUsers();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Compte supprimé ✅")));
  }

  void confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirmation"),
        content: const Text("Tu veux vraiment supprimer ce compte ?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Non")),
          TextButton(
            onPressed: () {
              deleteAccount(id);
              Navigator.pop(context);
            },
            child: const Text("Oui", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
@override
void dispose() {
  _controller.dispose();
  email.dispose();
  pass.dispose();
  super.dispose();
}
  @override
  Widget build(BuildContext context) {
return Scaffold(
body: Container(
decoration: const BoxDecoration(
gradient: LinearGradient(
colors: [Color(0xFFE8F1FF), Color(0xFFF7FBFF)],
begin: Alignment.topCenter,
end: Alignment.bottomCenter,
),
),
child: SafeArea(
child: SingleChildScrollView(
padding: const EdgeInsets.all(20),
child: Column(
children: [
const SizedBox(height: 50),
Container(
  width: 115,
  height: 115,
  decoration: BoxDecoration(
    shape: BoxShape.circle,
    gradient: const LinearGradient(
      colors: [
        Color(0xFF4A90E2),
        Color(0xFF38BDF8),
      ],
    ),
    boxShadow: const [
      BoxShadow(
       color: Color(0x334A90E2),
blurRadius: 25,
spreadRadius: 5,
      ),
    ],
  ),
  child: const Icon(
    Icons.medication_rounded,
    color: Colors.white,
    size: 65,
  ),
),
const SizedBox(height: 20),

Row(
mainAxisAlignment: MainAxisAlignment.center,
children: ["fr", "en", "ar"]
.map(
(l) => Padding(
padding: const EdgeInsets.symmetric(horizontal: 5),
child: TextButton(
style: TextButton.styleFrom(
backgroundColor:
lang == l ? const Color(0xFF4A90E2) : Colors.white,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(12),
),
),
onPressed: () => setState(() => lang = l),
child: Text(
l.toUpperCase(),
style: TextStyle(
color:
lang == l ? Colors.white : const Color(0xFF4A90E2),
fontWeight: FontWeight.bold,
),
),
),
),
)
.toList(),
),

const SizedBox(height: 20),

Text(
  "Dwaya",
  style: GoogleFonts.poppins(
    fontSize: 38,
    fontWeight: FontWeight.w900,
    color: const Color(0xFF22304A),
  ),
),

const SizedBox(height: 10),

Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    Text(
      "Bienvenue",
      style: GoogleFonts.poppins(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF22304A),
      ),
    ),
    AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _controller.value * 0.3,
          child: const Text(
            " 👋",
            style: TextStyle(fontSize: 30),
          ),
        );
      },
    ),
  ],
),

const SizedBox(height: 8),

Text(
"Votre santé, notre priorité 🩺",
style: GoogleFonts.poppins(
  fontSize: 15,
  color: Colors.grey.shade600,
),
),
const SizedBox(height: 35),
Container(
  padding: const EdgeInsets.all(25),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(30),
    boxShadow: [
      BoxShadow(
  color: Colors.black.withOpacity(0.08),
  blurRadius: 25,
  offset: const Offset(0, 10),
),
    ],
  ),
  child: Column(
    children: [
TextField(
  controller: email,
  decoration: InputDecoration(
    filled: true,
    fillColor: const Color(0xFFEFF6FF),
    labelText: t("email"),
    prefixIcon: const Icon(
      Icons.email_outlined,
      color: Color(0xFF4A90E2),
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide.none,
    ),
  ),
),

const SizedBox(height: 18),
TextField(
  controller: pass,
  obscureText: obscure,
  decoration: InputDecoration(
    filled: true,
    fillColor: const Color(0xFFEFF6FF),

    labelText: t("password"),

    prefixIcon: const Icon(
      Icons.lock_outline,
      color: Color(0xFF4A90E2),
    ),

    suffixIcon: IconButton(
      icon: Icon(
        obscure ? Icons.visibility_off : Icons.visibility,
      ),
      onPressed: () => setState(() => obscure = !obscure),
    ),

    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide.none,
    ),

    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide.none,
    ),

    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide.none,
    ),
  ),
),
const SizedBox(height: 20),
Align(
alignment: Alignment.centerRight,
child: TextButton(
onPressed: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ForgotPasswordPage(
        lang: lang,
      ),
    ),
  );

},

child: Text(
  t("forgot"),
  style: const TextStyle(
    color: Color(0xFF4A90E2),
    fontWeight: FontWeight.w600,
  ),
),

),
),
Container(
width: double.infinity,
height: 55,
decoration: BoxDecoration(
borderRadius: BorderRadius.circular(18),
gradient: const LinearGradient(
colors: [
Color(0xFF4A90E2),
Color(0xFF38BDF8),
],
),
boxShadow: const [
BoxShadow(
color: Color(0x334A90E2),
blurRadius: 15,
),
],
),
child: ElevatedButton(
style: ElevatedButton.styleFrom(
backgroundColor: Colors.transparent,
shadowColor: Colors.transparent,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(18),
),
),
onPressed: isLoading ? null : login,
child: isLoading
? const CircularProgressIndicator(
color: Colors.white,
)
: const Text(
"Se connecter",
style: TextStyle(
color: Colors.white,
fontSize: 18,
fontWeight: FontWeight.bold,
),
),
),
),
const SizedBox(height: 20),
if (users.isNotEmpty)
Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
  "Comptes enregistrés 👥",
  style: GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: const Color(0xFF22304A),
  ),
),
...users.map((u) => Card(
color: Colors.white,
elevation: 6,
margin: const EdgeInsets.only(bottom: 12),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(20),
),
child: ListTile(
  leading: CircleAvatar(
  radius: 28,
  backgroundColor: const Color(0xFFEFF6FF),

  backgroundImage:
      u["photoUrl"] != null &&
              u["photoUrl"].toString().isNotEmpty
          ? NetworkImage(u["photoUrl"])
          : null,

  child: u["photoUrl"] == null ||
          u["photoUrl"].toString().isEmpty
      ? const Icon(
          Icons.person,
          color: Color(0xFF4A90E2),
          size: 30,
        )
      : null,
),

title: Text(
  u["email"],
  maxLines: 1,
  overflow: TextOverflow.ellipsis,
  style: const TextStyle(
    fontWeight: FontWeight.w600,
  ),
),
onTap: () => email.text = u["email"],
trailing: IconButton(
icon: const Icon(
Icons.delete_outline,
color: Color(0xFFE57373),
),
onPressed: () => confirmDelete(u["id"]),
),
),
)),
],
),
const SizedBox(height: 20),
Wrap(
  alignment: WrapAlignment.center,
  children: [
    Text(
      "Vous n'avez pas de compte ? ",
      style: GoogleFonts.poppins(
        color: Colors.grey.shade600,
        fontSize: 14,
      ),
    ),
    TextButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const SignupPage(),
          ),
        );
      },
      child: Text(
        "Créer un compte",
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          color: const Color(0xFF4A90E2),
          fontSize: 15,
        ),
      ),
    ),
  ],
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
