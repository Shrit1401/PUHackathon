import 'package:flutter/material.dart';

import '../../../../core/widgets/glass_card.dart';
import '../../../../models/shelter.dart';

class ShelterTile extends StatelessWidget {
  const ShelterTile({
    super.key,
    required this.shelter,
    required this.distanceKm,
  });

  final Shelter shelter;
  final double? distanceKm;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Row(
        children: [
          const Icon(Icons.home_work_outlined),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${shelter.name} - ${shelter.availableSlots}/${shelter.capacity} slots',
            ),
          ),
          if (distanceKm != null) Text('${distanceKm!.toStringAsFixed(1)} km'),
        ],
      ),
    );
  }
}
