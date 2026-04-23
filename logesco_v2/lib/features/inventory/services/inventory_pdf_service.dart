import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';
import 'package:get/get.dart';
import '../models/stock_model.dart';
import '../../company_settings/models/company_profile.dart';
import '../../company_settings/services/company_settings_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/config/app_config.dart';
import '../../boutiques/controllers/boutique_controller.dart';

/// Service d'export PDF pour les stocks et mouvements de stock
class InventoryPdfService {
  static final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');
  static final _shortDate = DateFormat('dd/MM/yyyy');
  static final _numberFormat = NumberFormat('#,##0', 'fr_FR');

  // Palette de couleurs
  static final _primary = PdfColor.fromHex('#1e40af');
  static final _grey = PdfColor.fromHex('#6b7280');
  static final _greyBg = PdfColor.fromHex('#f3f4f6');
  static final _greyBorder = PdfColor.fromHex('#d1d5db');

  // Couleurs des cartes résumé
  static final _cardBlue = PdfColor.fromHex('#3b82f6');
  static final _cardBlueBg = PdfColor.fromHex('#eff6ff');
  static final _cardGreen = PdfColor.fromHex('#16a34a');
  static final _cardGreenBg = PdfColor.fromHex('#f0fdf4');
  static final _cardOrange = PdfColor.fromHex('#ea580c');
  static final _cardOrangeBg = PdfColor.fromHex('#fff7ed');
  static final _cardRed = PdfColor.fromHex('#dc2626');
  static final _cardRedBg = PdfColor.fromHex('#fef2f2');

  // ─── FETCH COMPANY ────────────────────────────────────────────────────────

  static Future<CompanyProfile?> _fetchCompany() async {
    try {
      final auth = Get.isRegistered<AuthService>() ? Get.find<AuthService>() : AuthService();
      final svc = CompanySettingsService(auth);
      final res = await svc.getCompanyProfile();
      return res.isSuccess ? res.data : null;
    } catch (_) {
      return null;
    }
  }

  static Future<Uint8List?> _fetchLogo(CompanyProfile? profile) async {
    if (profile?.logo == null || profile!.logo!.isEmpty) return null;
    try {
      var path = profile.logo!.replaceAll('\\', '/').split('/').last;
      final url = '${AppConfig.currentBaseUrl.replaceAll('/api/v1', '')}/uploads/$path';
      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      return res.statusCode == 200 ? res.bodyBytes : null;
    } catch (_) {
      return null;
    }
  }

  // ─── PUBLIC API ───────────────────────────────────────────────────────────

  static Future<String?> exportStocksToPdf(List<Stock> stocks, {String? boutiqueName}) async {
    try {
      final company = await _fetchCompany();
      final logo = await _fetchLogo(company);
      final now = DateTime.now();

      // Récupérer le nom de la boutique active si non fourni
      final activeBoutiqueName = boutiqueName ?? await _getActiveBoutiqueName();

      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(24),
          header: (_) => _buildCompanyHeader(company, logo, 'Rapport de stock', _shortDate.format(now), boutiqueName: activeBoutiqueName),
          footer: (ctx) => _buildFooter(ctx),
          build: (_) => [
            pw.SizedBox(height: 12),
            _buildStockSummaryCards(stocks),
            pw.SizedBox(height: 14),
            _buildStockTable(stocks),
          ],
        ),
      );
      return await _save(pdf, 'stock_export');
    } catch (_) {
      return null;
    }
  }

  static Future<String?> exportMovementsToPdf(List<StockMovement> movements, {String? boutiqueName}) async {
    try {
      final company = await _fetchCompany();
      final logo = await _fetchLogo(company);
      final now = DateTime.now();

      // Récupérer le nom de la boutique active si non fourni
      final activeBoutiqueName = boutiqueName ?? await _getActiveBoutiqueName();

      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(24),
          header: (_) => _buildCompanyHeader(company, logo, 'Rapport des mouvements de stock', _shortDate.format(now), boutiqueName: activeBoutiqueName),
          footer: (ctx) => _buildFooter(ctx),
          build: (_) => [
            pw.SizedBox(height: 12),
            _buildMovementsSummaryCards(movements),
            pw.SizedBox(height: 14),
            _buildMovementsTable(movements),
          ],
        ),
      );
      return await _save(pdf, 'mouvements_export');
    } catch (_) {
      return null;
    }
  }

  static Future<void> sharePdf(String filePath) async {
    await Share.shareXFiles([XFile(filePath)], text: 'Export PDF - LOGESCO');
  }

  /// Ouvre automatiquement le fichier PDF après export
  static Future<void> openPdf(String filePath) async {
    try {
      final result = await OpenFile.open(filePath);
      if (result.type != ResultType.done) {
        print('⚠️ Impossible d\'ouvrir le PDF: ${result.message}');
        // Fallback vers le partage si l'ouverture échoue
        await Share.shareXFiles([XFile(filePath)], text: 'Export PDF - LOGESCO');
      }
    } catch (e) {
      print('⚠️ Erreur lors de l\'ouverture du PDF: $e');
      // Fallback vers le partage en cas d'erreur
      try {
        await Share.shareXFiles([XFile(filePath)], text: 'Export PDF - LOGESCO');
      } catch (shareError) {
        print('⚠️ Erreur lors du partage PDF: $shareError');
      }
    }
  }

  /// Récupère le nom de la boutique active
  static Future<String?> _getActiveBoutiqueName() async {
    try {
      if (Get.isRegistered<BoutiqueController>()) {
        final controller = Get.find<BoutiqueController>();
        return controller.boutiquesActive.value?.nom;
      }
      return null;
    } catch (e) {
      print('⚠️ Erreur lors de la récupération du nom de la boutique: $e');
      return null;
    }
  }

  // ─── EN-TÊTE ENTREPRISE ───────────────────────────────────────────────────

  static pw.Widget _buildCompanyHeader(CompanyProfile? company, Uint8List? logo, String reportTitle, String date, {String? boutiqueName}) {
    return pw.Column(children: [
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Bloc gauche : logo + infos entreprise
          pw.Expanded(
            flex: 2,
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (logo != null)
                  pw.Container(
                    width: 52,
                    height: 52,
                    margin: const pw.EdgeInsets.only(right: 10),
                    child: pw.Image(pw.MemoryImage(logo), fit: pw.BoxFit.contain),
                  ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        (company?.name ?? 'LOGESCO').toUpperCase(),
                        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: _primary),
                      ),
                      if (company?.slogan != null && company!.slogan!.isNotEmpty) ...[
                        pw.SizedBox(height: 2),
                        pw.Text(company.slogan!, style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic, color: _grey)),
                      ],
                      if (company?.address.isNotEmpty == true) ...[
                        pw.SizedBox(height: 3),
                        pw.Text(company!.address, style: const pw.TextStyle(fontSize: 9)),
                      ],
                      if (company?.location?.isNotEmpty == true) ...[
                        pw.SizedBox(height: 2),
                        pw.Text(company!.location!, style: const pw.TextStyle(fontSize: 9)),
                      ],
                      if (company?.phone?.isNotEmpty == true) ...[
                        pw.SizedBox(height: 2),
                        pw.Text('Tél : ${company!.phone}', style: const pw.TextStyle(fontSize: 9)),
                      ],
                      if (company?.email?.isNotEmpty == true) ...[
                        pw.SizedBox(height: 2),
                        pw.Text('Email : ${company!.email}', style: const pw.TextStyle(fontSize: 9)),
                      ],
                      if (company?.nuiRccm?.isNotEmpty == true) ...[
                        pw.SizedBox(height: 2),
                        pw.Text('NUI/RCCM : ${company!.nuiRccm}', style: const pw.TextStyle(fontSize: 9)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Bloc droit : titre du rapport + boutique
          pw.Expanded(
            flex: 1,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(reportTitle, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: _primary), textAlign: pw.TextAlign.right),
                pw.SizedBox(height: 4),
                pw.Text('Date : $date', style: pw.TextStyle(fontSize: 9, color: _grey), textAlign: pw.TextAlign.right),
                if (boutiqueName != null) ...[
                  pw.SizedBox(height: 4),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: pw.BoxDecoration(
                      color: _cardBlueBg,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                      border: pw.Border.all(color: _cardBlue, width: 0.8),
                    ),
                    child: pw.Text(
                      'Boutique : $boutiqueName',
                      style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _cardBlue),
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      pw.SizedBox(height: 8),
      pw.Divider(color: _primary, thickness: 2),
    ]);
  }

  static pw.Widget _buildFooter(pw.Context ctx) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 6),
      decoration: pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(color: _greyBorder))),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Généré par LOGESCO v2', style: pw.TextStyle(fontSize: 8, color: _grey)),
          pw.Text('Page ${ctx.pageNumber} / ${ctx.pagesCount}', style: pw.TextStyle(fontSize: 8, color: _grey)),
        ],
      ),
    );
  }

  // ─── CARTES RÉSUMÉ ────────────────────────────────────────────────────────

  static pw.Widget _buildStockSummaryCards(List<Stock> stocks) {
    final total = stocks.length;
    final rupture = stocks.where((s) => s.quantiteDisponible == 0).length;
    final alerte = stocks.where((s) => (s.stockFaible ?? false) && s.quantiteDisponible > 0).length;
    final ok = total - alerte - rupture;

    return pw.Row(children: [
      _summaryCard('Total produits', total.toString(), _cardBlue, _cardBlueBg),
      pw.SizedBox(width: 8),
      _summaryCard('Stock OK', ok.toString(), _cardGreen, _cardGreenBg),
      pw.SizedBox(width: 8),
      _summaryCard('En alerte', alerte.toString(), _cardOrange, _cardOrangeBg),
      pw.SizedBox(width: 8),
      _summaryCard('En rupture', rupture.toString(), _cardRed, _cardRedBg),
    ]);
  }

  static pw.Widget _buildMovementsSummaryCards(List<StockMovement> movements) {
    final total = movements.length;
    final entrees = movements.where((m) => m.changementQuantite > 0).length;
    final sorties = movements.where((m) => m.changementQuantite < 0).length;
    final net = movements.fold<int>(0, (s, m) => s + m.changementQuantite);

    return pw.Row(children: [
      _summaryCard('Total mouvements', total.toString(), _cardBlue, _cardBlueBg),
      pw.SizedBox(width: 8),
      _summaryCard('Entrées', entrees.toString(), _cardGreen, _cardGreenBg),
      pw.SizedBox(width: 8),
      _summaryCard('Sorties', sorties.toString(), _cardRed, _cardRedBg),
      pw.SizedBox(width: 8),
      _summaryCard('Variation nette', (net >= 0 ? '+' : '') + net.toString(), net >= 0 ? _cardGreen : _cardRed, net >= 0 ? _cardGreenBg : _cardRedBg),
    ]);
  }

  static pw.Widget _summaryCard(String label, String value, PdfColor textColor, PdfColor bgColor) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: pw.BoxDecoration(
          color: bgColor,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          border: pw.Border.all(color: textColor, width: 0.8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label, style: pw.TextStyle(fontSize: 8, color: _grey)),
            pw.SizedBox(height: 5),
            pw.Text(value, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: textColor)),
          ],
        ),
      ),
    );
  }

  // ─── TABLEAUX ─────────────────────────────────────────────────────────────

  static pw.Widget _buildStockTable(List<Stock> stocks) {
    final headerStyle = pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9);

    return pw.Table(
      border: pw.TableBorder.all(color: _greyBorder, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.2),
        1: const pw.FlexColumnWidth(2.5),
        2: const pw.FlexColumnWidth(1.0),
        3: const pw.FlexColumnWidth(1.0),
        4: const pw.FlexColumnWidth(1.0),
        5: const pw.FlexColumnWidth(1.2),
        6: const pw.FlexColumnWidth(1.5),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _primary),
          children: [
            _cell('Référence', style: headerStyle),
            _cell('Produit', style: headerStyle),
            _cell('Disponible', style: headerStyle, align: pw.TextAlign.center),
            _cell('Réservé', style: headerStyle, align: pw.TextAlign.center),
            _cell('Seuil min.', style: headerStyle, align: pw.TextAlign.center),
            _cell('Statut', style: headerStyle, align: pw.TextAlign.center),
            _cell('Dernière MAJ', style: headerStyle),
          ],
        ),
        ...stocks.asMap().entries.map((e) {
          final i = e.key;
          final s = e.value;
          final isRupture = s.quantiteDisponible == 0;
          final isAlerte = (s.stockFaible ?? false) && !isRupture;
          final rowBg = isRupture
              ? PdfColor.fromHex('#fef2f2')
              : isAlerte
                  ? PdfColor.fromHex('#fff7ed')
                  : i.isEven
                      ? _greyBg
                      : PdfColors.white;
          final statusText = isRupture
              ? 'RUPTURE'
              : isAlerte
                  ? 'ALERTE'
                  : 'OK';
          final statusColor = isRupture
              ? _cardRed
              : isAlerte
                  ? _cardOrange
                  : _cardGreen;

          return pw.TableRow(
            decoration: pw.BoxDecoration(color: rowBg),
            children: [
              _cell(s.produit?.reference ?? '-'),
              _cell(s.produit?.nom ?? 'Produit #${s.produitId}'),
              _cell(_numberFormat.format(s.quantiteDisponible),
                  align: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: isRupture ? _cardRed : PdfColors.black, fontSize: 9)),
              _cell(_numberFormat.format(s.quantiteReservee), align: pw.TextAlign.center),
              _cell(_numberFormat.format(s.produit?.seuilStockMinimum ?? 0), align: pw.TextAlign.center),
              _cell(statusText, align: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: statusColor, fontSize: 9)),
              _cell(_dateFormat.format(s.derniereMaj)),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _buildMovementsTable(List<StockMovement> movements) {
    final headerStyle = pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9);
    final headerBg = pw.BoxDecoration(color: PdfColor.fromHex('#166534'));

    return pw.Table(
      border: pw.TableBorder.all(color: _greyBorder, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.8),
        1: const pw.FlexColumnWidth(1.2),
        2: const pw.FlexColumnWidth(2.2),
        3: const pw.FlexColumnWidth(1.2),
        4: const pw.FlexColumnWidth(0.9),
        5: const pw.FlexColumnWidth(2.0),
      },
      children: [
        pw.TableRow(
          decoration: headerBg,
          children: [
            _cell('Date', style: headerStyle),
            _cell('Référence', style: headerStyle),
            _cell('Produit', style: headerStyle),
            _cell('Type', style: headerStyle, align: pw.TextAlign.center),
            _cell('Qté', style: headerStyle, align: pw.TextAlign.center),
            _cell('Notes', style: headerStyle),
          ],
        ),
        ...movements.asMap().entries.map((e) {
          final i = e.key;
          final m = e.value;
          final isPos = m.changementQuantite > 0;
          return pw.TableRow(
            decoration: pw.BoxDecoration(color: i.isEven ? _greyBg : PdfColors.white),
            children: [
              _cell(_dateFormat.format(m.dateMouvement)),
              _cell(m.produit?.reference ?? '-'),
              _cell(m.produit?.nom ?? 'Produit #${m.produitId}'),
              _cell(_movementLabel(m.typeMouvement), align: pw.TextAlign.center),
              _cell('${isPos ? '+' : ''}${m.changementQuantite}', align: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: isPos ? _cardGreen : _cardRed, fontSize: 9)),
              _cell(m.notes ?? '-', style: pw.TextStyle(fontSize: 8, color: _grey)),
            ],
          );
        }),
      ],
    );
  }

  // ─── HELPERS ──────────────────────────────────────────────────────────────

  static pw.Widget _cell(String text, {pw.TextStyle? style, pw.TextAlign? align}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(text, style: style ?? const pw.TextStyle(fontSize: 9), textAlign: align ?? pw.TextAlign.left),
    );
  }

  static String _movementLabel(String type) {
    switch (type.toLowerCase()) {
      case 'achat':
        return 'Achat';
      case 'vente':
        return 'Vente';
      case 'ajustement':
        return 'Ajustement';
      case 'retour':
        return 'Retour';
      case 'approvisionnement':
        return 'Appro.';
      default:
        return type;
    }
  }

  static Future<String> _save(pw.Document pdf, String prefix) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/${prefix}_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }
}
