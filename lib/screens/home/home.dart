import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vyaparsetu/core/Core.dart';
import 'package:vyaparsetu/global/constants.dart';
import 'package:vyaparsetu/helpers/navigation.dart';
import 'package:vyaparsetu/screens/dashboard/dashboard.dart';
import 'package:vyaparsetu/screens/invoices/form.dart';
import 'package:vyaparsetu/screens/invoices/list.dart';
import 'package:vyaparsetu/screens/items/list.dart';
import 'package:vyaparsetu/screens/more/more.dart';
import 'package:vyaparsetu/screens/parties/list.dart';

/// Bottom navigation shell. Tabs are built on first visit and kept alive.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  static const _billsTab = 1;

  int _index = 0;
  final _visited = <int>{0};

  /// Lets other screens switch tabs (e.g. dashboard "See all bills").
  static HomeScreenState? of(BuildContext context) =>
      context.findAncestorStateOfType<HomeScreenState>();

  void setTab(int index) {
    setState(() {
      _index = index;
      _visited.add(index);
    });
  }

  void _newBill() {
    Navigator.of(context).push(
      getPageRoute(const InvoiceFormScreen(type: InvoiceType.sale)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild the tabs from scratch when the business changes.
    final businessId = context.select<Core, String?>(
      (c) => c.business.selectedBusiness?.id,
    );

    // Signing out clears the business while this shell is still on screen.
    // Building the tabs then would send them looking for a business that is
    // no longer there; the session handler moves to the sign-in screen on the
    // next frame.
    if (businessId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    const tabs = <Widget>[
      DashboardScreen(),
      InvoiceListScreen(),
      PartyListScreen(),
      ItemListScreen(),
      MoreScreen(),
    ];

    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setTab(0);
      },
      child: Scaffold(
        body: IndexedStack(
          key: ValueKey(businessId),
          index: _index,
          children: [
            for (var i = 0; i < tabs.length; i++)
              _visited.contains(i) ? tabs[i] : const SizedBox.shrink(),
          ],
        ),
        floatingActionButton: _index <= _billsTab
            ? FloatingActionButton.extended(
                heroTag: 'new-bill',
                onPressed: _newBill,
                icon: const Icon(Icons.add_rounded),
                label: Text('new_bill'.tr()),
              )
            : null,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: setTab,
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.space_dashboard_outlined),
              selectedIcon: const Icon(Icons.space_dashboard_rounded),
              label: 'tab_home'.tr(),
            ),
            NavigationDestination(
              icon: const Icon(Icons.receipt_long_outlined),
              selectedIcon: const Icon(Icons.receipt_long_rounded),
              label: 'tab_bills'.tr(),
            ),
            NavigationDestination(
              icon: const Icon(Icons.people_outline_rounded),
              selectedIcon: const Icon(Icons.people_rounded),
              label: 'tab_parties'.tr(),
            ),
            NavigationDestination(
              icon: const Icon(Icons.inventory_2_outlined),
              selectedIcon: const Icon(Icons.inventory_2_rounded),
              label: 'tab_items'.tr(),
            ),
            NavigationDestination(
              icon: const Icon(Icons.grid_view_outlined),
              selectedIcon: const Icon(Icons.grid_view_rounded),
              label: 'tab_more'.tr(),
            ),
          ],
        ),
      ),
    );
  }
}
