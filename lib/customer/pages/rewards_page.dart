import 'package:flutter/material.dart';

import '../../app/format.dart';
import '../../app/theme.dart';
import '../data/customer_store.dart';
import '../data/models.dart';
import '../widgets/common.dart';
import 'reward_detail_page.dart';

/// Saldo poin dan katalog hadiah (FR-C7).
class RewardsPage extends StatefulWidget {
  const RewardsPage({super.key});

  @override
  State<RewardsPage> createState() => _RewardsPageState();
}

class _RewardsPageState extends State<RewardsPage> {
  RewardCategory? _category;

  @override
  Widget build(BuildContext context) {
    final store = CustomerScope.of(context);
    final rewards = store.rewards
        .where((r) => _category == null || r.category == _category)
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SALDO POIN ANDA',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.lime,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${formatNumber(store.points)} poin',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Akumulasi setoran dari seluruh mitra pilihan Anda',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.white.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Poin diperoleh bulan ini',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                    Text(
                      '+${formatNumber(store.pointsThisMonth)} poin',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.lime,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const PageHeading(
          'Hadiah Untuk Anda',
          'Tukarkan poin dengan hadiah pilihan.',
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _CategoryChip(
                label: 'Semua',
                selected: _category == null,
                onTap: () => setState(() => _category = null),
              ),
              for (final c in RewardCategory.values)
                _CategoryChip(
                  label: c.label,
                  selected: _category == c,
                  onTap: () => setState(() => _category = c),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: rewards.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: 268,
          ),
          itemBuilder: (context, i) =>
              _RewardCard(reward: rewards[i], balance: store.points),
        ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.primary,
        backgroundColor: AppColors.white,
        side: BorderSide(color: selected ? AppColors.primary : AppColors.line),
        labelStyle: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: selected ? AppColors.white : AppColors.ink,
        ),
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  const _RewardCard({required this.reward, required this.balance});
  final Reward reward;
  final int balance;

  @override
  Widget build(BuildContext context) {
    final enough = reward.points <= balance;
    void open() => Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => RewardDetailPage(reward: reward)));

    return AppCard(
      padding: const EdgeInsets.all(12),
      onTap: open,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: reward.category.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                reward.initials,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: reward.category.foreground,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            reward.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${formatNumber(reward.points)} poin',
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          const Spacer(),
          FilledButton(
            onPressed: enough ? open : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(38),
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: Text(enough ? 'Tukar Hadiah' : 'Poin belum cukup'),
          ),
        ],
      ),
    );
  }
}
