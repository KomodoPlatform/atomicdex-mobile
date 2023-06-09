import 'dart:math';

import 'package:flutter/material.dart';
import '../../../../../../model/coin.dart';
import '../../../../../../model/order_book_provider.dart';
import '../../../../../../model/orderbook.dart';
import 'package:provider/provider.dart';

class MatchingBidsChart extends StatefulWidget {
  const MatchingBidsChart({
    this.bidsList,
    this.sellAmount,
    this.lineHeight,
  });

  final List<Ask> bidsList;
  final double sellAmount;
  final double lineHeight;

  @override
  _MatchingBidsChartState createState() => _MatchingBidsChartState();
}

class _MatchingBidsChartState extends State<MatchingBidsChart> {
  OrderBookProvider orderBookProvider;
  Coin sellCoin;

  @override
  Widget build(BuildContext context) {
    orderBookProvider = Provider.of<OrderBookProvider>(context);
    sellCoin = orderBookProvider.activePair.sell;

    return CustomPaint(
      painter: _ChartPainter(widget),
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter(this.widget);

  final MatchingBidsChart widget;

  @override
  void paint(Canvas canvas, Size size) {
    double maxBaseVolume = _volumes().reduce(max);
    if (maxBaseVolume < widget.sellAmount) maxBaseVolume = widget.sellAmount;
    final double baseVolumeRatio = size.width / maxBaseVolume;

    final Paint paint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.green.withAlpha(70);

    for (int i = 0; i < widget.bidsList.length; i++) {
      final Ask bid = widget.bidsList[i];
      double barWidth =
          bid.maxvolume.toDouble() * double.parse(bid.price) * baseVolumeRatio;
      if (barWidth < 1) barWidth = 1;

      canvas.drawRect(
          Rect.fromLTRB(
            size.width - barWidth,
            widget.lineHeight * i,
            size.width,
            widget.lineHeight * i + widget.lineHeight,
          ),
          paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;

  List<double> _volumes() {
    return widget.bidsList
        .map((ask) => ask.maxvolume.toDouble() * double.parse(ask.price))
        .toList();
  }
}
