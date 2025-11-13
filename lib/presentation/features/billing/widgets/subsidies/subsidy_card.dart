import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/presentation/features/billing/widgets/subsidies/subsidies_section.dart';

class SubsidyCard extends StatefulWidget {
  const SubsidyCard({
    super.key,
    required this.subsidy,
    this.onDelete,
    this.onEdit,
    this.onLongPress,
  });

  final SubsidyItem subsidy;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onLongPress;

  @override
  State<SubsidyCard> createState() => _SubsidyCardState();
}

class _SubsidyCardState extends State<SubsidyCard> {
  bool _isExpanded = false;
  @override
  Widget build(BuildContext context) {
    final SubsidyItem subsidyItem = widget.subsidy;
    return IntrinsicHeight(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x1A162831), width: 1),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            onLongPress: widget.onLongPress,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _buildHeader(subsidyItem),
                if (_isExpanded) ...<Widget>[
                  const Divider(
                    height: 1,
                    thickness: 1,
                    indent: 16,
                    endIndent: 16,
                    color: Color(0xFFE9ECEF),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        _detailRow(
                          'Invoiced',
                          NumberFormat.currency(
                            locale: 'en_US',
                            symbol: '\$',
                            decimalDigits: 0,
                          ).format(subsidyItem.invoiced),
                        ),
                        const SizedBox(height: 12),
                        _detailRow(
                          'Received',
                          NumberFormat.currency(
                            locale: 'en_US',
                            symbol: '\$',
                            decimalDigits: 0,
                          ).format(subsidyItem.received),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    //child: _buildActions(statusLower),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(SubsidyItem subsidyItem) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.center,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  subsidyItem.subsidyName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                    color: Color(0xff573353),
                    height: 19 / 15,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _isExpanded && subsidyItem.balance != null
                ? NumberFormat.currency(
                    locale: 'en_US',
                    symbol: '\$',
                    decimalDigits: 0,
                  ).format(subsidyItem.balance)
                : '-',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontWeight: FontWeight.w500,
              fontSize: 15,
              color: Color(0xff573353),
            ),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Color(0xff573353),
              height: 16 / 12,
            ),
            textAlign: TextAlign.left,
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xff573353),
              height: 19 / 14,
            ),
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
