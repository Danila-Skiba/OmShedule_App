import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../core/utils/platform_utils.dart';
import '../data/mock_data.dart';
import '../models/building.dart';

/// Карты/корпуса (эквивалент Maps.tsx)
class MapsScreen extends StatelessWidget {
  const MapsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentBuilding = MockData.buildings[2]; // Корпус 3
    final theme = Theme.of(context);

    return ColoredBox(
      color: theme.scaffoldBackgroundColor, // iOS — theme-aware
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(currentBuilding)),
          SliverToBoxAdapter(child: _buildMapPreview(currentBuilding)),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildQuickActions(),
                const SizedBox(height: 16),
                _buildBuildingInfo(currentBuilding),
                const SizedBox(height: 16),
                _buildNextLessonCard(),
                const SizedBox(height: 16),
                _buildAllBuildings(),
                const SizedBox(height: 16),
                _buildNearbyPlaces(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Building building) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            const Icon(Icons.location_on_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    building.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    building.address,
                    style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.9)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapPreview(Building building) {
    return Container(
      height: 256,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE0E7FF), Color(0xFFDBEAFE)],
        ),
        border: Border(bottom: BorderSide(color: AppColors.primaryLight, width: 4)),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.backgroundAlt,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(blurRadius: 12, color: Colors.black12)],
              ),
              child: Stack(
                children: [
                  // Grid
                  GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 8,
                      childAspectRatio: 1,
                    ),
                    itemCount: 48,
                    itemBuilder: (_, __) => Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.textSecondary.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                  ),
                  // Roads and buildings
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: const [BoxShadow(blurRadius: 8, color: Colors.black26)],
                          ),
                          child: const Icon(
                            Icons.location_on_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 32,
            right: 32,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(999),
                boxShadow: const [BoxShadow(blurRadius: 8, color: Colors.black12)],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.navigation_rounded, color: AppColors.primaryLight, size: 16),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        building.distance,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        building.walkTime,
                        style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return const Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: Icons.navigation_rounded,
            label: 'Маршрут',
            primary: true,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            icon: Icons.coffee_rounded,
            label: 'Кафе',
            primary: false,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            icon: Icons.local_parking_rounded,
            label: 'Парковки',
            primary: false,
          ),
        ),
      ],
    );
  }

  Widget _buildBuildingInfo(Building building) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.location_on_rounded, size: 16, color: AppColors.primaryLight),
              SizedBox(width: 8),
              Text(
                'Информация о корпусе',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _InfoRow(label: 'Адрес', value: building.address),
          _InfoRow(label: 'Расстояние', value: '${building.distance} • ${building.walkTime}'),
          _InfoRow(label: 'Кафе в корпусе', value: building.hasCafe ? 'Да' : 'Нет'),
        ],
      ),
    );
  }

  Widget _buildNextLessonCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryLight, AppColors.primary],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(blurRadius: 12, color: Colors.black26)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.access_time_rounded, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Text(
                'Ближайшая пара в этом корпусе',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const _WhiteRow(label: 'Аудитория', value: '312 (3 этаж)'),
          const _WhiteRow(label: 'Время', value: '08:30 - 10:15'),
          const _WhiteRow(label: 'Преподаватель', value: 'Петров В.В.'),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.star_rounded, color: AppColors.warning, size: 16),
              const SizedBox(width: 4),
              const Text('4.2', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
              Text(' (127 отзывов)', style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.75))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAllBuildings() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Все корпуса',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...MockData.buildings.map(
            (b) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.location_on_rounded, color: AppColors.primaryLight, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                b.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                              Text(
                                b.address,
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              b.distance,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                            Text(
                              b.walkTime,
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNearbyPlaces() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.coffee_rounded, size: 16, color: AppColors.warning),
              SizedBox(width: 8),
              Text(
                'Рядом с корпусом',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          _NearbyPlaceRow(
            title: 'Столовая ОмГТУ',
            distance: '50м • 1 мин',
            rating: '4.5 (234)',
            iconColor: AppColors.warning,
          ),
          SizedBox(height: 12),
          _NearbyPlaceRow(
            title: 'Кофейня "Энергия"',
            distance: '120м • 2 мин',
            rating: '4.8 (89)',
            iconColor: AppColors.success,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool primary;

  const _ActionButton({required this.icon, required this.label, required this.primary});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: primary ? AppColors.primaryLight : AppColors.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: primary ? null : Border.all(color: AppColors.border),
            boxShadow: primary ? [const BoxShadow(blurRadius: 8, color: Colors.black12)] : null,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 24,
                color: primary ? Colors.white : AppColors.primary,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: primary ? Colors.white : AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

class _WhiteRow extends StatelessWidget {
  final String label;
  final String value;

  const _WhiteRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.9))),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }
}

class _NearbyPlaceRow extends StatelessWidget {
  final String title;
  final String distance;
  final String rating;
  final Color iconColor;

  const _NearbyPlaceRow({
    required this.title,
    required this.distance,
    required this.rating,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.coffee_rounded, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              Text(
                distance,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              Row(
                children: [
                  const Icon(Icons.star_rounded, size: 12, color: AppColors.warning),
                  const SizedBox(width: 4),
                  Text(rating, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.phone_rounded, color: AppColors.primaryLight, size: 16),
          onPressed: () {},
        ),
      ],
    );
  }
}
