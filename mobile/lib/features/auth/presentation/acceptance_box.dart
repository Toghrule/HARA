import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A tick box for a text the person has to accept, with links to read it. Part of a form: it fails validation, with
/// [errorText], until it is ticked.
class AcceptanceBox extends FormField<bool> {
  AcceptanceBox({
    required Key super.key,
    required String label,
    required List<({String label, String route})> links,
    required String errorText,
    bool enabled = true,
  }) : super(
          initialValue: false,
          validator: (ticked) => ticked == true ? null : errorText,
          builder: (state) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CheckboxListTile(
                value: state.value ?? false,
                onChanged: enabled ? (value) => state.didChange(value) : null,
                title: Text(label),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              Wrap(
                children: [
                  for (final link in links)
                    TextButton(
                      onPressed: () => state.context.push(link.route),
                      child: Text(link.label),
                    ),
                ],
              ),
              if (state.hasError)
                Padding(
                  padding: const EdgeInsets.only(left: 12, bottom: 4),
                  child: Text(
                    state.errorText!,
                    style: Theme.of(state.context).textTheme.bodySmall?.copyWith(color: Theme.of(state.context).colorScheme.error),
                  ),
                ),
            ],
          ),
        );
}
