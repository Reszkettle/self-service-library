import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lendme/components/loadable_area.dart';
import 'package:lendme/models/item.dart';
import 'package:lendme/models/user.dart';
import 'package:lendme/repositories/item_repository.dart';
import 'package:lendme/screens/other/item_details/panel_available.dart';
import 'package:lendme/screens/other/item_details/panel_borrowed.dart';
import 'package:lendme/screens/other/item_details/panel_lent.dart';
import 'package:lendme/utils/enums.dart';
import 'package:provider/provider.dart';
import 'dart:developer';

class ItemDetails extends StatefulWidget {
  const ItemDetails({required this.itemId, Key? key}) : super(key: key);

  final String itemId;

  @override
  _ItemDetailsState createState() => _ItemDetailsState();
}

class _ItemDetailsState extends State<ItemDetails> {
  final ItemRepository _itemRepository = ItemRepository();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _itemRepository.getItemStream(widget.itemId),
      builder: _buildFromItem,
    );
  }

  Widget _buildFromItem(BuildContext context, AsyncSnapshot<Item?> itemSnap) {
    final item = itemSnap.data;

    final user = Provider.of<User?>(context);
    if (user == null) {
      return Container();
    }

    ItemStatus? itemStatus;
    if (item != null) {
      itemStatus = getItemStatus(item, user);
    }

    return Scaffold(
      appBar: AppBar(
          title: Row(
            children: [
              const Text('Item: '),
              if (item != null) Text(item.title),
            ],
          ),
          elevation: 0.0),
      body: LoadableArea(
          initialState:
              item == null ? LoadableAreaState.loading : LoadableAreaState.main,
          child: SingleChildScrollView(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: _mainLayout(context, item, itemStatus),
            ),
          )),
    );
  }

  Widget _mainLayout(BuildContext context, Item? item, ItemStatus? itemStatus) {
    return Column(
      children: [
        _topRow(itemStatus),
        const SizedBox(height: 16.0),
        _itemImage(context, item),
        const SizedBox(height: 16.0),
        _title(item),
        if (item?.description != null) _description(context, item),
        const SizedBox(height: 16.0),
        _statusPanel(item, itemStatus),
        const SizedBox(height: 16.0),
        _historyButton(),
      ],
    );
  }

  Widget _topRow(ItemStatus? itemStatus) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            _addedTime(),
            const Spacer(),
            if (itemStatus == ItemStatus.available) _deleteButton(),
          ],
        )
      ],
    );
  }

  Text _addedTime() {
    return const Text(
      "Added 23/10/2021",
      style: TextStyle(color: Colors.grey),
    );
  }

  Widget _deleteButton() {
    return IconButton(
      icon: const Icon(
        Icons.delete,
        color: Colors.red,
      ),
      padding: const EdgeInsets.all(0.0),
      splashRadius: 25,
      visualDensity: const VisualDensity(
        horizontal: VisualDensity.minimumDensity,
        vertical: VisualDensity.minimumDensity,
      ),
      onPressed: () {},
    );
  }

  Widget _itemImage(BuildContext context, Item? item) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              border: Border.all(
                color: Theme.of(context).primaryColor,
                width: 3,
              ),
              borderRadius: const BorderRadius.all(Radius.circular(20))),
          child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: item?.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: item?.imageUrl ?? '',
                      height: 200,
                      fit: BoxFit.fitHeight,
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.error, size: 45))
                  : Image.asset(
                      'assets/images/item_default.jpg',
                      height: 200,
                    )),
        )
      ],
    );
  }

  Widget _title(Item? item) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          item?.title ?? '',
          style: const TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _description(BuildContext context, Item? item) {
    return Column(
      children: [
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: const BorderRadius.all(Radius.circular(10))),
          child: ExpansionTile(
            title: const Text('Description'),
            textColor: Colors.black,
            iconColor: Colors.black,
            collapsedIconColor: Colors.black,
            childrenPadding: const EdgeInsets.all(0),
            children: <Widget>[
              ListTile(title: Text(item?.description ?? '')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statusPanel(Item? item, ItemStatus? itemStatus) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: const BorderRadius.all(Radius.circular(10))),
          padding: const EdgeInsets.all(16),
          child: _getProperStatusPanel(item, itemStatus),
        ),
      ],
    );
  }

  Widget _getProperStatusPanel(Item? item, ItemStatus? itemStatus) {
    if (item == null || itemStatus == null) {
      return Container();
    }
    if (itemStatus == ItemStatus.available) {
      return PanelAvailable(item: item);
    } else if (itemStatus == ItemStatus.lent) {
      return PanelLent(item: item);
    } else if (itemStatus == ItemStatus.borrowed) {
      return PanelBorrowed(item: item);
    } else {
      return Container();
    }
  }

  Widget _historyButton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          label: const Text('Show Item History'),
          icon: const Icon(Icons.history_rounded),
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0)),
          ),
          onPressed: () {
            // TODO: Extend time action
          },
        ),
      ],
    );
  }

  ItemStatus getItemStatus(Item item, User user) {
    if (item.lentById == user.uid) {
      return ItemStatus.borrowed;
    } else if (item.lentById == null && item.ownerId == user.uid) {
      return ItemStatus.available;
    } else if (item.lentById != null && item.ownerId == user.uid) {
      return ItemStatus.lent;
    } else {
      log('Inconsistent database state! unable to conclude item ${item.id} status!');
      return ItemStatus.available;  // Shouldn't happen, but lets say it's available!
    }
  }
}
