import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
class FamilyProfilePage extends StatefulWidget {
  const FamilyProfilePage({super.key});

  @override
  State<FamilyProfilePage> createState() =>
      _FamilyProfilePageState();
}

class _FamilyProfilePageState
    extends State<FamilyProfilePage> {
      Map<String, dynamic>? familyData;
File? newImage;
@override
void initState() {
  super.initState();
  loadFamily();
}

Future<void> loadFamily() async {
  final uid = FirebaseAuth.instance.currentUser!.uid;

  final doc = await FirebaseFirestore.instance
      .collection("users")
      .doc(uid)
      .get();

  if (mounted) {
    setState(() {
      familyData = doc.data();
    });
  }
}
ImageProvider? _getProfileImage() {

  if (newImage != null) {
    return FileImage(newImage!);
  }

  final url = familyData?["photoUrl"];

  if (url != null && url.toString().isNotEmpty) {
    return NetworkImage(url);
  }

  return null;
}
Future<void> pickAndUploadPhoto() async {

  final picked = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    imageQuality: 70,
  );

  if (picked == null) return;

  setState(() {
    newImage = File(picked.path);
  });

  final photoUrl =
      await uploadToCloudinary(newImage!);

  if (photoUrl != null) {

    final uid =
        FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .update({
      "photoUrl": photoUrl,
    });

    loadFamily();
  }
}
Future<String?> uploadToCloudinary(File image) async {
  try {
    final uri = Uri.parse(
      "https://api.cloudinary.com/v1_1/dqlm7wqpp/image/upload",
    );

    final request = http.MultipartRequest(
      "POST",
      uri,
    );

    request.fields["upload_preset"] =
        "dwaya_preset";

    request.files.add(
      await http.MultipartFile.fromPath(
        "file",
        image.path,
      ),
    );

    final response = await request.send();

    final body =
        await response.stream.bytesToString();

    final decoded = jsonDecode(body);

    return decoded["secure_url"];

  } catch (e) {
    return null;
  }
}
Future<void> confirmLogout() async {
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

  Navigator.of(context).pop();

  await FirebaseAuth.instance.signOut();

  if (!mounted) return;

  Navigator.pushNamedAndRemoveUntil(
    context,
    '/',
    (route) => false,
  );
},

          child: const Text(
            "Déconnexion",
            style: TextStyle(color: Colors.redAccent),
          ),
        ),
      ],
    ),
  );
}
Future<void> showEditProfileDialog() async {

  final nom = TextEditingController(
    text: familyData?["nom"] ?? "",
  );

  final prenom = TextEditingController(
    text: familyData?["prenom"] ?? "",
  );

  final email = TextEditingController(
    text: familyData?["email"] ?? "",
  );

  final telephone = TextEditingController(
    text: familyData?["telephone"] ?? "",
  );

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("✏️ Modifier profil"),

      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            TextField(
              controller: nom,
              decoration: const InputDecoration(
                labelText: "Nom",
                prefixIcon: Icon(Icons.person),
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: prenom,
              decoration: const InputDecoration(
                labelText: "Prénom",
                prefixIcon: Icon(Icons.badge),
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: email,
              decoration: const InputDecoration(
                labelText: "Email",
                prefixIcon: Icon(Icons.email),
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: telephone,
              decoration: const InputDecoration(
                labelText: "Téléphone",
                prefixIcon: Icon(Icons.phone),
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
           style: ElevatedButton.styleFrom(
  backgroundColor: Colors.green,
  foregroundColor: Colors.white,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(20),
  ),
),
          onPressed: () async {
           

            final uid =
                FirebaseAuth.instance.currentUser!.uid;

            await FirebaseFirestore.instance
                .collection("users")
                .doc(uid)
                .update({
              "nom": nom.text.trim(),
              "prenom": prenom.text.trim(),
              "email": email.text.trim(),
              "telephone": telephone.text.trim(),
            });

            Navigator.pop(context);

            loadFamily();
          },
          child: const Text("Enregistrer"),
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
        title: const Text("🔐 Changer le mot de passe"),

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
                    icon: Icon(
                      obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        obscurePassword = !obscurePassword;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 10),

              TextField(
                controller: newPasswordController,
                obscureText: obscureNewPassword,
                decoration: InputDecoration(
                  labelText: "Nouveau mot de passe",
                  prefixIcon: const Icon(Icons.lock_open),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureNewPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        obscureNewPassword =
                            !obscureNewPassword;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 10),

              TextField(
                controller: confirmPasswordController,
                obscureText: obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: "Confirmer mot de passe",
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        obscureConfirmPassword =
                            !obscureConfirmPassword;
                      });
                    },
                  ),
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
            style: ElevatedButton.styleFrom(
  backgroundColor: Colors.green,
  foregroundColor: Colors.white,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(20),
  ),
),
            onPressed: () async {

              if (newPasswordController.text !=
                  confirmPasswordController.text) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Les mots de passe ne correspondent pas",
                    ),
                  ),
                );
                return;
              }

              try {

                final user =
                    FirebaseAuth.instance.currentUser!;

                final credential =
                    EmailAuthProvider.credential(
                  email: user.email!,
                  password: passwordController.text,
                );

                await user
                    .reauthenticateWithCredential(
                        credential);

                await user.updatePassword(
                  newPasswordController.text,
                );

                Navigator.pop(context);

                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Mot de passe changé avec succès",
                    ),
                  ),
                );

              } catch (e) {

                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  SnackBar(
                    content: Text("Erreur : $e"),
                  ),
                );
              }
            },
            child: const Text("Mettre à jour"),
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
      content: const Text(
        "Voulez-vous vraiment supprimer votre compte ?",
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

            final uid =
                FirebaseAuth.instance.currentUser!.uid;

            await FirebaseFirestore.instance
                .collection("users")
                .doc(uid)
                .delete();

            await FirebaseAuth.instance.currentUser
                ?.delete();

            Navigator.pop(context);

          },
          child: const Text(
            "Supprimer",
            style: TextStyle(
              color: Colors.red,
            ),
          ),
        ),
      ],
    ),
  );
}
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),
    appBar: AppBar(
  backgroundColor: const Color(0xFFF5F8FF),
  elevation: 0,
  title: const Text(
    "Profil Famille 👨‍👩‍👧",
    style: TextStyle(
      color: Colors.black,
    ),
  ),


  actions: [
   PopupMenuButton<String>(
  icon: const Icon(Icons.menu),
      onSelected: (value) {

        if (value == "modifier") {
           showEditProfileDialog();
        }

        if (value == "password") {
           showChangePasswordDialog();
        }
if (value == "supprimer") {
  confirmDeleteAccount();
}
        
      },

      itemBuilder: (context) => [

        const PopupMenuItem(
          value: "modifier",
          child: Row(
            children: [
              Icon(Icons.edit),
              SizedBox(width: 10),
              Text("Modifier profil"),
            ],
          ),
        ),

        const PopupMenuItem(
          value: "password",
          child: Row(
            children: [
              Icon(Icons.lock),
              SizedBox(width: 10),
              Text("Changer mot de passe"),
            ],
          ),
        ),
        const PopupMenuItem(
  value: "supprimer",
  child: Row(
    children: [
      Icon(Icons.delete, color: Colors.red),
      SizedBox(width: 10),
      Text("Supprimer profil"),
    ],
  ),
),

       
      ],
    ),
  ],
),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection("users")
            .doc(uid)
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
  child: Padding(
    padding: const EdgeInsets.all(20),
    child: Column(
              children: [

                GestureDetector(
  onTap: pickAndUploadPhoto,

  child: Stack(
    children: [

      CircleAvatar(
        radius: 55,
        backgroundColor: Colors.blue.shade100,
        backgroundImage: _getProfileImage(),

        child: _getProfileImage() == null
            ? const Icon(
                Icons.person,
                size: 60,
                color: Colors.white,
              )
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
          child: const Icon(
            Icons.camera_alt,
            color: Colors.white,
            size: 16,
          ),
        ),
      ),
    ],
  ),
),
    
const SizedBox(height: 10),

Text(
  "${data["nom"]} ${data["prenom"]}",
  style: const TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: Color(0xFF22304A),
  ),
),

                const SizedBox(height: 20),

                buildInfoTile(
                  Icons.person,
                  "Nom",
                  data["nom"] ?? "",
                  Colors.blue,
                ),

                buildInfoTile(
                  Icons.person_outline,
                  "Prénom",
                  data["prenom"] ?? "",
                  Colors.indigo,
                ),

                buildInfoTile(
                  Icons.email,
                  "Email",
                  data["email"] ?? "",
                  Colors.orange,
                ),

                buildInfoTile(
                  Icons.phone,
                  "Téléphone",
                  data["telephone"] ?? "",
                  Colors.green,
                ),

                buildInfoTile(
                  Icons.wc,
                  "Sexe",
                  data["sexe"] ?? "",
                  Colors.teal,
                ),
                const SizedBox(height: 20),

SizedBox(
  width: double.infinity,
  height: 50,
  child: ElevatedButton.icon(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.red,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
    ),
    icon: const Icon(
      Icons.logout,
      color: Colors.white,
    ),
    label: const Text(
      "Déconnexion",
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    ),
    onPressed: () {
      confirmLogout();
    },
  ),
),
              ],
            ),
  ),
          );
        },
      ),
    );
  }
Widget buildInfoTile(
  IconData icon,
  String title,
  String value,
  Color color,
)
   {
  return Container(
    margin: const EdgeInsets.symmetric(
      horizontal: 5,
      vertical: 8,
    ),

    padding: const EdgeInsets.all(18),

    decoration: BoxDecoration(
      color: Colors.white,

      borderRadius: BorderRadius.circular(20),

      boxShadow: [
  BoxShadow(
    color: color.withOpacity(0.15),
    blurRadius: 10,
    offset: const Offset(0, 5),
  ),
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

          child: Icon(
            icon,
            color: color,
            size: 28,
          ),
        ),

        const SizedBox(width: 15),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [

              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 5),

              Text(
  value,
  maxLines: 2,
  overflow: TextOverflow.ellipsis,
  style: const TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.bold,
  ),
),
            ],
          ),
        ),
      ],
    ),
  );
}
    }