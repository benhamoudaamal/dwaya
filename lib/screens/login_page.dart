/*import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, Map<String, String>> translations = {
  "fr": {
    "welcome": "Bienvenue 👩‍⚕️",
    "login": "Connexion",
    "email": "Email",
    "password": "Mot de passe",
    "remember": "Se souvenir de moi",
    "create": "Créer un compte",
  },
  "en": {
    "welcome": "Welcome 👩‍⚕️",
    "login": "Login",
    "email": "Email",
    "password": "Password",
    "remember": "Remember me",
    "create": "Create account",
  },
  "ar": {
    "welcome": "مرحبا 👩‍⚕️",
    "login": "تسجيل الدخول",
    "email": "البريد الإلكتروني",
    "password": "كلمة المرور",
    "remember": "تذكرني",
    "create": "إنشاء حساب",
  },
};

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final pass = TextEditingController();

  bool obscure = true;
  bool remember = false;
  bool isLoading = false;
  String lang = "fr";

  String t(String key) => translations[lang]![key]!;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F8),

      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),

          child: SingleChildScrollView(
            child: Column(
              children: [

                // 🟢 HEADER MEDICAL
                Container(
                  height: 220,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF00C9A7),
                        Color(0xFF92FE9D),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.local_hospital,
                            size: 60, color: Colors.white),
                        const SizedBox(height: 10),
                        Text(
                          t("welcome"),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // 🟢 CARD FORM
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        )
                      ],
                    ),
                    child: Column(
                      children: [

                        // EMAIL
                        TextField(
                          controller: email,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.email, color: Colors.teal),
                            labelText: t("email"),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),

                        const SizedBox(height: 15),

                        // PASSWORD
                        TextField(
                          controller: pass,
                          obscureText: obscure,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.lock, color: Colors.teal),
                            labelText: t("password"),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscure
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() => obscure = !obscure);
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // REMEMBER
                        Row(
                          children: [
                            Checkbox(
                              value: remember,
                              activeColor: Colors.teal,
                              onChanged: (v) =>
                                  setState(() => remember = v!),
                            ),
                            Text(t("remember")),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // LOGIN BUTTON
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00C9A7),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            onPressed: () {},
                            child: isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : Text(
                                    t("login"),
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // SIGNUP
                        TextButton(
                          onPressed: () {},
                          child: Text(
                            t("create"),
                            style: const TextStyle(color: Colors.teal),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}*/

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, Map<String, String>> translations = {
  "fr": {
    "welcome": "Bienvenue 👩‍⚕️",
    "login": "Connexion",
    "email": "Email",
    "password": "Mot de passe",
    "remember": "Se souvenir de moi",
    "create": "Créer un compte",
  },
  "en": {
    "welcome": "Welcome 👩‍⚕️",
    "login": "Login",
    "email": "Email",
    "password": "Password",
    "remember": "Remember me",
    "create": "Create account",
  },
  "ar": {
    "welcome": "مرحبا 👩‍⚕️",
    "login": "تسجيل الدخول",
    "email": "البريد الإلكتروني",
    "password": "كلمة المرور",
    "remember": "تذكرني",
    "create": "إنشاء حساب",
  },
};

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final pass = TextEditingController();

  bool obscure = true;
  bool remember = false;
  bool isLoading = false;
  String lang = "fr";

  String t(String key) => translations[lang]![key]!;

  @override
  Widget build(BuildContext context) {
    print("login page FROM login_paga.dart IS BULDING"); 
    return Scaffold(
      backgroundColor: Colors.green,

      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),

          child: SingleChildScrollView(
            child: Column(
              children: [

                // 🌊 HEADER MODERNE MEDICAL
                Container(
                  height: 260,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF0EA5E9),
                        Color(0xFF14B8A6),
                      ],
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
                      const Icon(
                        Icons.local_hospital,
                        size: 70,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        t("welcome"),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "Medical Secure Access",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // 🧾 FORM CARD (MODERN)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 25,
                          offset: const Offset(0, 10),
                        )
                      ],
                    ),
                    child: Column(
                      children: [

                        // 📧 EMAIL
                        TextField(
                          controller: email,
                          decoration: InputDecoration(
                            labelText: t("email"),
                            prefixIcon: const Icon(Icons.email_outlined),
                            filled: true,
                            fillColor: const Color(0xFFF1F5F9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),

                        const SizedBox(height: 15),

                        // 🔒 PASSWORD
                        TextField(
                          controller: pass,
                          obscureText: obscure,
                          decoration: InputDecoration(
                            labelText: t("password"),
                            prefixIcon: const Icon(Icons.lock_outline),
                            filled: true,
                            fillColor: const Color(0xFFF1F5F9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscure
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() => obscure = !obscure);
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // 🔘 REMEMBER
                        Row(
                          children: [
                            Checkbox(
                              value: remember,
                              activeColor: const Color(0xFF14B8A6),
                              onChanged: (v) {
                                setState(() => remember = v!);
                              },
                            ),
                            Text(t("remember")),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // 🚀 LOGIN BUTTON
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
                            onPressed: () {},
                            child: isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : Text(
                                    t("login"),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 15),

                        // ➕ SIGN UP
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account?",
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            TextButton(
                              onPressed: () {},
                              child: Text(
                                t("create"),
                                style: const TextStyle(
                                  color: Color(0xFF14B8A6),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}