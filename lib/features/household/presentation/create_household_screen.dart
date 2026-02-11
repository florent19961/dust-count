import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dust_count/shared/strings.dart';
import '../domain/household_providers.dart';

/// Screen for creating a new household
class CreateHouseholdScreen extends ConsumerStatefulWidget {
  const CreateHouseholdScreen({super.key});

  @override
  ConsumerState<CreateHouseholdScreen> createState() =>
      _CreateHouseholdScreenState();
}

class _CreateHouseholdScreenState extends ConsumerState<CreateHouseholdScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createHousehold() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ref
          .read(householdControllerProvider.notifier)
          .createHousehold(_nameController.text.trim());

      if (!mounted) return;

      // Get the newly created household ID
      final currentHouseholdId = ref.read(currentHouseholdIdProvider);

      if (currentHouseholdId != null) {
        // Navigate to the new household home screen
        context.go('/household/$currentHouseholdId');
      } else {
        // Fallback to household list
        context.go('/households');
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${S.errorCreatingHousehold}: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(S.createHousehold),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icon
              Icon(
                Icons.home_outlined,
                size: 80,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                S.createNewHousehold,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Description
              Text(
                S.createHouseholdDescription,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Name field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: S.householdName,
                  hintText: S.householdNameHint,
                  prefixIcon: const Icon(Icons.home),
                  border: const OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                enabled: !_isLoading,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return S.householdNameRequired;
                  }
                  if (value.trim().length < 2) {
                    return S.householdNameTooShort;
                  }
                  if (value.trim().length > 50) {
                    return S.householdNameTooLong;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Create button
              FilledButton(
                onPressed: _isLoading ? null : _createHousehold,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : Text(S.create),
              ),
              const SizedBox(height: 12),

              // Cancel button
              OutlinedButton(
                onPressed: _isLoading ? null : () => context.pop(),
                child: Text(S.cancel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
