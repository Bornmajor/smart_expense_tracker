import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/profile_repository_impl.dart';
import '../cubit/profile_cubit.dart';

/// The Settings row for the first name used in the greeting. Tapping it opens a
/// small box to change it, or to clear it.
class ProfileNameTile extends StatelessWidget {
  const ProfileNameTile({super.key});

  Future<void> _edit(BuildContext context, String current) async {
    final cubit = context.read<ProfileCubit>();
    final saved = await showDialog<String>(
      context: context,
      builder: (context) => _NameDialog(initial: current),
    );
    if (saved != null) await cubit.setName(saved);
  }

  @override
  Widget build(BuildContext context) {
    final name = context.watch<ProfileCubit>().state;
    return ListTile(
      leading: const Icon(Icons.person_outline),
      title: const Text('Your name'),
      subtitle: Text(name.isEmpty ? 'Not set' : name),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _edit(context, name),
    );
  }
}

/// Owns its text controller, so it is only disposed once the dialog has
/// finished closing.
class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.initial});

  final String initial;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Your name'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        maxLength: ProfileRepositoryImpl.maxLength,
        decoration: const InputDecoration(
          labelText: 'First name',
          helperText:
              'To make the app feel like yours. It stays on your phone.',
        ),
        onSubmitted: (value) => Navigator.pop(context, value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
