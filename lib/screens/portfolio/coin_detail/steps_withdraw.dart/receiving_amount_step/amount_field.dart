import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../app_config/app_config.dart';
import '../../../../../localizations.dart';
import '../../../../../utils/decimal_text_input_formatter.dart';

class AmountField extends StatelessWidget {
  const AmountField({
    Key key,
    this.trailingText,
    this.controller,
    this.enabled = true,
  }) : super(key: key);

  final String trailingText;
  final TextEditingController controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    Widget widget = TextFormField(
      inputFormatters: <TextInputFormatter>[
        DecimalTextInputFormatter(
          decimalRange: appConfig.tradeFormPrecision,
        ),
        FilteringTextInputFormatter.allow(
          RegExp('^\$|^(0|([1-9][0-9]{0,12}))([.,]{1}[0-9]{0,8})?\$'),
        )
      ],
      controller: enabled ? controller : null,
      autovalidateMode: controller.text.isNotEmpty
          ? AutovalidateMode.always
          : AutovalidateMode.disabled,
      textInputAction: TextInputAction.done,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
      ),
      style: Theme.of(context).textTheme.bodyText2,
      textAlign: TextAlign.end,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context).amount,
        suffixIcon: Padding(
          padding: EdgeInsets.only(right: 8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                trailingText.toUpperCase(),
                style: Theme.of(context).textTheme.bodyText1,
              ),
            ],
          ),
        ),
      ),
      validator: (String value) {
        if (!enabled) return null;

        value = value.replaceAll(',', '.');
        if (value.isEmpty || double.parse(value) <= 0) {
          return AppLocalizations.of(context).errorValueNotEmpty;
        }

        return null;
      },
    );

    if (!enabled) {
      widget = Stack(
        children: [
          widget,
          Positioned.fill(
            child: ClipRRect(
              clipBehavior: Clip.hardEdge,
              borderRadius: BorderRadius.circular(2),
              child: ColoredBox(
                color: Colors.grey.withOpacity(0.6),
              ),
            ),
          ),
        ],
      );
    }

    return widget;
  }
}
