import 'blocks.dart';

/// An immutable stack of items. `count == 0` means empty.
class ItemStack {
  const ItemStack(this.id, this.count);

  static const empty = ItemStack(0, 0);

  final int id;
  final int count;

  bool get isEmpty => count <= 0 || id == 0;
  bool get isNotEmpty => !isEmpty;
  int get maxStack => Registry.item(id).maxStack;
  ItemDef get def => Registry.item(id);

  ItemStack withCount(int c) => c <= 0 ? empty : ItemStack(id, c);

  bool sameKind(ItemStack o) => isNotEmpty && o.isNotEmpty && id == o.id;

  List<int> toJson() => isEmpty ? const [0, 0] : [id, count];

  static ItemStack fromJson(Object? j) {
    if (j is List && j.length >= 2) {
      final id = (j[0] as num).toInt();
      final c = (j[1] as num).toInt();
      return c <= 0 || id == 0 ? empty : ItemStack(id, c);
    }
    return empty;
  }

  @override
  String toString() => isEmpty ? 'empty' : '${Registry.nameOf(id)} x$count';

  @override
  bool operator ==(Object other) =>
      other is ItemStack && ((isEmpty && other.isEmpty) || (id == other.id && count == other.count));

  @override
  int get hashCode => isEmpty ? 0 : Object.hash(id, count);
}

/// Fixed-size slot container with the stacking rules used everywhere
/// (player inventory, chests, kiln, crafting grids).
class SlotList {
  SlotList(int size) : slots = List<ItemStack>.filled(size, ItemStack.empty);

  SlotList.from(List<ItemStack> s) : slots = List<ItemStack>.of(s);

  final List<ItemStack> slots;

  int get length => slots.length;

  ItemStack operator [](int i) => slots[i];

  void operator []=(int i, ItemStack s) => slots[i] = s;

  bool get isEmpty => slots.every((s) => s.isEmpty);

  /// Adds [stack] into the first matching partial stacks then empty slots,
  /// searching indices in [order] (defaults to natural order). Returns the
  /// remainder that did not fit.
  ItemStack add(ItemStack stack, {List<int>? order}) {
    if (stack.isEmpty) return ItemStack.empty;
    var remaining = stack.count;
    final idx = order ?? List<int>.generate(slots.length, (i) => i);
    for (final i in idx) {
      final s = slots[i];
      if (s.isNotEmpty && s.id == stack.id && s.count < s.maxStack) {
        final take = (s.maxStack - s.count).clamp(0, remaining);
        slots[i] = s.withCount(s.count + take);
        remaining -= take;
        if (remaining == 0) return ItemStack.empty;
      }
    }
    for (final i in idx) {
      if (slots[i].isEmpty) {
        final take = remaining.clamp(0, stack.maxStack);
        slots[i] = ItemStack(stack.id, take);
        remaining -= take;
        if (remaining == 0) return ItemStack.empty;
      }
    }
    return stack.withCount(remaining);
  }

  int countOf(int id) => slots.where((s) => s.id == id).fold(0, (a, s) => a + s.count);

  /// Removes up to [count] of [id]; returns how many were removed.
  int remove(int id, int count) {
    var left = count;
    for (var i = 0; i < slots.length && left > 0; i++) {
      final s = slots[i];
      if (s.id == id && s.isNotEmpty) {
        final take = s.count < left ? s.count : left;
        slots[i] = s.withCount(s.count - take);
        left -= take;
      }
    }
    return count - left;
  }

  List<List<int>> toJson() => slots.map((s) => s.toJson()).toList();

  static SlotList fromJson(Object? j, int size) {
    final out = SlotList(size);
    if (j is List) {
      for (var i = 0; i < size && i < j.length; i++) {
        out.slots[i] = ItemStack.fromJson(j[i]);
      }
    }
    return out;
  }
}

/// Player inventory layout: 0..8 hotbar, 9..35 main storage.
class Inventory {
  static const hotbarSize = 9;
  static const size = 36;
  static const preferredFillOrder = <int>[
    0, 1, 2, 3, 4, 5, 6, 7, 8, //
    9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27,
    28, 29, 30, 31, 32, 33, 34, 35,
  ];
}
