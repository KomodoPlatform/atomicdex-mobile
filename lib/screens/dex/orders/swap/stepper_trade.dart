import 'package:flutter/material.dart';
import '../../../../model/swap.dart';
import '../../../dex/orders/swap/detail_swap.dart';
import '../../../dex/orders/swap/progress_swap.dart';

class StepperTrade extends StatefulWidget {
  const StepperTrade({this.swap, this.onStepFinish});

  final Swap swap;
  final Function onStepFinish;

  @override
  _StepperTradeState createState() => _StepperTradeState();
}

class _StepperTradeState extends State<StepperTrade> {
  @override
  Widget build(BuildContext context) {
    if (widget.swap.result != null && widget.swap.result.myInfo == null) {
      widget.swap.status = Status.SWAP_FAILED;
    }

    return ListView(
      children: <Widget>[
        ProgressSwap(
            uuid: widget.swap.result.uuid, onFinished: widget.onStepFinish),
        if (widget.swap != null)
          DetailSwap(
            swap: widget.swap,
          ),
      ],
    );
  }
}
