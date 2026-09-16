import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vyaparsetu/components/emptyState.dart';
import 'package:vyaparsetu/components/loadStateBody.dart';
import 'package:vyaparsetu/components/pagedList.dart';
import 'package:vyaparsetu/components/searchBar.dart';
import 'package:vyaparsetu/core/Core.dart';
import 'package:vyaparsetu/global/constants.dart';
import 'package:vyaparsetu/global/themes.dart';
import 'package:vyaparsetu/helpers/navigation.dart';
import 'package:vyaparsetu/screens/parties/form.dart';
import 'package:vyaparsetu/screens/parties/widgets.dart';
import 'package:vyaparsetu/types/party.dart';

class PartyListScreen extends StatefulWidget {
  const PartyListScreen({super.key});

  @override
  State<PartyListScreen> createState() => _PartyListScreenState();
}

class _PartyListScreenState extends State<PartyListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<Core>().party.fetchParties(),
    );
  }

  void _add() => Navigator.of(context).push(getPageRoute(const PartyFormScreen()));

  @override
  Widget build(BuildContext context) {
    final core = context.watch<Core>();
    final parties = core.party;
    scheduleReload(parties.list.needsReload, () => parties.fetchParties(refresh: true));

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('tab_parties'.tr()),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add-party',
        onPressed: _add,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: Text('add_party'.tr()),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spaceLg,
              0,
              AppTheme.spaceLg,
              AppTheme.spaceSm,
            ),
            child: AppSearchBar(
              hintText: 'search_parties'.tr(),
              initialValue: parties.search,
              onChanged: (query) => parties.setFilters(search: query),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLg),
              children: [
                ChoiceChip(
                  label: Text('filter_all'.tr()),
                  selected: parties.typeFilter == null,
                  showCheckmark: false,
                  onSelected: (_) => parties.setFilters(clearType: true),
                ),
                for (final type in const [
                  PartyType.customer,
                  PartyType.supplier,
                  PartyType.transporter,
                ])
                  Padding(
                    padding: const EdgeInsets.only(left: AppTheme.spaceSm),
                    child: ChoiceChip(
                      label: Text('party_filter_${type.value}'.tr()),
                      selected: parties.typeFilter == type,
                      showCheckmark: false,
                      onSelected: (_) => parties.setFilters(type: type),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: PagedListView<Party>(
              items: parties.list.items,
              isLoading: parties.list.isLoading,
              isLoadingMore: parties.list.isLoadingMore,
              hasMore: parties.list.data.hasMore,
              error: parties.list.error,
              onRefresh: () => parties.fetchParties(refresh: true),
              onLoadMore: parties.loadMore,
              itemBuilder: (context, party) => PartyTile(party: party),
              emptyState: EmptyState(
                icon: Icons.people_outline_rounded,
                title: parties.search.isEmpty && parties.typeFilter == null
                    ? 'no_parties_yet'.tr()
                    : 'no_parties_match'.tr(),
                description: 'no_parties_yet_hint'.tr(),
                buttonText: 'add_party'.tr(),
                buttonIcon: Icons.person_add_alt_1_rounded,
                onButtonPressed: _add,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
