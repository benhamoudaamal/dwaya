import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});
  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final nom = TextEditingController();
  final prenom = TextEditingController();
  final email = TextEditingController();
  final pass = TextEditingController();
  final tel = TextEditingController();
  final otpController = TextEditingController();

  DateTime? selectedDate;
  String selectedRole = "patient";
  String? sexe;

  // ✅ Stocker les bytes en mémoire au lieu du File
  Uint8List? imageBytes;
  File? image; // Juste pour afficher l'aperçu

  bool isLoading = false;
  bool obscure = true;

  String verificationId = "";
  bool phoneSent = false;
  bool phoneVerified = false;
  bool isSendingOtp = false;

  static const String defaultAvatarUrl =
      "https://ui-avatars.com/api/?background=0D8ABC&color=fff&size=200";

  String? errNom, errPrenom, errEmail, errPass, errTel, errSexe;

  bool get isTestNumber {
    final number = tel.text.trim();
    return number == "00000000" || number.startsWith("000");
  }

  Future<void> pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  // ✅ Lire les bytes immédiatement après la sélection
  Future<void> pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) {
      // Lire les bytes MAINTENANT pendant que le fichier existe encore
      final bytes = await picked.readAsBytes();
      setState(() {
        imageBytes = bytes;
        image = File(picked.path); // Pour l'aperçu seulement
      });
    }
  }

  // 📱 Envoyer OTP
  Future<void> sendOtp() async {
    final number = tel.text.trim();

    if (!isTestNumber && !RegExp(r'^(2|4|5|9)\d{7}$').hasMatch(number)) {
      setState(() => errTel = "Numéro tunisien invalide");
      return;
    }

    setState(() {
      isSendingOtp = true;
      errTel = null;
    });

    if (isTestNumber) {
      setState(() {
        phoneSent = true;
        isSendingOtp = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("📩 [TEST] Utilisez le code : 123456"),
            backgroundColor: Colors.blue,
          ),
        );
      }
      return;
    }

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: "+216$number",
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        setState(() {
          phoneVerified = true;
          phoneSent = false;
          isSendingOtp = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("✅ Téléphone vérifié automatiquement !"),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        setState(() => isSendingOtp = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("❌ Erreur: ${e.message}")),
          );
        }
      },
      codeSent: (String vId, int? resendToken) {
        setState(() {
          verificationId = vId;
          phoneSent = true;
          isSendingOtp = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("📩 Code SMS envoyé !"),
              backgroundColor: Colors.blue,
            ),
          );
        }
      },
      codeAutoRetrievalTimeout: (String vId) {
        verificationId = vId;
      },
    );
  }

  // ✅ Vérifier OTP
  Future<void> verifyOtp() async {
    final code = otpController.text.trim();

    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Entrez le code à 6 chiffres")),
      );
      return;
    }

    if (isTestNumber) {
      if (code == "123456") {
        setState(() {
          phoneVerified = true;
          phoneSent = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("✅ Téléphone vérifié !"),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("❌ Code incorrect (utilisez 123456)"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
      return;
    }

    try {
      setState(() => isLoading = true);
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: code,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      setState(() {
        phoneVerified = true;
        phoneSent = false;
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Téléphone vérifié !"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("❌ Code incorrect"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 📸 Upload depuis les bytes en mémoire → jamais de problème de cache
  Future<String> uploadPhoto() async {
    if (imageBytes == null) return defaultAvatarUrl;

    try {
      final uri = Uri.parse(
          "https://api.cloudinary.com/v1_1/dqlm7wqpp/image/upload");

      final request = http.MultipartRequest("POST", uri);
      request.fields["upload_preset"] = "dwaya_preset";
      request.files.add(
        http.MultipartFile.fromBytes(
          "file",
          imageBytes!, // ✅ Bytes en mémoire, pas de chemin fichier
          filename: "profile_${DateTime.now().millisecondsSinceEpoch}.jpg",
        ),
      );

      final response = await request.send();
      final body = await response.stream.bytesToString();
      final decoded = jsonDecode(body);

      if (decoded["secure_url"] != null) {
        print("☁️ CLOUDINARY URL = ${decoded["secure_url"]}");
        return decoded["secure_url"];
      }
      return defaultAvatarUrl;
    } catch (e) {
      print("❌ CLOUDINARY ERROR: $e");
      return defaultAvatarUrl;
    }
  }

  // 💾 Sauvegarder dans Firestore
  Future<void> saveToFirestore(String uid, String photoUrl) async {
    await FirebaseFirestore.instance.collection("users").doc(uid).set({
      "nom": nom.text.trim(),
      "prenom": prenom.text.trim(),
      "dateNaissance": selectedDate?.toIso8601String(),
      "email": email.text.trim(),
      "tel": "+216${tel.text.trim()}",
      "role": selectedRole,
      "sexe": sexe,
      "photoUrl": photoUrl,
      "doctorIds": [],
      "createdAt": DateTime.now(),
    });
  }

  // 🔐 Créer compte
  Future<void> signup() async {
    try {
      setState(() => isLoading = true);

      await FirebaseAuth.instance.signOut();

      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.text.trim(),
        password: pass.text.trim(),
      );

      final photoUrl = await uploadPhoto();

      await cred.user!.sendEmailVerification();
      await saveToFirestore(cred.user!.uid, photoUrl);

      setState(() => isLoading = false);

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Succès ✅"),
          content: const Text("Compte créé !\nVérifiez votre Gmail 📧"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text("OK"),
            )
          ],
        ),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => isLoading = false);
      String message = "Erreur";
      if (e.code == 'email-already-in-use') message = "Email déjà utilisé";
      else if (e.code == 'weak-password') message = "Mot de passe faible";
      else if (e.code == 'invalid-email') message = "Email invalide";
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  void validate() {
    final number = tel.text.trim();

    setState(() {
      errNom = nom.text.isEmpty ? "Nom obligatoire" : null;
      errPrenom = prenom.text.isEmpty ? "Prénom obligatoire" : null;
      errEmail = !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
              .hasMatch(email.text)
          ? "Email invalide"
          : null;
      errPass = pass.text.length < 8 ? "Min 8 caractères" : null;
      errTel = isTestNumber
          ? null
          : !RegExp(r'^(2|4|5|9)\d{7}$').hasMatch(number)
              ? "Numéro tunisien invalide"
              : null;
      errSexe = sexe == null ? "Choisir sexe" : null;
    });

    if (errNom == null &&
        errPrenom == null &&
        errEmail == null &&
        errPass == null &&
        errTel == null &&
        errSexe == null) {
      if (!phoneVerified) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("⚠️ Vérifiez votre numéro de téléphone d'abord"),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      signup();
    }
  }

  Widget medicalInput(
      TextEditingController c, String label, IconData icon,
      {String? err, bool password = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: c,
            obscureText: password ? obscure : false,
            decoration: InputDecoration(
              labelText: label,
              prefixIcon: Icon(icon, color: Colors.blue),
              suffixIcon: password
                  ? IconButton(
                      icon: Icon(
                          obscure ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => obscure = !obscure),
                    )
                  : null,
              filled: true,
              fillColor: Colors.blue.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          if (err != null)
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 4),
              child: Text(err,
                  style: const TextStyle(color: Colors.red, fontSize: 12)),
            ),
        ],
      ),
    );
  }

  Widget roleCard({
    required String title,
    required IconData icon,
    required String value,
    required Color color,
  }) {
    bool selected = selectedRole == value;
    return GestureDetector(
      onTap: () => setState(() => selectedRole = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.12) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? color : Colors.grey.shade300, width: 2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 15),
            Expanded(
                child: Text(title,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color))),
            Radio(
              value: value,
              groupValue: selectedRole,
              activeColor: color,
              onChanged: (v) => setState(() => selectedRole = v.toString()),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFEAF4FF), Color(0xFFF8FCFF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                        colors: [Colors.blue.shade400, Colors.green.shade300]),
                  ),
                  child: const Icon(Icons.local_hospital,
                      color: Colors.white, size: 45),
                ),
                const SizedBox(height: 20),
                const Text("Créer un compte",
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B3A57))),
                const SizedBox(height: 30),
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Column(
                    children: [
                      // 📸 Photo picker — affiche depuis les bytes en mémoire
                      GestureDetector(
                        onTap: pickImage,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 55,
                              backgroundColor: Colors.blue.shade50,
                              // ✅ Afficher depuis bytes en mémoire
                              backgroundImage: imageBytes != null
                                  ? MemoryImage(imageBytes!)
                                  : null,
                              child: imageBytes == null
                                  ? Icon(Icons.person,
                                      size: 50, color: Colors.blue.shade300)
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: imageBytes != null
                                      ? Colors.green
                                      : Colors.blue,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.camera_alt,
                                    color: Colors.white, size: 18),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        imageBytes != null
                            ? "✅ Photo sélectionnée"
                            : "Photo optionnelle (avatar par défaut)",
                        style: TextStyle(
                          color: imageBytes != null
                              ? Colors.green
                              : Colors.grey.shade500,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 16),

                      medicalInput(nom, "Nom", Icons.person_outline,
                          err: errNom),
                      medicalInput(prenom, "Prénom", Icons.person,
                          err: errPrenom),

                      // Date picker
                      GestureDetector(
                        onTap: pickDate,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 15),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 15, vertical: 18),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_month,
                                  color: Colors.blue),
                              const SizedBox(width: 12),
                              Text(
                                selectedDate == null
                                    ? "Date de naissance"
                                    : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
                              ),
                            ],
                          ),
                        ),
                      ),

                      medicalInput(email, "Email", Icons.email_outlined,
                          err: errEmail),
                      medicalInput(pass, "Mot de passe", Icons.lock_outline,
                          password: true, err: errPass),

                      // 📱 Téléphone + OTP
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: tel,
                                  keyboardType: TextInputType.phone,
                                  decoration: InputDecoration(
                                    labelText: "Téléphone",
                                    prefixText: "+216 ",
                                    prefixIcon: const Icon(Icons.phone),
                                    filled: true,
                                    fillColor: phoneVerified
                                        ? Colors.green.shade50
                                        : Colors.blue.shade50,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(18),
                                      borderSide: BorderSide.none,
                                    ),
                                    suffixIcon: phoneVerified
                                        ? const Icon(Icons.check_circle,
                                            color: Colors.green)
                                        : null,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: phoneVerified
                                      ? Colors.green
                                      : Colors.blue,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(14)),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 16),
                                ),
                                onPressed: phoneVerified
                                    ? null
                                    : (isSendingOtp ? null : sendOtp),
                                child: isSendingOtp
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white),
                                      )
                                    : Text(
                                        phoneVerified ? "✅" : "Envoyer",
                                        style: const TextStyle(
                                            color: Colors.white),
                                      ),
                              ),
                            ],
                          ),
                          if (errTel != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 8, top: 4),
                              child: Text(errTel!,
                                  style: const TextStyle(
                                      color: Colors.red, fontSize: 12)),
                            ),

                          if (phoneSent && !phoneVerified) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(18),
                                border:
                                    Border.all(color: Colors.blue.shade200),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    isTestNumber
                                        ? "🧪 Mode test — code : 123456"
                                        : "📩 Code SMS envoyé",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue),
                                  ),
                                  const SizedBox(height: 10),
                                  TextField(
                                    controller: otpController,
                                    keyboardType: TextInputType.number,
                                    maxLength: 6,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        fontSize: 24,
                                        letterSpacing: 8,
                                        fontWeight: FontWeight.bold),
                                    decoration: InputDecoration(
                                      hintText: "------",
                                      counterText: "",
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(14),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(14)),
                                      ),
                                      onPressed: verifyOtp,
                                      child: const Text(
                                        "Vérifier le code",
                                        style:
                                            TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          if (phoneVerified)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Row(
                                children: const [
                                  Icon(Icons.check_circle,
                                      color: Colors.green, size: 16),
                                  SizedBox(width: 6),
                                  Text("Numéro vérifié ✅",
                                      style: TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 15),

                      // Sexe
                      DropdownButtonFormField<String>(
                        value: sexe,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.blue.shade50,
                          prefixIcon: const Icon(Icons.people),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        hint: const Text("Sexe"),
                        items: const [
                          DropdownMenuItem(
                              value: "Homme", child: Text("Homme")),
                          DropdownMenuItem(
                              value: "Femme", child: Text("Femme")),
                        ],
                        onChanged: (value) => setState(() => sexe = value),
                      ),
                      if (errSexe != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 8, top: 4),
                          child: Text(errSexe!,
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 12)),
                        ),

                      const SizedBox(height: 25),

                      roleCard(
                          title: "Patient",
                          icon: Icons.person,
                          value: "patient",
                          color: Colors.green),
                      roleCard(
                          title: "Docteur",
                          icon: Icons.local_hospital,
                          value: "docteur",
                          color: Colors.blue),
                      roleCard(
                          title: "Famille",
                          icon: Icons.family_restroom,
                          value: "famille",
                          color: Colors.orange),

                      const SizedBox(height: 30),

                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18)),
                          ),
                          onPressed: isLoading ? null : validate,
                          child: isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Text("Créer un compte",
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white)),
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