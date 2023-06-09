import 'package:flutter/material.dart';
import '../../../../model/order.dart';
import '../../../../model/swap.dart';
import '../../../../model/swap_provider.dart';
import '../../../dex/orders/swap/build_item_swap.dart';
import 'package:provider/provider.dart';

class MakerOrderSwaps extends StatefulWidget {
  const MakerOrderSwaps(this.order);

  final Order order;

  @override
  _MakerOrderSwapsState createState() => _MakerOrderSwapsState();
}

class _MakerOrderSwapsState extends State<MakerOrderSwaps> {
  SwapProvider swapProvider;

  @override
  Widget build(BuildContext context) {
    swapProvider ??= Provider.of<SwapProvider>(context);

    if (widget.order.startedSwaps == null || widget.order.startedSwaps.isEmpty)
      return SizedBox();

    return Column(
      children: buildFilteredSwaps(),
    );
  }

  List<Widget> buildFilteredSwaps() {
    final List<Widget> filtered = [];

    for (Swap swap in swapProvider.swaps) {
      final String swapId = swap.result?.uuid;
      if (swapId == null) continue;

      if (widget.order.startedSwaps.contains(swapId)) {
        filtered.add(BuildItemSwap(
          context: context,
          swap: swap,
        ));
      }
    }

    return filtered;
  }
}
