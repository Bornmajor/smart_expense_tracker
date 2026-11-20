import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';

/// A row with something on the left and an amount on the right.
///
/// The amount never pushes the left side off the screen, however long it is
/// (a big sum, a currency symbol, or large text on a small phone). It takes
/// only the room it needs up to half the row, and shrinks to fit beyond that.
/// The left side gets all the rest.
class AmountRow extends StatelessWidget {
  const AmountRow({
    super.key,
    required this.leading,
    required this.amount,
    this.amountStyle,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  final Widget leading;

  /// The amount, already written out, such as "KSh 1,234.56".
  final String amount;
  final TextStyle? amountStyle;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Row(
        crossAxisAlignment: crossAxisAlignment,
        children: [
          Expanded(child: leading),
          const SizedBox(width: AppSpacing.sm),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: constraints.maxWidth * 0.5),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(amount, style: amountStyle, maxLines: 1),
            ),
          ),
        ],
      ),
    );
  }
}
