import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../auth/login_page.dart';

class PatientProfilePage extends StatefulWidget {
  final String patientId;
  const PatientProfilePage({super.key, required this.patientId});

  @override
  State<PatientProfilePage> createState() => _PatientProfilePageState();
}

class _PatientProfilePageState extends State<PatientProfilePage> {
  Map<String, dynamic>? patientData;
  File? newImage;
  bool isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    loadPatient();
  }

  Future<void> loadPatient() async {
    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(widget.patientId)
        .get();
    if (mounted) setState(() => patientData = doc.data());
  }

  int calculateAge(String birthDate) {
    DateTime birth = DateTime.parse(birthDate);
    DateTime today = DateTime.now();
    int age = today.year - birth.year;
    if (today.month < birth.month ||
        (today.month == birth.month && today.day < birth.day)) age--;
    return age;
  }

  // 📸 Choisir nouvelle photo
  Future<void> pickAndUploadPhoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (picked == null) return;

    setState(() {
      newImage = File(picked.path);
      isUploadingPhoto = true;
    });

    final photoUrl = await uploadToCloudinary(newImage!);

    if (photoUrl != null) {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(widget.patientId)
          .update({"photoUrl": photoUrl});
      await loadPatient();
    }

    setState(() => isUploadingPhoto = false);
  }

  // ☁️ Upload Cloudinary
  Future<String?> uploadToCloudinary(File image) async {
    try {
      final uri =
          Uri.parse("https://api.cloudinary.com/v1_1/dqlm7wqpp/image/upload");
      final request = http.MultipartRequest("POST", uri);
      request.fields["upload_preset"] = "dwaya_preset";
      request.files.add(await http.MultipartFile.fromPath("file", image.path));
      final response = await request.send();
      final body = await response.stream.bytesToString();
      final decoded = jsonDecode(body);
      return decoded["secure_url"];
    } catch (e) {
      print("CLOUDINARY ERROR: $e");
      return null;
    }
  }

  Future<void> showEditProfileDialog() async {
    final nom = TextEditingController(text: patientData?["nom"]);
    final prenom = TextEditingController(text: patientData?["prenom"]);
    final email = TextEditingController(text: patientData?["email"]);
    final telephone = TextEditingController(text: patientData?["tel"]);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("✏️ Modifier mon profil",
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildEditTextField(nom, "Nom", Icons.person),
              _buildEditTextField(prenom, "Prénom", Icons.badge),
              _buildEditTextField(email, "Email", Icons.email),
              _buildEditTextField(telephone, "Téléphone", Icons.phone),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () async {
              if (nom.text.isEmpty ||
                  prenom.text.isEmpty ||
                  email.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text("⚠️ Veuillez remplir tous les champs")),
                );
                return;
              }

              await FirebaseFirestore.instance
                  .collection("users")
                  .doc(widget.patientId)
                  .update({
                "nom": nom.text.trim(),
                "prenom": prenom.text.trim(),
                "email": email.text.trim(),
                "tel": telephone.text.trim(),
              });

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text("✅ Profil mis à jour avec succès")));
              loadPatient();
            },
            child: const Text("Enregistrer",
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> showChangePasswordDialog() async {
    final passwordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscurePassword = true;
    bool obscureNewPassword = true;
    bool obscureConfirmPassword = true;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("🔐 Changer le mot de passe",
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  decoration: InputDecoration(
                    labelText: "Mot de passe actuel",
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () =>
                          setState(() => obscurePassword = !obscurePassword),
                    ),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newPasswordController,
                  obscureText: obscureNewPassword,
                  decoration: InputDecoration(
                    labelText: "Nouveau mot de passe",
                    prefixIcon: const Icon(Icons.lock_open),
                    suffixIcon: IconButton(
                      icon: Icon(obscureNewPassword
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () => setState(
                          () => obscureNewPassword = !obscureNewPassword),
                    ),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: "Confirmer mot de passe",
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(obscureConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () => setState(() =>
                          obscureConfirmPassword = !obscureConfirmPassword),
                    ),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annuler"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () async {
                if (passwordController.text.isEmpty ||
                    newPasswordController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("⚠️ Tous les champs sont requis")),
                  );
                  return;
                }

                if (newPasswordController.text !=
                    confirmPasswordController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                            Text("❌ Les mots de passe ne correspondent pas")),
                  );
                  return;
                }

                try {
                  final user = FirebaseAuth.instance.currentUser!;
                  final credential = EmailAuthProvider.credential(
                    email: user.email!,
                    password: passwordController.text,
                  );

                  await user.reauthenticateWithCredential(credential);
                  await user.updatePassword(newPasswordController.text);

                  Navigator.pop(context);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("✅ Mot de passe changé avec succès")),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("❌ Erreur: ${e.toString()}")),
                    );
                  }
                }
              },
              child: const Text("Mettre à jour",
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> confirmDeleteAccount() async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("⚠️ Confirmation"),
        content: const Text("Voulez-vous supprimer le compte ?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annuler")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection("users")
                  .doc(widget.patientId)
                  .delete();
              await FirebaseAuth.instance.currentUser?.delete();
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
            child:
                const Text("Supprimer", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),
      appBar: AppBar(
        title: const Text("Profil Patient 👤"),
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu),
            onSelected: (value) {
              if (value == "modifier")
                showEditProfileDialog();
              else if (value == "password")
                showChangePasswordDialog();
              else if (value == "supprimer") confirmDeleteAccount();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: "modifier",
                child: Row(children: [
                  Icon(Icons.edit),
                  SizedBox(width: 10),
                  Text("Modifier profil")
                ]),
              ),
              const PopupMenuItem(
                value: "password",
                child: Row(children: [
                  Icon(Icons.lock),
                  SizedBox(width: 10),
                  Text("Changer mot de passe")
                ]),
              ),
              const PopupMenuItem(
                value: "supprimer",
                child: Row(children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 10),
                  Text("Supprimer compte")
                ]),
              ),
            ],
          ),
        ],
      ),
      body: patientData == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 25),

                  // 📸 PHOTO
                  GestureDetector(
                    onTap: pickAndUploadPhoto,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 55,
                          backgroundColor: Colors.blue.shade100,
                          backgroundImage: _getProfileImage(),
                          child: _getProfileImage() == null
                              ? const Icon(Icons.person,
                                  size: 60, color: Colors.white)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                            child: isUploadingPhoto
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.camera_alt,
                                    color: Colors.white, size: 16),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),
                  Text(
                    "${patientData?["nom"] ?? ""} ${patientData?["prenom"] ?? ""}",
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  buildInfoCard(
                      icon: Icons.person,
                      title: "Nom",
                      value: patientData?["nom"] ?? "",
                      color: Colors.blue),
                  buildInfoCard(
                      icon: Icons.badge,
                      title: "Prénom",
                      value: patientData?["prenom"] ?? "",
                      color: Colors.indigo),
                  buildInfoCard(
                      icon: Icons.calendar_month,
                      title: "Date de naissance",
                      value: patientData?["dateNaissance"] != null
                          ? patientData!["dateNaissance"]
                              .toString()
                              .split("T")[0]
                          : "Non disponible",
                      color: Colors.purple),
                  buildInfoCard(
                      icon: Icons.cake,
                      title: "Âge",
                      value: patientData?["dateNaissance"] != null
                          ? "${calculateAge(patientData!["dateNaissance"])} ans"
                          : "Non disponible",
                      color: Colors.orange),
                  buildInfoCard(
                      icon: Icons.email,
                      title: "Email",
                      value: patientData?["email"] ?? "",
                      color: Colors.orange),
                  buildInfoCard(
                      icon: Icons.phone,
                      title: "Téléphone",
                      value: patientData?["tel"] ?? "Non disponible",
                      color: Colors.green),
                  buildInfoCard(
                      icon: Icons.wc,
                      title: "Sexe",
                      value: patientData?["sexe"] ?? "Non disponible",
                      color: Colors.teal),

                  const SizedBox(height: 20),

                  // 🚪 DÉCONNEXION
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15)),
                        ),
                        icon: const Icon(Icons.logout, color: Colors.white),
                        label: const Text("Déconnexion",
                            style: TextStyle(color: Colors.white)),
                        onPressed: () {

  showDialog(
    context: context,

    builder: (_) => AlertDialog(

      title: const Text(
        "Confirmation",
      ),

      content: const Text(
        "Voulez-vous vraiment vous déconnecter ?",
      ),

      actions: [

        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text("Annuler"),
        ),

        TextButton(
          onPressed: () async {

            Navigator.pop(context);

            await FirebaseAuth.instance.signOut();

            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (_) => const LoginPage(),
              ),
              (route) => false,
            );
          },

          child: const Text(
            "Déconnexion",
            style: TextStyle(
              color: Colors.red,
            ),
          ),
        ),
      ],
    ),
  );
},
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  // ✅ Helper pour image
  ImageProvider? _getProfileImage() {
    if (newImage != null) return FileImage(newImage!);
    final url = patientData?["photoUrl"];
    if (url != null && url.toString().isNotEmpty) {
      return NetworkImage(url);
    }
    return null;
  }

  Widget buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 5)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style:
                        TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                const SizedBox(height: 5),
                Text(value,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditTextField(
    TextEditingController controller,
    String label,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}
