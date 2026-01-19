import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_colors.dart';
import '../../core/formatters.dart';
import '../invoices/data/invoice.dart';
import '../invoices/presentation/invoices_controller.dart';
import '../items/data/item.dart';
import '../items/presentation/items_controller.dart';
import '../users/presentation/users_controller.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoicesAsync = ref.watch(invoicesProvider);
    final itemsAsync = ref.watch(itemsProvider);
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.asData?.value;
    final displayName = (user?.fullName != null && user!.fullName!.isNotEmpty)
        ? user.fullName!
        : (user?.username ?? 'User');

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(
              name: displayName,
              profilePhoto: user?.profilePhoto,
            ),
            const SizedBox(height: 12),
            _StatsRow(invoicesAsync: invoicesAsync, itemsAsync: itemsAsync),
            const SizedBox(height: 16),
            _QuickActions(),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Invoices',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () => context.go('/invoices'),
                    child: const Text(
                      'View All',
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            invoicesAsync.when(
              data: (invoices) {
                final recent = invoices.take(3).toList();
                if (recent.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('No invoices yet.'),
                  );
                }
                return Column(
                  children: recent
                      .map(
                        (invoice) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.05)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    height: 40,
                                    width: 40,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.description, color: AppColors.primary),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        invoice.customerName ?? 'Client',
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        invoice.invoiceNumber ?? 'INV',
                                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    formatCurrency(invoice.totalAmount, currency: invoice.currency),
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  _StatusChip(status: invoice.status),
                                ],
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: LinearProgressIndicator(),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('Error: $e'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String name;
  final String? profilePhoto;

  const _Header({required this.name, this.profilePhoto});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary.withOpacity(0.2),
            backgroundImage: profilePhoto != null ? NetworkImage(profilePhoto!) : null,
            child: profilePhoto == null ? const Icon(Icons.person, color: Colors.white) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Welcome back', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                const SizedBox(height: 4),
                Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_outlined),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final AsyncValue<List<Invoice>> invoicesAsync;
  final AsyncValue<List<Item>> itemsAsync;

  const _StatsRow({required this.invoicesAsync, required this.itemsAsync});

  @override
  Widget build(BuildContext context) {
    double totalSales = 0;
    int activeInvoices = 0;
    int paidInvoices = 0;
    invoicesAsync.whenData((invoices) {
      for (final invoice in invoices) {
        final status = (invoice.status ?? '').toString().toLowerCase();
        if (status == 'paid') {
          totalSales += invoice.totalAmount;
          paidInvoices += 1;
        } else {
          activeInvoices += 1;
        }
      }
    });

    double inventoryValue = 0;
    itemsAsync.whenData((items) {
      for (final item in items) {
        inventoryValue += item.unitPrice * item.stock;
      }
    });

    return SizedBox(
      height: 170,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        children: [
          Container(
            width: 280,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Total Sales', style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 6),
                Text(
                  formatCurrency(totalSales),
                  style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Row(
                  children: [
                    const Icon(Icons.receipt_long, color: Colors.white, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'Paid invoices: $paidInvoices',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _StatCard(
            title: 'Active Invoices',
            value: activeInvoices.toString(),
            icon: Icons.pending_actions,
            iconColor: Colors.orange,
          ),
          const SizedBox(width: 12),
          _StatCard(
            title: 'Inventory Value',
            value: formatCurrency(inventoryValue),
            icon: Icons.inventory_2,
            iconColor: Colors.green,
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ActionCard(
                  title: 'Scan Item',
                  subtitle: 'Identify inventory',
                  icon: Icons.qr_code_scanner,
                  onTap: () => context.push('/ai-scanner'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionCard(
                  title: 'Scan Bill',
                  subtitle: 'Expense manager',
                  icon: Icons.receipt_long,
                  onTap: () => context.push('/checkout'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 150,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.white.withOpacity(0.06),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Container(
                height: 32,
                width: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
            ),
            const Spacer(),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();
    Color color;
    String label;
    switch (normalized) {
      case 'paid':
        color = Colors.green;
        label = 'PAID';
        break;
      case 'overdue':
        color = Colors.redAccent;
        label = 'OVERDUE';
        break;
      case 'pending':
        color = Colors.orange;
        label = 'PENDING';
        break;
      default:
        color = Colors.blueGrey;
        label = status.toUpperCase();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}
