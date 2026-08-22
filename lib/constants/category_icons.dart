import 'package:flutter/material.dart';

/// The fixed, curated set of Material icons a category may use. Every entry
/// is a compile-time constant [IconData] literal, so Flutter's icon
/// tree-shaking (release builds) can keep exactly these glyphs and nothing
/// breaks — see [resolveCategoryIcon].
const List<IconData> kMaterialCategoryIcons = [
  Icons.restaurant_rounded, Icons.coffee_rounded, Icons.local_pizza_rounded,
  Icons.lunch_dining_rounded, Icons.icecream_rounded, Icons.local_bar_rounded,
  Icons.shopping_bag_rounded, Icons.shopping_cart_rounded, Icons.store_rounded,
  Icons.checkroom_rounded, Icons.face_rounded, Icons.brush_rounded,
  Icons.directions_car_rounded, Icons.two_wheeler_rounded, Icons.flight_rounded,
  Icons.directions_bus_rounded, Icons.train_rounded, Icons.local_gas_station_rounded,
  Icons.home_rounded, Icons.king_bed_rounded, Icons.light_rounded,
  Icons.water_drop_rounded, Icons.foundation_rounded, Icons.fence_rounded,
  Icons.phone_rounded, Icons.laptop_rounded, Icons.headphones_rounded,
  Icons.camera_alt_rounded, Icons.smartphone_rounded, Icons.tablet_rounded,
  Icons.attach_money_rounded, Icons.account_balance_rounded, Icons.savings_rounded,
  Icons.receipt_long_rounded, Icons.credit_card_rounded, Icons.payments_rounded,
  Icons.favorite_rounded, Icons.local_hospital_rounded, Icons.medical_services_rounded,
  Icons.fitness_center_rounded, Icons.spa_rounded, Icons.monitor_heart_rounded,
  Icons.sports_esports_rounded, Icons.movie_rounded, Icons.music_note_rounded,
  Icons.sports_football_rounded, Icons.palette_rounded, Icons.brush_rounded,
  Icons.school_rounded, Icons.menu_book_rounded, Icons.science_rounded,
  Icons.build_rounded, Icons.engineering_rounded, Icons.architecture_rounded,
  Icons.pets_rounded, Icons.catching_pokemon_rounded, Icons.eco_rounded,
  Icons.flight_takeoff_rounded, Icons.map_rounded, Icons.beach_access_rounded,
  Icons.workspace_premium_rounded, Icons.emoji_events_rounded, Icons.star_rounded,
  Icons.workspace_premium_rounded, Icons.card_giftcard_rounded, Icons.celebration_rounded,
  Icons.notifications_rounded, Icons.mail_rounded, Icons.chat_rounded,
  Icons.bookmark_rounded, Icons.flag_rounded, Icons.push_pin_rounded,
];

/// Resolves a stored [iconCodePoint] to its constant [IconData] from
/// [kMaterialCategoryIcons]. Because the lookup returns one of those
/// constant literals, no `IconData(int)` is ever constructed at runtime, so
/// release builds can tree-shake icons without error.
///
/// Code points that don't match (e.g. 0 for system/imported categories)
/// fall back to [Icons.star_rounded].
IconData resolveCategoryIcon(int iconCodePoint) {
  for (final icon in kMaterialCategoryIcons) {
    if (icon.codePoint == iconCodePoint) return icon;
  }
  return Icons.star_rounded;
}
