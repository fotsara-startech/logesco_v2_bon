import 'package:flutter/material.dart';
import '../models/receipt_model.dart';
import '../models/print_format.dart' as print_models;
import '../utils/amount_in_words.dart';
import 'receipt_template_base.dart';

/// Template de reçu pour imprimante matricielle (papier continu à picots).
///
/// Contrairement aux autres templates, celui-ci n'utilise ni couleurs, ni
/// images, ni bordures dessinées : uniquement du texte en police fixe
/// (monospace), pour refléter fidèlement ce qu'une imprimante à aiguilles
/// produit réellement (mode texte ESC/P). Les colonnes du tableau sont
/// alignées par espacement, pas par une grille.
class ReceiptTemplateMatriciel extends ReceiptTemplateBase {
  const ReceiptTemplateMatriciel({
    Key? key,
    required Receipt receipt,
    required print_models.PrintTemplate template,
    bool showPreview = false,
  }) : super(
          key: key,
          receipt: receipt,
          template: template,
          showPreview: showPreview,
        );

  static const int _cols = 80;
  // Retrait supplémentaire pour les blocs alignés à droite (n° facture/date,
  // récapitulatif des totaux) — aligné sur receipt_preview_page.dart, où
  // cette valeur a été confirmée nécessaire sur impression réelle.
  static const double _rightInset = 16.0;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontFamily: 'monospace',
      fontSize: template.fontSize,
      color: Colors.black,
      height: 1.3,
    );
    final boldStyle = style.copyWith(fontWeight: FontWeight.bold);
    final titleStyle = style.copyWith(fontWeight: FontWeight.bold, fontSize: template.titleFontSize);

    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(
        template.margins.left,
        template.margins.top,
        template.margins.right,
        template.margins.bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          ..._buildHeaderLines(style, boldStyle),
          const SizedBox(height: 6),
          Text('-' * _cols, style: style),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(receipt.isProforma ? t('proformaInvoice') : t('invoice'), style: titleStyle),
              Padding(
                padding: const EdgeInsets.only(right: _rightInset),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${t('saleNumber')}: ${receipt.saleNumber}', style: style),
                    Text(
                      '${t('date')}: ${receipt.saleDate.day.toString().padLeft(2, '0')}/${receipt.saleDate.month.toString().padLeft(2, '0')}/${receipt.saleDate.year}',
                      style: style,
                    ),
                  ],
                ),
              ),
            ],
          ),
          Text('-' * _cols, style: style),
          const SizedBox(height: 4),
          if (receipt.customer != null) ...[
            Text('${t('billedTo')}: ${receipt.customer!.nom}', style: boldStyle),
            if (receipt.customer!.nui?.isNotEmpty == true) Text('NUI: ${receipt.customer!.nui}', style: style),
            if (receipt.customer!.rccm?.isNotEmpty == true) Text('RCCM: ${receipt.customer!.rccm}', style: style),
            const SizedBox(height: 4),
          ],
          Text('-' * _cols, style: style),
          Text(_row(t('reference'), t('designation'), t('quantity'), t('unitPrice'), t('discount'), t('netUnitPrice'), t('total')), style: boldStyle),
          Text('-' * _cols, style: style),
          ...receipt.items.map((item) {
            final puGross = item.hasDiscount ? item.displayPrice : item.unitPrice;
            return Text(
              _row(
                item.productReference,
                item.productName,
                item.quantity.toString(),
                puGross.toStringAsFixed(0),
                item.hasDiscount ? item.discountAmount.toStringAsFixed(0) : '',
                item.unitPrice.toStringAsFixed(0),
                item.totalPrice.toStringAsFixed(0),
              ),
              style: style,
            );
          }),
          Text('-' * _cols, style: style),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: _rightInset),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (receipt.discountAmount > 0) Text('${t('subtotal')}: ${receipt.subtotal.toStringAsFixed(0)}', style: style),
                  if (receipt.discountAmount > 0) Text('${t('discount')}: -${receipt.discountAmount.toStringAsFixed(0)}', style: style),
                  if (receipt.tvaAmount > 0)
                    Text(
                      'TVA (${receipt.tvaRate % 1 == 0 ? receipt.tvaRate.toStringAsFixed(0) : receipt.tvaRate.toStringAsFixed(2)}%): +${receipt.tvaAmount.toStringAsFixed(0)}',
                      style: style,
                    ),
                  Text('${t('netToPay')}: ${receipt.totalAmount.toStringAsFixed(0)}', style: boldStyle.copyWith(fontSize: template.fontSize + 1)),
                  Text('${t('paid')}: ${receipt.paidAmount.toStringAsFixed(0)}', style: style),
                  if (receipt.paidAmount > receipt.totalAmount)
                    Text('${t('change')}: ${(receipt.paidAmount - receipt.totalAmount).toStringAsFixed(0)}', style: boldStyle),
                  if (receipt.remainingAmount > 0) Text('${t('remaining')}: ${receipt.remainingAmount.toStringAsFixed(0)}', style: boldStyle),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text('${t('amountInWordsLabel')}:', style: style),
          Text(amountInWordsFcfa(receipt.totalAmount), style: boldStyle),
          const SizedBox(height: 4),
          Text('-' * _cols, style: style),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(t('seller'), style: style),
              Text(t('clientSignature'), style: style),
              Text(t('cashier'), style: style),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  List<Widget> _buildHeaderLines(TextStyle style, TextStyle boldStyle) {
    final company = receipt.companyInfo;
    final lines = <String>[
      company.name.toUpperCase(),
      if (company.address.isNotEmpty) company.address,
      if (company.location?.isNotEmpty == true) company.location!,
      if (company.phone?.isNotEmpty == true) '${t('phone')}: ${company.phone}',
      if (company.email?.isNotEmpty == true) '${t('email')}: ${company.email}',
      if (company.nuiRccm?.isNotEmpty == true) '${t('nuiRccm')}: ${company.nuiRccm}',
    ];
    return lines
        .asMap()
        .entries
        .map((e) => Center(child: Text(e.value, style: e.key == 0 ? boldStyle : style)))
        .toList();
  }

  /// Ligne de tableau alignée sur 80 colonnes :
  /// Référence(9) Désignation(22) Qté(4) PU(9) Remise(7) PU Net(9) Total(11)
  String _row(String ref, String desig, String qte, String pu, String remise, String puNet, String total) {
    return '${_fit(ref, 9)} ${_fit(desig, 22)} ${_fitRight(qte, 4)} ${_fitRight(pu, 9)} ${_fitRight(remise, 7)} ${_fitRight(puNet, 9)} ${_fitRight(total, 11)}';
  }

  String _fit(String text, int width) {
    final t = text.length > width ? text.substring(0, width) : text;
    return t.padRight(width);
  }

  String _fitRight(String text, int width) {
    final t = text.length > width ? text.substring(text.length - width) : text;
    return t.padLeft(width);
  }
}
