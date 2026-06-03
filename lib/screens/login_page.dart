import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _signIn() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthService.instance.signInWithEmail(_emailController.text.trim(), _passwordController.text);
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message);
    } on Exception catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _register() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthService.instance.registerWithEmail(_emailController.text.trim(), _passwordController.text);
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message);
    } on Exception catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ログイン')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'メール')),
            const SizedBox(height: 8),
            TextField(controller: _passwordController, decoration: const InputDecoration(labelText: 'パスワード'), obscureText: true),
            const SizedBox(height: 16),
            if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            _loading
                ? const CircularProgressIndicator()
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(onPressed: _signIn, child: const Text('ログイン')),
                      const SizedBox(width: 12),
                      OutlinedButton(onPressed: _register, child: const Text('新規登録')),
                    ],
                  ),
            const SizedBox(height: 24),
            TextButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const _GuestInfo())),
                child: const Text('ゲストとして続行'))
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

class _GuestInfo extends StatelessWidget {
  const _GuestInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ゲスト利用')),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('ゲストとしてデータは端末ローカルに保存されます。クラウド同期やプロフィール機能を使うには登録してください。'),
      ),
    );
  }
}
