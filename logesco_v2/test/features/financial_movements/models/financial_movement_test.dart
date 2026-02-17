// import 'package:flutter_test/flutter_test.dart';
// import 'package:logesco_v2/features/financial_movements/models/financial_movement.dart';

// void main() {
//   group('FinancialMovement', () {
//     test('should create from JSON correctly', () {
//       // Arrange
//       final json = {
//         'id': 1,
//         'reference': 'MOV-001',
//         'montant': 50000.0,
//         'categorieId': 1,
//         'description': 'Achat de fournitures',
//         'date': '2024-01-15T10:30:00.000Z',
//         'utilisateurId': 1,
//         'dateCreation': '2024-01-15T10:30:00.000Z',
//         'dateModification': '2024-01-15T10:30:00.000Z',
//         'notes': 'Notes additionnelles',
//       };

//       // Act
//       final movement = FinancialMovement.fromJson(json);

//       // Assert
//       expect(movement.id, 1);
//       expect(movement.reference, 'MOV-001');
//       expect(movement.montant, 50000.0);
//       expect(movement.categorieId, 1);
//       expect(movement.description, 'Achat de fournitures');
//       expect(movement.utilisateurId, 1);
//       expect(movement.notes, 'Notes additionnelles');
//     });

//     test('should convert to JSON correctly', () {
//       // Arrange
//       final movement = FinancialMovement(
//         id: 1,
//         reference: 'MOV-001',
//         montant: 50000.0,
//         categorieId: 1,
//         description: 'Achat de fournitures',
//         date: DateTime.parse('2024-01-15T10:30:00.000Z'),
//         utilisateurId: 1,
//         dateCreation: DateTime.parse('2024-01-15T10:30:00.000Z'),
//         dateModification: DateTime.parse('2024-01-15T10:30:00.000Z'),
//         notes: 'Notes additionnelles',
//       );

//       // Act
//       final json = movement.toJson();

//       // Assert
//       expect(json['id'], 1);
//       expect(json['reference'], 'MOV-001');
//       expect(json['montant'], 50000.0);
//       expect(json['categorieId'], 1);
//       expect(json['description'], 'Achat de fournitures');
//       expect(json['utilisateurId'], 1);
//       expect(json['notes'], 'Notes additionnelles');
//     });

//     test('should format amount correctly', () {
//       // Arrange
//       final movement = FinancialMovement(
//         id: 1,
//         reference: 'MOV-001',
//         montant: 50000.0,
//         categorieId: 1,
//         description: 'Test',
//         date: DateTime.now(),
//         utilisateurId: 1,
//         dateCreation: DateTime.now(),
//         dateModification: DateTime.now(),
//       );

//       // Act & Assert
//       expect(movement.montantFormate, '50000.00 FCFA');
//     });

//     test('should detect attachments correctly', () {
//       // Arrange
//       final movementWithoutAttachments = FinancialMovement(
//         id: 1,
//         reference: 'MOV-001',
//         montant: 50000.0,
//         categorieId: 1,
//         description: 'Test',
//         date: DateTime.now(),
//         utilisateurId: 1,
//         dateCreation: DateTime.now(),
//         dateModification: DateTime.now(),
//       );

//       final movementWithAttachments = FinancialMovement(
//         id: 2,
//         reference: 'MOV-002',
//         montant: 25000.0,
//         categorieId: 1,
//         description: 'Test',
//         date: DateTime.now(),
//         utilisateurId: 1,
//         dateCreation: DateTime.now(),
//         dateModification: DateTime.now(),
//         attachments: [
//           MovementAttachment(
//             id: 1,
//             mouvementId: 2,
//             fileName: 'receipt.pdf',
//             originalName: 'receipt.pdf',
//             mimeType: 'application/pdf',
//             fileSize: 1024,
//             filePath: '/uploads/receipt.pdf',
//             uploadedAt: DateTime.now(),
//           ),
//         ],
//       );

//       // Act & Assert
//       expect(movementWithoutAttachments.hasAttachments, false);
//       expect(movementWithoutAttachments.attachmentCount, 0);
//       expect(movementWithAttachments.hasAttachments, true);
//       expect(movementWithAttachments.attachmentCount, 1);
//     });
//   });

//   group('FinancialMovementForm', () {
//     test('should validate correctly', () {
//       // Arrange
//       final validForm = FinancialMovementForm(
//         montant: 50000.0,
//         categorieId: 1,
//         description: 'Achat de fournitures',
//         date: DateTime.now(),
//       );

//       final invalidForm = FinancialMovementForm(
//         montant: -100.0,
//         categorieId: 1,
//         description: 'AB',
//         date: DateTime.now().add(const Duration(days: 2)),
//       );

//       // Act & Assert
//       expect(validForm.isValid, true);
//       expect(validForm.validate(), isEmpty);

//       expect(invalidForm.isValid, false);
//       final errors = invalidForm.validate();
//       expect(errors.length, 3);
//       expect(errors, contains('Le montant doit être supérieur à 0'));
//       expect(errors, contains('La description doit contenir au moins 3 caractères'));
//       expect(errors, contains('La date ne peut pas être dans le futur'));
//     });

//     test('should convert to JSON correctly', () {
//       // Arrange
//       final form = FinancialMovementForm(
//         montant: 50000.0,
//         categorieId: 1,
//         description: 'Achat de fournitures',
//         date: DateTime.parse('2024-01-15T10:30:00.000Z'),
//         notes: 'Notes',
//       );

//       // Act
//       final json = form.toJson();

//       // Assert
//       expect(json['montant'], 50000.0);
//       expect(json['categorieId'], 1);
//       expect(json['description'], 'Achat de fournitures');
//       expect(json['notes'], 'Notes');
//     });
//   });

//   group('MovementCategory', () {
//     test('should create from JSON correctly', () {
//       // Arrange
//       final json = {
//         'id': 1,
//         'nom': 'achats',
//         'displayName': 'Achats',
//         'color': '#EF4444',
//         'icon': 'shopping_cart',
//         'isDefault': true,
//         'isActive': true,
//         'dateCreation': '2024-01-15T10:30:00.000Z',
//         'dateModification': '2024-01-15T10:30:00.000Z',
//       };

//       // Act
//       final category = MovementCategory.fromJson(json);

//       // Assert
//       expect(category.id, 1);
//       expect(category.nom, 'achats');
//       expect(category.displayName, 'Achats');
//       expect(category.color, '#EF4444');
//       expect(category.icon, 'shopping_cart');
//       expect(category.isDefault, true);
//       expect(category.isActive, true);
//     });
//   });

//   group('MovementAttachment', () {
//     test('should format file size correctly', () {
//       // Arrange
//       final smallFile = MovementAttachment(
//         id: 1,
//         mouvementId: 1,
//         fileName: 'small.txt',
//         originalName: 'small.txt',
//         mimeType: 'text/plain',
//         fileSize: 512,
//         filePath: '/uploads/small.txt',
//         uploadedAt: DateTime.now(),
//       );

//       final mediumFile = MovementAttachment(
//         id: 2,
//         mouvementId: 1,
//         fileName: 'medium.pdf',
//         originalName: 'medium.pdf',
//         mimeType: 'application/pdf',
//         fileSize: 1536, // 1.5 KB
//         filePath: '/uploads/medium.pdf',
//         uploadedAt: DateTime.now(),
//       );

//       final largeFile = MovementAttachment(
//         id: 3,
//         mouvementId: 1,
//         fileName: 'large.jpg',
//         originalName: 'large.jpg',
//         mimeType: 'image/jpeg',
//         fileSize: 2097152, // 2 MB
//         filePath: '/uploads/large.jpg',
//         uploadedAt: DateTime.now(),
//       );

//       // Act & Assert
//       expect(smallFile.fileSizeFormatted, '512 B');
//       expect(mediumFile.fileSizeFormatted, '1.5 KB');
//       expect(largeFile.fileSizeFormatted, '2.0 MB');
//     });

//     test('should detect file types correctly', () {
//       // Arrange
//       final imageFile = MovementAttachment(
//         id: 1,
//         mouvementId: 1,
//         fileName: 'image.jpg',
//         originalName: 'image.jpg',
//         mimeType: 'image/jpeg',
//         fileSize: 1024,
//         filePath: '/uploads/image.jpg',
//         uploadedAt: DateTime.now(),
//       );

//       final pdfFile = MovementAttachment(
//         id: 2,
//         mouvementId: 1,
//         fileName: 'document.pdf',
//         originalName: 'document.pdf',
//         mimeType: 'application/pdf',
//         fileSize: 1024,
//         filePath: '/uploads/document.pdf',
//         uploadedAt: DateTime.now(),
//       );

//       // Act & Assert
//       expect(imageFile.isImage, true);
//       expect(imageFile.isPdf, false);
//       expect(imageFile.fileExtension, 'jpg');

//       expect(pdfFile.isImage, false);
//       expect(pdfFile.isPdf, true);
//       expect(pdfFile.fileExtension, 'pdf');
//     });
//   });
// }
