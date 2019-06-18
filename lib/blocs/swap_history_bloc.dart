import 'dart:async';

import 'package:flutter/material.dart';
import 'package:komodo_dex/localizations.dart';
import 'package:komodo_dex/model/coin.dart';
import 'package:komodo_dex/model/error_string.dart';
import 'package:komodo_dex/model/recent_swaps.dart';
import 'package:komodo_dex/model/swap.dart';
import 'package:komodo_dex/model/uuid.dart';
import 'package:komodo_dex/services/market_maker_service.dart';
import 'package:komodo_dex/widgets/bloc_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

final swapHistoryBloc = SwapHistoryBloc();

class SwapHistoryBloc implements BlocBase {
  List<Swap> swaps = new List<Swap>();

  // Streams to handle the list coin
  StreamController<List<Swap>> _swapsController =
      StreamController<List<Swap>>.broadcast();
  Sink<List<Swap>> get _inSwaps => _swapsController.sink;
  Stream<List<Swap>> get outSwaps => _swapsController.stream;

  bool isAnimationStepFinalIsFinish = false;

  // Streams to handle the list coin
  StreamController<bool> _isAnimationStepFinalIsFinishController =
      StreamController<bool>.broadcast();
  Sink<bool> get _inIsAnimationStepFinalIsFinish =>
      _isAnimationStepFinalIsFinishController.sink;
  Stream<bool> get outIsAnimationStepFinalIsFinish =>
      _isAnimationStepFinalIsFinishController.stream;

  bool isSwapsOnGoing = false;
  @override
  void dispose() {
    _swapsController.close();
    _isAnimationStepFinalIsFinishController.close();
  }

  Future<List<Swap>> updateSwaps(int limit, String fromUuid) async {
    isSwapsOnGoing = false;
    RecentSwaps recentSwaps = await mm2.getRecentSwaps(limit, fromUuid);
    List<Swap> newSwaps = new List<Swap>();

    recentSwaps.result.swaps.forEach((swap) {
      dynamic nSwap = new Swap(result: swap, status: getStatusSwap(swap));
      if (nSwap is Swap) {
        if (swap.myInfo.startedAt + 3600 <
                DateTime.now().millisecondsSinceEpoch ~/ 1000 &&
            getStatusSwap(swap) != Status.SWAP_SUCCESSFUL) {
          nSwap.status = Status.TIME_OUT;
        }
        newSwaps.add(nSwap);
        if (nSwap.status == Status.ORDER_MATCHED ||
            nSwap.status == Status.ORDER_MATCHING ||
            nSwap.status == Status.SWAP_ONGOING) {
          isSwapsOnGoing = true;
        }
      } else if (nSwap is ErrorString) {
        if (swap.myInfo.startedAt + 600 <
            DateTime.now().millisecondsSinceEpoch ~/ 1000) {
          newSwaps.add(Swap(
            status: Status.TIME_OUT,
            result: swap,
          ));
        }
      }
    });
    setSwaps(newSwaps);
    return this.swaps;
  }

  void setSwaps(List<Swap> newSwaps) {
    if (newSwaps == null) {
      this.swaps.clear();
    } else {
      if (this.swaps.length == 0) {
        this.swaps.addAll(newSwaps);
      } else {
        newSwaps.forEach((newSwap) {
          bool isSwapAlreadyExist = false;
          this.swaps.asMap().forEach((index, currentSwap) {
            if (newSwap.result.uuid == currentSwap.result.uuid) {
              isSwapAlreadyExist = true;
              if (newSwap.status != currentSwap.status) {
                this.swaps.removeAt(index);
                this.swaps.add(newSwap);
              }
            }
          });
          if (!isSwapAlreadyExist) {
            this.swaps.add(newSwap);
          }
        });
      }
    }

    _inSwaps.add(this.swaps);
  }

  Status getStatusSwap(ResultSwap resultSwap) {
    Status status = Status.ORDER_MATCHING;

    resultSwap.events.forEach((event) {
      switch (event.event.type) {
        case "Started":
          status = Status.ORDER_MATCHED;
          break;
        case "TakerFeeSent":
          status = Status.SWAP_ONGOING;
          break;
        case "MakerPaymentSpent":
          status = Status.SWAP_SUCCESSFUL;
          break;
        default:
      }
    });

    return status;
  }

  String getSwapStatusString(BuildContext context, Status status) {
    switch (status) {
      case Status.ORDER_MATCHING:
        return AppLocalizations.of(context).orderMatching;
        break;
      case Status.ORDER_MATCHED:
        return AppLocalizations.of(context).orderMatched;
        break;
      case Status.SWAP_ONGOING:
        return AppLocalizations.of(context).swapOngoing;
        break;
      case Status.SWAP_SUCCESSFUL:
        return AppLocalizations.of(context).swapSucceful;
        break;
      case Status.TIME_OUT:
        return AppLocalizations.of(context).timeOut;
        break;
      default:
    }
    return "";
  }

  Color getColorStatus(Status status) {
    switch (status) {
      case Status.ORDER_MATCHING:
        return Colors.grey;
        break;
      case Status.ORDER_MATCHED:
        return Colors.yellowAccent.shade700.withOpacity(0.7);
        break;
      case Status.SWAP_ONGOING:
        return Colors.orangeAccent;
        break;
      case Status.SWAP_SUCCESSFUL:
        return Colors.green.shade500;
        break;
      case Status.TIME_OUT:
        return Colors.redAccent;
        break;
      default:
    }
    return Colors.redAccent;
  }

  String getStepStatus(Status status) {
    switch (status) {
      case Status.ORDER_MATCHING:
        return "0/3";
        break;
      case Status.ORDER_MATCHED:
        return "1/3";
        break;
      case Status.SWAP_ONGOING:
        return "2/3";
        break;
      case Status.SWAP_SUCCESSFUL:
        return "✓";
        break;
      case Status.TIME_OUT:
        return "";
        break;
      default:
    }
    return "";
  }

  int getStepStatusNumber(Status status) {
    switch (status) {
      case Status.ORDER_MATCHING:
        return 0;
        break;
      case Status.ORDER_MATCHED:
        return 1;
        break;
      case Status.SWAP_ONGOING:
        return 2;
        break;
      case Status.SWAP_SUCCESSFUL:
        return 3;
        break;
      case Status.TIME_OUT:
        return 0;
        break;
      default:
    }
    return 0;
  }

  double getNumberStep() {
    return 3;
  }
}
