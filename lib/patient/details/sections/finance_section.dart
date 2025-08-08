import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../design_system/design_system_screen.dart' show NeoCard, DesignTokens;
import '../../../payment.dart';

final priceFormatter = NumberFormat('#,###', 'ru_RU');

class FinanceSection extends StatefulWidget {
  final Map<String, dynamic> patientData;
  final String patientId;
  final int selectedIndex;

  const FinanceSection({
    Key? key,
    required this.patientData,
    required this.patientId,
    required this.selectedIndex,
  }) : super(key: key);

  @override
  _FinanceSectionState createState() => _FinanceSectionState();
}

class _FinanceSectionState extends State<FinanceSection> with AutomaticKeepAliveClientMixin<FinanceSection> {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    // Only perform heavy calculations when this section is visible (selectedIndex == 2)
    final isVisible = widget.selectedIndex == 2;
    if (!isVisible) {
      return Container(
        key: ValueKey<int>(2),
        padding: const EdgeInsets.all(20),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    final paymentsData = widget.patientData['payments'] as List<dynamic>? ?? [];
    final payments = paymentsData.map((p) => Payment.fromMap(p)).toList();
    final totalPaid = payments.fold<double>(0, (sum, p) => sum + p.amount);
    final price = (widget.patientData['price'] ?? 0) as num;
    final remain = price - totalPaid;
    
    return Container(
      key: ValueKey<int>(2),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Финансовые показатели
          Row(
            children: [
              _buildFinanceMetricCard(
                '💵 Стоимость лечения',
                '${priceFormatter.format(price)} ₽',
                DesignTokens.accentPrimary,
                'Общая стоимость',
              ),
              const SizedBox(width: 16),
              _buildFinanceMetricCard(
                '✅ Оплачено',
                '${priceFormatter.format(totalPaid)} ₽',
                DesignTokens.accentSuccess,
                '${payments.length} платежей',
              ),
              const SizedBox(width: 16),
              _buildFinanceMetricCard(
                '⏳ Остаток',
                '${priceFormatter.format(remain)} ₽',
                remain > 0 ? DesignTokens.accentWarning : DesignTokens.accentSuccess,
                remain > 0 ? 'К оплате' : 'Оплачено полностью',
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // История платежей
          Expanded(
            child: NeoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text('📜', style: TextStyle(fontSize: 24)),
                          const SizedBox(width: 8),
                          Text('История платежей', style: DesignTokens.h3),
                        ],
                      ),
                      Text(
                        'Всего: ${payments.length}',
                        style: DesignTokens.body.copyWith(
                          color: DesignTokens.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: _buildPaymentsList(payments),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Карточка финансовой метрики
  Widget _buildFinanceMetricCard(String title, String value, Color color, String subtitle) {
    final parts = title.split(' ');
    final emoji = parts[0];
    final text = parts.sublist(1).join(' ');
    
    return Expanded(
      child: NeoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    text,
                    style: DesignTokens.h4,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: DesignTokens.h2.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: DesignTokens.small.copyWith(
                color: DesignTokens.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentsList(List<Payment> payments) {
    if (payments.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.payment_outlined,
              size: 64,
              color: DesignTokens.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              'Нет платежей',
              style: DesignTokens.body.copyWith(
                color: DesignTokens.textMuted,
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      itemCount: payments.length,
      itemBuilder: (context, index) {
        final payment = payments[payments.length - 1 - index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: NeoCard.inset(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: DesignTokens.accentSuccess.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: DesignTokens.body.copyWith(
                          color: DesignTokens.accentSuccess,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${priceFormatter.format(payment.amount)} ₽',
                          style: DesignTokens.h4.copyWith(
                            color: DesignTokens.accentSuccess,
                          ),
                        ),
                        Text(
                          DateFormat('dd.MM.yyyy в HH:mm').format(payment.date),
                          style: DesignTokens.small.copyWith(
                            color: DesignTokens.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}