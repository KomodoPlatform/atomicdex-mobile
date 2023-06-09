import 'package:flutter/material.dart';
import 'package:komodo_dex/utils/utils.dart';
import '../../../../../model/swap_constructor_provider.dart';
import 'package:provider/provider.dart';

class BuildTradeMessage extends StatefulWidget {
  @override
  _BuildTradeMessageState createState() => _BuildTradeMessageState();
}

class _BuildTradeMessageState extends State<BuildTradeMessage> {
  ConstructorProvider _constrProvider;
  String _error;
  String _warning;

  @override
  Widget build(BuildContext context) {
    _constrProvider ??= Provider.of<ConstructorProvider>(context);
    _error = _constrProvider.error;
    _warning = _constrProvider.warning;

    if (_error == null && _warning == null) return SizedBox();

    return Container(
      padding: EdgeInsets.fromLTRB(12, 16, 12, 0),
      child: Container(
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_error == null && _warning == null) return SizedBox();
    return Column(
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(minHeight: 36),
          child: _error == null ? _buildWarning() : _buildError(),
        ),
      ],
    );
  }

  Widget _buildWarning() {
    final Color color = Theme.of(context).textTheme.bodyText1.color;

    return Container(
      padding: EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color, width: 0.5)),
      child: Row(
        children: [
          Icon(
            Icons.notification_important,
            size: 16,
            color: color,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              _warning,
              style: Theme.of(context)
                  .textTheme
                  .caption
                  .copyWith(color: color, fontSize: 13),
            ),
          ),
          // todo(MRC): Port to IconButton
          InkWell(
            onTap: () => _constrProvider.warning = null,
            child: Container(
              padding: EdgeInsets.fromLTRB(6, 6, 8, 6),
              child: Icon(
                Icons.clear,
                size: 13,
                color: color,
              ),
            ),
          )
        ],
      ),
    );
  }

  bool showErrorDetails = false;
  Widget _buildError() {
    final Color color = Theme.of(context).errorColor;

    List<String> errors = _error.split('.');
    String first = errors.first;
    errors.remove(first);
    String details = errors.join('. ');
    return Container(
      padding: EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color, width: 0.5)),
      child: Row(
        children: [
          Icon(
            Icons.error,
            size: 16,
            color: Theme.of(context).errorColor,
          ),
          SizedBox(width: 8),
          Expanded(
            child: ListView(
              shrinkWrap: true,
              children: [
                Text(
                  first,
                  style: Theme.of(context)
                      .textTheme
                      .caption
                      .copyWith(color: color, fontSize: 13),
                ),
                if (showErrorDetails)
                  Text(
                    '\n' + details.trim(),
                    style: Theme.of(context)
                        .textTheme
                        .caption
                        .copyWith(color: color, fontSize: 13),
                  ),
              ],
            ),
          ),
          SizedBox(width: 8),
          if (details.isNotEmpty)
            Column(
              children: [
                InkWell(
                  onTap: () {
                    showErrorDetails = !showErrorDetails;
                    setState(() {});
                  },
                  child: Icon(
                    showErrorDetails
                        ? Icons.arrow_drop_up
                        : Icons.arrow_drop_down,
                    color: Theme.of(context).textTheme.bodyText1.color,
                    size: 16,
                  ),
                ),
                if (showErrorDetails)
                  Padding(
                    padding: EdgeInsets.only(top: 18.0),
                    child: IconButton(
                      icon: Icon(Icons.copy, size: 18),
                      onPressed: () {
                        copyToClipBoard(context, _error);
                      },
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
