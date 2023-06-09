import 'package:flutter/material.dart';
import '../../localizations.dart';
import '../feed/news/news_tab.dart';
import '../../utils/custom_tab_indicator.dart';
import '../../../utils/log.dart';

class FeedPage extends StatefulWidget {
  @override
  _FeedPageState createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage>
    with SingleTickerProviderStateMixin {
  TabController _controllerTabs;
  @override
  void initState() {
    _controllerTabs = TabController(length: 1, vsync: this);
    _controllerTabs.addListener(_getIndex);
    super.initState();
  }

  @override
  void dispose() {
    _controllerTabs.dispose();
    super.dispose();
  }

  void _getIndex() {
    Log.println('media_page:38', _controllerTabs.index);
  }

  @override
  Widget build(BuildContext context) {
    Widget _buildAppBar() {
      final bool _isSmallScreen = MediaQuery.of(context).size.height < 680;

      final Widget _tabsPanel = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          height: 40,
          decoration: BoxDecoration(
              shape: BoxShape.rectangle,
              borderRadius: const BorderRadius.all(Radius.circular(32)),
              border: Border.all(color: Colors.grey, width: 1)),
          child: TabBar(
            labelPadding: const EdgeInsets.symmetric(horizontal: 16),
            indicator: CustomTabIndicator(context: context),
            controller: _controllerTabs,
            tabs: <Widget>[
              Tab(text: AppLocalizations.of(context).feedNewsTab.toUpperCase()),
            ],
          ),
        ),
      );

      return _isSmallScreen && _controllerTabs.length > 1
          ? PreferredSize(
              preferredSize: const Size.fromHeight(80),
              child: AppBar(
                flexibleSpace: SafeArea(
                    child: Column(
                  children: <Widget>[
                    const SizedBox(height: 20),
                    _tabsPanel,
                  ],
                )),
                automaticallyImplyLeading: false,
              ),
            )
          : AppBar(
              title: Text(AppLocalizations.of(context).feedTitle.toUpperCase()),
              automaticallyImplyLeading: false,
            );
    }

    return Scaffold(
      appBar: _buildAppBar(),
      body: TabBarView(
        controller: _controllerTabs,
        children: <Widget>[
          NewsTab(),
        ],
      ),
    );
  }
}
