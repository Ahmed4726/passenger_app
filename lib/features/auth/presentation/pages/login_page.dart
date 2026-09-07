import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../../core/api/dio_client.dart';
import '../../../../core/models/app_user.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final response = await DioClient.dio.post(
        '/auth/login',
        data: {
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
        },
      );

      debugPrint('LOGIN RESPONSE: ${response.data}');

      final responseData = response.data;

      // Make sure the response is a JSON object.
      if (responseData is! Map) {
        throw Exception('Invalid server response.');
      }

      final data = Map<String, dynamic>.from(responseData);

      // Get the data object from the API response.
      final payloadData = data['data'];

      if (payloadData is! Map) {
        throw Exception(
          data['message']?.toString() ?? 'Invalid login response.',
        );
      }

      final payload = Map<String, dynamic>.from(payloadData);

      // Get authentication token.
      final token = payload['token']?.toString() ?? '';

      if (token.isEmpty) {
        throw Exception(
          'Login token was not returned by the server.',
        );
      }

      // Get user data.
      final userData = payload['user'];

      if (userData is! Map) {
        throw Exception(
          'User data was not returned by the server.',
        );
      }

      AppUser.fromJson(
        Map<String, dynamic>.from(userData),
        token: token,
      );

      // Save token locally.
      await DioClient.persistToken(token);

      // Set token for future API requests.
      await DioClient.setAuthToken(token);

      if (!mounted) return;

      Navigator.of(context).pushReplacementNamed('/home');
    } on DioException catch (e) {
      debugPrint('LOGIN ERROR: ${e.message}');
      debugPrint('LOGIN ERROR RESPONSE: ${e.response?.data}');

      final responseData = e.response?.data;

      String message = 'Unable to sign in right now.';

      // Laravel returned a JSON object.
      if (responseData is Map) {
        message = responseData['message']?.toString() ?? message;
      }

      // Server returned a plain text response.
      else if (responseData is String &&
          responseData.trim().isNotEmpty) {
        message = responseData.trim();
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
    } on Exception catch (e) {
      debugPrint('LOGIN EXCEPTION: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    } catch (e) {
      debugPrint('LOGIN UNKNOWN ERROR: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: AppColors.background,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 32,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Icon(
                            Icons.person_outline,
                            size: 52,
                            color: AppColors.primary,
                          ),

                          const SizedBox(height: 18),

                          Text(
                            'Welcome back',
                            style: AppTextStyles.heading,
                          ),

                          const SizedBox(height: 10),

                          Text(
                            'Sign in to continue your ride',
                            style: AppTextStyles.subtitle,
                          ),

                          const SizedBox(height: 28),

                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(
                                Icons.email_outlined,
                              ),
                            ),
                            validator: (value) {
                              if (value == null ||
                                  value.trim().isEmpty) {
                                return 'Email is required';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Password',
                              prefixIcon: Icon(
                                Icons.lock_outline,
                              ),
                            ),
                            validator: (value) {
                              if (value == null ||
                                  value.isEmpty) {
                                return 'Password is required';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(height: 24),

                          FilledButton.icon(
                            onPressed: _loading ? null : _submit,
                            icon: _loading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.white,
                                    ),
                                  )
                                : const Icon(Icons.login),
                            label: Text(
                              _loading
                                  ? 'Signing in...'
                                  : 'Sign in',
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    Center(
                      child: TextButton(
                        onPressed: _loading
                            ? null
                            : () {
                                Navigator.of(context)
                                    .pushNamed('/register');
                              },
                        child: const Text(
                          'Create account',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
