import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../pages/doctor/doctor_home.dart';
import '../pages/doctor/add_patient_page.dart';
import '../pages/doctor/doctor_rendezvous_page.dart';
import '../pages/doctor/doctor_notifications_page.dart';
import '../pages/doctor/doctor_profile_page.dart';
import '../pages/auth/login_page.dart';

class DoctorNavBar extends StatefulWidget {
  const DoctorNavBar({super.key});

  @override
  State<DoctorNavBar> createState() => _DoctorNavBarState();
}

class _DoctorNavBarState extends State<DoctorNavBar> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const DoctorHome(),
    const AddPatientPage(),
    const DoctorRendezVousPage(),
    const DoctorNotificationsPage(),
    const DoctorProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: Colors.blue,
            unselectedItemColor: Colors.grey.shade400,
            selectedFontSize: 12,
            unselectedFontSize: 11,
            elevation: 0,
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: "Accueil",
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.person_add_outlined),
                activeIcon: Icon(Icons.person_add),
                label: "Patients",
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.calendar_today_outlined),
                activeIcon: Icon(Icons.calendar_today),
                label: "Rendez-vous",
              ),
              BottomNavigationBarItem(
                icon: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection("doctor_notifications")
                      .where("read", isEqualTo: false)
                      .snapshots(),
                  builder: (context, snapshot) {
                    int count = snapshot.data?.docs.length ?? 0;
                    return Stack(
  children: [
    const Icon(Icons.notifications_outlined),

    if (count > 0)
      Positioned(
        right: 0,
        top: 0,
        child: Container(
          padding: const EdgeInsets.all(4),

          decoration: const BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
          ),

          constraints: const BoxConstraints(
            minWidth: 18,
            minHeight: 18,
          ),

          child: Text(
            count.toString(),

            textAlign: TextAlign.center,

            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
  ],
);
                  },
                ),
                activeIcon: const Icon(Icons.notifications),
                label: "Alertes",
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.account_circle_outlined),
                activeIcon: Icon(Icons.account_circle),
                label: "Profil",
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================
// Page Profil Docteur
// ============================================
class DoctorProfilePage extends StatefulWidget {
  const DoctorProfilePage({super.key});
  @override
  State<DoctorProfilePage> createState() => _DoctorProfilePageState();
}

class _DoctorProfilePageState extends State<DoctorProfilePage> {
  Map<String, dynamic>? doctorData;
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
    setState(() => doctorData = doc.data());
  }

  Future<void> pickAndUploadPhoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (picked == null) return;

    setState(() {
      isUploadingPhoto = true;
    });

    final photoUrl = await uploadToCloudinary(File(picked.path));

    if (photoUrl != null) {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .update({"photoUrl": photoUrl});
      await loadDoctor();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Impossible de charger la photo"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() {
      isUploadingPhoto = false;
    });
  }

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

      return decoded["secure_url"] as String?;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur Cloudinary: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
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
Future<void> showEditProfileDialog() async {
  final nom = TextEditingController(text: doctorData?["nom"]);
  final prenom = TextEditingController(text: doctorData?["prenom"]);
  final email = TextEditingController(text: doctorData?["email"]);
  final telephone = TextEditingController(text: doctorData?["tel"]);

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text(
        "✏️ Modifier mon profil",
        style: TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),

      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            _buildEditTextField(
              nom,
              "Nom",
              Icons.person,
            ),

            _buildEditTextField(
              prenom,
              "Prénom",
              Icons.badge,
            ),

            _buildEditTextField(
              email,
              "Email",
              Icons.email,
            ),

            _buildEditTextField(
              telephone,
              "Téléphone",
              Icons.phone,
            ),
          ],
        ),
      ),

      actions: [

        TextButton(
          onPressed: () =>
              Navigator.pop(context),

          child: const Text(
            "Annuler",
          ),
        ),

        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
          ),

          onPressed: () async {

            if (nom.text.isEmpty ||
                prenom.text.isEmpty ||
                email.text.isEmpty) {

              ScaffoldMessenger.of(context)
                  .showSnackBar(

                const SnackBar(
                  content: Text(
                    "⚠️ Veuillez remplir tous les champs",
                  ),
                ),
              );

              return;
            }

            final uid =
                FirebaseAuth.instance
                    .currentUser!
                    .uid;

            await FirebaseFirestore
                .instance
                .collection("users")
                .doc(uid)
                .update({

              "nom":
                  nom.text.trim(),

              "prenom":
                  prenom.text.trim(),

              "email":
                  email.text.trim(),

              "tel":
                  telephone.text.trim(),
            });

            await loadDoctor();

            Navigator.pop(context);

            ScaffoldMessenger.of(context)
                .showSnackBar(

              const SnackBar(
                content: Text(
                  "✅ Profil mis à jour avec succès",
                ),
              ),
            );
          },

          child: const Text(
            "Enregistrer",
            style: TextStyle(
              color: Colors.white,
            ),
          ),
        ),
      ],
    ),
  );
}
Future<void> confirmDeleteAccount() async {

  showDialog(
    context: context,

    builder: (_) => AlertDialog(

      title: const Text(
        "⚠️ Confirmation",
      ),

      content: const Text(
        "Voulez-vous supprimer le compte ?",
      ),

      actions: [

        TextButton(
          onPressed: () =>
              Navigator.pop(context),

          child: const Text(
            "Annuler",
          ),
        ),

        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
          ),

          onPressed: () async {

            try {

              final uid =
                  FirebaseAuth.instance
                      .currentUser!
                      .uid;

              await FirebaseFirestore
                  .instance
                  .collection("users")
                  .doc(uid)
                  .delete();

              await FirebaseAuth
                  .instance
                  .currentUser
                  ?.delete();

              if (!mounted) return;

              Navigator.pop(context);

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const LoginPage(),
                ),
                (route) => false,
              );

            } catch (e) {

              ScaffoldMessenger.of(context)
                  .showSnackBar(

                SnackBar(
                  content: Text(
                    "❌ Erreur : $e",
                  ),
                ),
              );
            }
          },

          child: const Text(
            "Supprimer",
            style: TextStyle(
              color: Colors.white,
            ),
          ),
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

      body: doctorData == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Avatar
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.blue.shade200,
                        backgroundImage: doctorData?['photoUrl'] != null
                            ? NetworkImage(doctorData!['photoUrl'])
                                as ImageProvider
                            : null,
                        child: doctorData?['photoUrl'] == null
                            ? const Icon(Icons.medical_services,
                                color: Colors.white, size: 60)
                            : null,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: GestureDetector(
                          onTap: pickAndUploadPhoto,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(8),
                            child: isUploadingPhoto
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(
                                    Icons.camera_alt,
                                    size: 20,
                                    color: Colors.blue,
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Dr. ${doctorData?['nom'] ?? ''} ${doctorData?['prenom'] ?? ''}",
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    doctorData?['email'] ?? '',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 30),
                  _infoCard(Icons.email, "Email", doctorData?['email'] ?? '',
                      Colors.blue),
                  _infoCard(Icons.phone, "Téléphone", doctorData?['tel'] ?? '',
                      Colors.green),
                  _infoCard(Icons.wc, "Sexe", doctorData?['sexe'] ?? '',
                      Colors.orange),
                  const SizedBox(height: 30),
                  // Logout
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade400,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      icon: const Icon(Icons.logout, color: Colors.white),
                      label: const Text("Déconnexion",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
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

            if (!mounted) return;

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
    );
  }

  Widget _infoCard(IconData icon, String title, String value, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
              Text(value,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
            ],
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
    padding: const EdgeInsets.only(
      bottom: 12,
    ),

    child: TextField(
      controller: controller,

      decoration: InputDecoration(
        labelText: label,

        prefixIcon: Icon(icon),

        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(10),
        ),
      ),
    ),
  );
}
}
