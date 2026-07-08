import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../bloc/auth_cubit.dart';

class SignupStartupScreen extends StatefulWidget {
  const SignupStartupScreen({super.key});

  @override
  State<SignupStartupScreen> createState() => _SignupStartupScreenState();
}

class _SignupStartupScreenState extends State<SignupStartupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _startupNameController = TextEditingController();
  final _taglineController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _proofController = TextEditingController();
  String _category = 'Engineering';
  bool _obscure = true;
  int _step = 0;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _startupNameController.dispose();
    _taglineController.dispose();
    _descriptionController.dispose();
    _proofController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await context.read<AuthCubit>().signUpStartup(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          fullName: _nameController.text.trim(),
          startupName: _startupNameController.text.trim(),
          tagline: _taglineController.text.trim(),
          description: _descriptionController.text.trim(),
          category: _category,
          aluRecognitionProof: _proofController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: _step == 0 ? () => context.pop() : () => setState(() => _step--),
        ),
        title: Text('Register Startup — Step ${_step + 1}/2'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_step + 1) / 2,
            backgroundColor: AppColors.border,
            color: AppColors.primary,
          ),
        ),
      ),
      body: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    '🎉 Startup registered! Your profile is pending ALU verification.'),
                backgroundColor: AppColors.success,
                duration: Duration(seconds: 4),
              ),
            );
            context.go('/home');
          }
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: _step == 0 ? _buildStep1() : _buildStep2(),
          ),
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your Account', style: AppTextStyles.displayMedium),
        const SizedBox(height: 8),
        Text('Enter your personal details to create a startup account.',
            style: AppTextStyles.bodyMedium),
        const SizedBox(height: 32),

        const _Label('Full Name'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            hintText: 'Your full name',
            prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
          ),
          validator: (v) => v == null || v.isEmpty ? 'Name required' : null,
        ),
        const SizedBox(height: 20),

        const _Label('Email'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            hintText: 'startup@email.com',
            prefixIcon: Icon(Icons.email_outlined, size: 20),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Email required';
            if (!v.contains('@')) return 'Enter a valid email';
            return null;
          },
        ),
        const SizedBox(height: 20),

        const _Label('Password'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscure,
          decoration: InputDecoration(
            hintText: 'At least 6 characters',
            prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                  _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 20),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Password required';
            if (v.length < 6) return 'Minimum 6 characters';
            return null;
          },
        ),
        const SizedBox(height: 32),

        ElevatedButton(
          onPressed: () {
            if (_nameController.text.trim().isEmpty ||
                _emailController.text.trim().isEmpty ||
                _passwordController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please fill all fields')),
              );
              return;
            }
            setState(() => _step = 1);
          },
          child: const Text('Next: Startup Info',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Startup Profile', style: AppTextStyles.displayMedium),
        const SizedBox(height: 8),
        Text(
          'Your startup will be reviewed by ALU admin before going live.',
          style: AppTextStyles.bodyMedium,
        ),

        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.verified_outlined, color: AppColors.warning, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Only ALU-recognized startups are approved. Provide valid proof of ALU recognition.',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.warning),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        const _Label('Startup Name'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _startupNameController,
          decoration: const InputDecoration(
            hintText: 'e.g. Learnify, GreenLoop',
            prefixIcon: Icon(Icons.business_outlined, size: 20),
          ),
          validator: (v) => v == null || v.isEmpty ? 'Startup name required' : null,
        ),
        const SizedBox(height: 20),

        const _Label('Tagline'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _taglineController,
          decoration: const InputDecoration(
            hintText: 'One-line description of what you do',
            prefixIcon: Icon(Icons.short_text_rounded, size: 20),
          ),
          validator: (v) => v == null || v.isEmpty ? 'Tagline required' : null,
        ),
        const SizedBox(height: 20),

        const _Label('Category'),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _category,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.category_outlined, size: 20),
          ),
          items: AppConstants.categories
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: (v) => setState(() => _category = v ?? _category),
        ),
        const SizedBox(height: 20),

        const _Label('Description'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descriptionController,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Describe your startup, its mission, and what kind of support you need...',
            alignLabelWithHint: true,
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Description required';
            if (v.length < 50) return 'Please provide at least 50 characters';
            return null;
          },
        ),
        const SizedBox(height: 20),

        const _Label('ALU Recognition Proof (URL)'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _proofController,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            hintText: 'Link to ALU recognition letter / certificate',
            prefixIcon: Icon(Icons.link_rounded, size: 20),
          ),
          validator: (v) => v == null || v.isEmpty ? 'Proof of ALU recognition required' : null,
        ),
        const SizedBox(height: 32),

        BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            return ElevatedButton(
              onPressed: state is AuthLoading ? null : _submit,
              child: state is AuthLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Submit for Verification',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
            );
          },
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) =>
      Text(text, style: AppTextStyles.labelLarge);
}
