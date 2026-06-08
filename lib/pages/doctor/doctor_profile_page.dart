import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../auth/login_page.dart';

class DoctorProfilePage extends StatefulWidget {
  const DoctorProfilePage({super.key});

  @override
  State<DoctorProfilePage> createState() => _DoctorProfilePageState();
}

class _DoctorProfilePageState extends State<DoctorProfilePage> {
  Map<String, dynamic>? doctorData;
  File? newImage;
  bool isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    loadDoctor();
  }

  Future<void> loadDoctor() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc =
        await FirebaseFirestore.instance.collection("users").doc(uid).get();
    if (mounted) setState(() => doctorData = doc.data());
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
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .update({"photoUrl": photoUrl});
      await loadDoctor();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Photo mise à jour")),
        );
      }
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Erreur upload: $e")),
        );
      }
      return null;
    }
  }

  Future<void> showEditProfileDialog() async {
    final nom = TextEditingController(text: doctorData?["nom"]);
    final prenom = TextEditingController(text: doctorData?["prenom"]);
    final email = TextEditingController(text: doctorData?["email"]);
    final telephone = TextEditingController(text: doctorData?["tel"]);
    final specialite =
        TextEditingController(text: doctorData?["specialite"] ?? "");
    final numeroLicense =
        TextEditingController(text: doctorData?["numeroLicense"] ?? "");

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("✏️ Modifier mon profil",
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(nom, "Nom", Icons.person),
              _buildTextField(prenom, "Prénom", Icons.badge),
              _buildTextField(email, "Email", Icons.email),
              _buildTextField(telephone, "Téléphone", Icons.phone),
              _buildTextField(specialite, "Spécialité", Icons.medical_services),
              _buildTextField(
                  numeroLicense, "N° de license", Icons.card_membership),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
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

              final uid = FirebaseAuth.instance.currentUser!.uid;
              await FirebaseFirestore.instance
                  .collection("users")
                  .doc(uid)
                  .update({
                "nom": nom.text.trim(),
                "prenom": prenom.text.trim(),
                "email": email.text.trim(),
                "tel": telephone.text.trim(),
                "specialite": specialite.text.trim(),
                "numeroLicense": numeroLicense.text.trim(),
              });

              await loadDoctor();
              Navigator.pop(context);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text("✅ Profil mis à jour avec succès")),
                );
              }
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
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
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
        title: const Text("⚠️ Suppression du compte"),
        content: const Text(
          "Cette action est irréversible. Tous vos données seront supprimées.",
          style: TextStyle(color: Colors.red),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                final uid = FirebaseAuth.instance.currentUser!.uid;
                await FirebaseFirestore.instance
                    .collection("users")
                    .doc(uid)
                    .delete();
                await FirebaseAuth.instance.currentUser?.delete();

                Navigator.pop(context);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("❌ Erreur: $e")),
                  );
                }
              }
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
  backgroundColor: Colors.white,
  foregroundColor: const Color(0xFF22304A),
  elevation: 0,

  title: const Text("Mon Profil 👨‍⚕️"),

  actions: [
          PopupMenuButton<String>(

 
    icon: const Icon(Icons.menu),

  
            onSelected: (value) {
              if (value == "modifier")
                showEditProfileDialog();
              else if (value == "password")
                showChangePasswordDialog();
              else if (value == "delete") confirmDeleteAccount();
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
                value: "delete",
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
      body: doctorData == null
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
                          radius: 60,
                          backgroundColor: Colors.blue.shade100,
                          backgroundImage: _getProfileImage(),
                          child: _getProfileImage() == null
                              ? const Icon(Icons.person,
                                  size: 65, color: Colors.blue)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              
                              shape: BoxShape.circle,
                            ),
                            child: isUploadingPhoto
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.camera_alt,
                                    color: Colors.white, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),
                  Text(
                    "Dr. ${doctorData?["nom"] ?? ""} ${doctorData?["prenom"] ?? ""}",
                    style: const TextStyle(
  fontSize: 28,
  fontWeight: FontWeight.bold,
  color: Color(0xFF22304A),
),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    doctorData?["specialite"] ?? "Médecin",
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 25),

                  // ℹ️ INFO CARDS
                  _buildInfoCard(
                    icon: Icons.email,
                    title: "Email",
                    value: doctorData?["email"] ?? "",
                    color: Colors.blue,
                  ),
                  _buildInfoCard(
                    icon: Icons.phone,
                    title: "Téléphone",
                    value: doctorData?["tel"] ?? "Non disponible",
                    color: Colors.green,
                  ),
                  _buildInfoCard(
                    icon: Icons.medical_services,
                    title: "Spécialité",
                    value: doctorData?["specialite"] ?? "Non disponible",
                    color: Colors.purple,
                  ),
                  _buildInfoCard(
                    icon: Icons.card_membership,
                    title: "N° License",
                    value: doctorData?["numeroLicense"] ?? "Non disponible",
                    color: Colors.orange,
                  ),

                  const SizedBox(height: 25),

                  // 🔘 BOUTONS D'ACTION
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.edit, color: Colors.white),
                            label: const Text("Modifier Profil",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 16)),
                            onPressed: showEditProfileDialog,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.lock, color: Colors.white),
                            label: const Text("Changer Mot de Passe",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 16)),
                            onPressed: showChangePasswordDialog,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
  backgroundColor: const Color(0xFFE57373),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
),
                            icon: const Icon(Icons.logout, color: Colors.white),
                            label: const Text("Déconnexion",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 16)),
                           onPressed: () {

  showDialog(
    context: context,

    builder: (_) => AlertDialog(

      title: const Text("Confirmation"),

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
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  // ✅ Helper pour image
  ImageProvider? _getProfileImage() {
    if (newImage != null) return FileImage(newImage!);
    final url = doctorData?["photoUrl"];
    if (url != null && url.toString().isNotEmpty) {
      return NetworkImage(url);
    }
    return null;
  }

  Widget _buildTextField(
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

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
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
                        TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                const SizedBox(height: 4),
                Text(value,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
