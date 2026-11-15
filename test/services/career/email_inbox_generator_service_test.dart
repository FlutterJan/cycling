// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/services/career/email_inbox_generator_service.dart';

void main() {
  group('EmailInboxGeneratorService Tests', () {
    late EmailInboxGeneratorService service;

    setUp(() {
      service = EmailInboxGeneratorService(seed: 42);
    });

    test('initializes empty and correctly calculates counts', () {
      expect(service.emails, isEmpty);
      expect(service.unreadCount, equals(0));
      expect(service.urgentActionCount, equals(0));
    });

    test('generates Race Invitation Email with interactive buttons and accepts invite', () {
      final email = service.generateRaceInvitationEmail(
        raceName: 'Strade Bianche',
        raceId: 'strade_bianche_2026',
        organizerName: 'RCS Sport',
        raceCategory: '1.UWT',
        raceStartDate: DateTime(2026, 3, 7),
        stageCount: 1,
      );

      service.addEmail(email);

      expect(service.emails.length, equals(1));
      expect(service.unreadCount, equals(1));
      expect(service.urgentActionCount, equals(1));
      expect(email.subject, contains('Strade Bianche'));
      expect(email.category, equals(EmailCategory.raceInvitation));
      expect(email.priority, equals(EmailPriority.high));
      expect(email.actions.length, equals(2));

      final acceptAction = email.actions.firstWhere(
        (a) => a.actionType == EmailActionType.acceptRaceInvitation,
      );
      expect(acceptAction.label, equals('Zaakceptuj zaproszenie na wyścig'));
      expect(acceptAction.isPending, isTrue);

      // Wykonanie akcji: Zaakceptuj
      final result = service.executeAction(
        emailId: email.id,
        actionId: acceptAction.actionId,
      );

      expect(result.success, isTrue);
      expect(result.message, contains('Pomyślnie zaakceptowano zaproszenie'));
      expect(result.stateChanges['addedToCalendar'], isTrue);
      expect(result.stateChanges['raceId'], equals('strade_bianche_2026'));

      // Sprawdzenie stanu po wykonaniu akcji
      final updatedEmail = service.emails.first;
      expect(updatedEmail.isRead, isTrue);
      expect(updatedEmail.requiresImmediateAction, isFalse);

      final updatedAccept = updatedEmail.actions.firstWhere(
        (a) => a.actionId == acceptAction.actionId,
      );
      expect(updatedAccept.status, equals(InboxActionStatus.completed));
      expect(updatedAccept.resultMessage, isNotNull);

      // Druga akcja (odrzucenie) powinna być dezaktywowana
      final updatedDecline = updatedEmail.actions.firstWhere(
        (a) => a.actionType == EmailActionType.declineRaceInvitation,
      );
      expect(updatedDecline.status, equals(InboxActionStatus.disabled));
      expect(service.urgentActionCount, equals(0));
    });

    test('generates Medical Crash Report Email and authorizes accelerated therapy', () {
      final email = service.generateMedicalCrashReportEmail(
        riderName: 'Jonas Vingegaard',
        riderId: 'rider_vingegaard_01',
        raceName: 'Paryż-Nicea',
        stageNumber: 4,
        injuryDescription: 'Głębokie stłuczenie biodra i obtarcia skóry',
        daysOut: 12,
        treatmentCostEur: 4500,
        reducedDaysByTreatment: 5,
      );

      service.addEmail(email);

      expect(email.category, equals(EmailCategory.medicalReport));
      expect(email.priority, equals(EmailPriority.urgent));
      expect(email.actions.length, equals(3));

      // 1. Akcja: Przejdź do raportu medycznego po kraksie
      final viewAction = email.actions.firstWhere(
        (a) => a.actionType == EmailActionType.viewMedicalReport,
      );
      expect(viewAction.label, equals('Przejdź do raportu medycznego po kraksie'));

      // 2. Akcja: Zatwierdź przyspieszoną terapię
      final treatAction = email.actions.firstWhere(
        (a) => a.actionType == EmailActionType.authorizeMedicalTreatment,
      );
      expect(treatAction.label, contains('Zatwierdź przyspieszoną terapię'));

      final result = service.executeAction(
        emailId: email.id,
        actionId: treatAction.actionId,
      );

      expect(result.success, isTrue);
      expect(result.message, contains('Zatwierdzono terapię w komorze hiperbarycznej'));
      expect(result.stateChanges['budgetDeltaEur'], equals(-4500));
      expect(result.stateChanges['daysReduced'], equals(5));
      expect(result.stateChanges['riderId'], equals('rider_vingegaard_01'));
    });

    test('generates Transfer Buyout Offer Email and sends counter-offer (+25%)', () {
      final email = service.generateTransferBuyoutOfferEmail(
        riderName: 'Juan Ayuso',
        riderId: 'rider_ayuso_01',
        buyingTeamName: 'INEOS Grenadiers',
        buyingTeamDsName: 'Dave Brailsford',
        buyoutFeeEur: 1200000,
        proposedRiderSalaryEur: 150000,
      );

      service.addEmail(email);

      expect(email.category, equals(EmailCategory.transferOffer));
      expect(email.actions.length, equals(3));

      final counterAction = email.actions.firstWhere(
        (a) => a.actionType == EmailActionType.counterTransferOffer,
      );
      expect(counterAction.label, contains('Odpowiedz na ofertę wykupu kolarza'));

      final result = service.executeAction(
        emailId: email.id,
        actionId: counterAction.actionId,
      );

      expect(result.success, isTrue);
      expect(result.message, contains('+25%'));
      expect(result.stateChanges['requestedFeeEur'], equals(1500000));
    });

    test('generates Altitude Camp Budget Email and approves Sierra Nevada camp', () {
      final email = service.generateAltitudeCampBudgetEmail(
        location: 'Sierra Nevada (Hiszpania, 2 320 m n.p.m.)',
        durationWeeks: 3,
        riderCount: 7,
        totalBudgetEur: 42000,
        economyBudgetEur: 28000,
        expectedFtpGainPct: 3.8,
        expectedVamGainPct: 5.2,
      );

      service.addEmail(email);

      expect(email.category, equals(EmailCategory.trainingAndCamp));
      expect(email.actions.length, equals(3));

      final approveAction = email.actions.firstWhere(
        (a) => a.actionType == EmailActionType.approveCampBudget,
      );
      expect(approveAction.label, contains('Zatwierdź budżet na obóz w Sierra Nevada'));

      final result = service.executeAction(
        emailId: email.id,
        actionId: approveAction.actionId,
      );

      expect(result.success, isTrue);
      expect(result.stateChanges['budgetDeltaEur'], equals(-42000));
      expect(result.stateChanges['ftpBonusPct'], equals(3.8));
      expect(result.stateChanges['vamBonusPct'], equals(5.2));
    });

    test('handles Rider Ego Conflict Email with schedule meeting', () {
      final email = service.generateRiderConflictEmail(
        riderName: 'Enric Mas',
        riderId: 'rider_mas_01',
        complaintReason: 'Odmowa roli pomocnika dla młodego kolarza na Vuelta a España',
      );

      service.addEmail(email);

      expect(email.category, equals(EmailCategory.riderRelations));
      final meetAction = email.actions.firstWhere(
        (a) => a.actionType == EmailActionType.scheduleRiderMeeting,
      );

      final result = service.executeAction(
        emailId: email.id,
        actionId: meetAction.actionId,
      );

      expect(result.success, isTrue);
      expect(result.stateChanges['moraleDelta'], equals(10.0));
    });

    test('handles Youth Scouting Discovery Email with Devo contract signing', () {
      final email = service.generateYouthDiscoveryEmail(
        talentName: 'Lukas Van Aert',
        age: 18,
        nationality: 'Belgia',
        riderType: 'Góral / Puncheur',
        vo2max: 84,
        annualSalaryEur: 24000,
      );

      service.addEmail(email);

      expect(email.category, equals(EmailCategory.youthDevelopment));
      final signAction = email.actions.firstWhere(
        (a) => a.actionType == EmailActionType.signDevoRider,
      );

      final result = service.executeAction(
        emailId: email.id,
        actionId: signAction.actionId,
      );

      expect(result.success, isTrue);
      expect(result.stateChanges['action'], equals('devo_contract_signed'));
      expect(result.stateChanges['salaryEur'], equals(24000));
    });

    test('handles Equipment Aero Upgrade Email with watt savings', () {
      final email = service.generateEquipmentUpgradeEmail(
        supplierName: 'Specialized S-Works R&D',
        upgradeName: 'Koła TT Roval Rapide CLX II 60mm',
        costEur: 18000,
        wattSavings: 11,
      );

      service.addEmail(email);

      expect(email.category, equals(EmailCategory.equipmentAndTech));
      final orderAction = email.actions.firstWhere(
        (a) => a.actionType == EmailActionType.orderEquipmentUpgrade,
      );

      final result = service.executeAction(
        emailId: email.id,
        actionId: orderAction.actionId,
      );

      expect(result.success, isTrue);
      expect(result.stateChanges['wattSavings'], equals(11));
      expect(result.stateChanges['budgetDeltaEur'], equals(-18000));
    });

    test('handles Anti-Doping ADAMS notice and Press Conference request', () {
      final adamsEmail = service.generateAntiDopingNoticeEmail(
        riderName: 'Tadej Pogacar',
        testLocation: 'Hotel w Nicei (Poza zawodami)',
        isRandomOutCompetiton: true,
      );
      service.addEmail(adamsEmail);

      final pressEmail = service.generatePressInterviewRequestEmail(
        mediaOutlet: "L'Équipe",
        journalistName: 'Gilles Le Roc',
        topic: 'Taktyka zespołu na Alpe d’Huez',
      );
      service.addEmail(pressEmail);

      expect(service.emails.length, equals(2));

      // Acknowledge ADAMS
      final adamsAction = adamsEmail.actions.first;
      final adamsResult = service.executeAction(
        emailId: adamsEmail.id,
        actionId: adamsAction.actionId,
      );
      expect(adamsResult.success, isTrue);

      // Respond to press
      final pressAction = pressEmail.actions.firstWhere(
        (a) => a.actionType == EmailActionType.respondToPress,
      );
      final pressResult = service.executeAction(
        emailId: pressEmail.id,
        actionId: pressAction.actionId,
      );
      expect(pressResult.success, isTrue);
    });

    test('rejects execution on expired emails', () {
      final expiredEmail = InboxEmailMessage(
        id: 'expired_01',
        senderName: 'ASO Organizers',
        senderRole: 'Organizer',
        subject: 'Wygasłe zaproszenie',
        bodyText: 'Termin minął',
        category: EmailCategory.raceInvitation,
        sentDate: DateTime.now().subtract(const Duration(days: 10)),
        expiryDate: DateTime.now().subtract(const Duration(days: 2)),
        actions: const [
          InboxEmailAction(
            actionId: 'act_exp_01',
            label: 'Zaakceptuj',
            actionType: EmailActionType.acceptRaceInvitation,
          ),
        ],
      );

      service.addEmail(expiredEmail);

      final result = service.executeAction(
        emailId: 'expired_01',
        actionId: 'act_exp_01',
      );

      expect(result.success, isFalse);
      expect(result.message, contains('wyga'));
      expect(service.emails.first.actions.first.status, equals(InboxActionStatus.expired));
    });

    test('manages email lifecycle: read, star, archive, filter, and delete', () {
      final email1 = service.generateRaceInvitationEmail(
        raceName: 'Tour de Pologne',
        raceId: 'tdp_2026',
        organizerName: 'Lang Team',
        raceCategory: '2.UWT',
        raceStartDate: DateTime(2026, 8, 1),
        stageCount: 7,
      );

      final email2 = service.generateMedicalCrashReportEmail(
        riderName: 'Michał Kwiatkowski',
        riderId: 'rider_kwiato_01',
        raceName: 'Amstel Gold Race',
        stageNumber: 1,
        injuryDescription: 'Stłuczenie kolana',
        daysOut: 5,
      );

      service.addEmail(email1);
      service.addEmail(email2);

      expect(service.unreadCount, equals(2));

      // Mark single read
      service.markAsRead(email1.id, true);
      expect(service.unreadCount, equals(1));

      // Mark all read
      service.markAllAsRead();
      expect(service.unreadCount, equals(0));

      // Star email
      service.toggleStarred(email1.id);
      expect(service.emails.firstWhere((e) => e.id == email1.id).isStarred, isTrue);

      // Filter by category
      final raceMails = service.getFilteredEmails(category: EmailCategory.raceInvitation);
      expect(raceMails.length, equals(1));
      expect(raceMails.first.id, equals(email1.id));

      // Filter by search query
      final searchResults = service.getFilteredEmails(searchQuery: 'Kwiatkowski');
      expect(searchResults.length, equals(1));
      expect(searchResults.first.id, equals(email2.id));

      // Archive email
      service.toggleArchived(email2.id);
      final activeEmails = service.getFilteredEmails();
      expect(activeEmails.length, equals(1));
      expect(activeEmails.first.id, equals(email1.id));

      final archivedEmails = service.getFilteredEmails(archivedOnly: true);
      expect(archivedEmails.length, equals(1));
      expect(archivedEmails.first.id, equals(email2.id));

      // Delete email
      final deleted = service.deleteEmail(email1.id);
      expect(deleted, isTrue);
      expect(service.emails.length, equals(1));
    });

    test('supports full toJson and fromJson serialization', () {
      final email = service.generateAltitudeCampBudgetEmail(
        location: 'Sierra Nevada',
        totalBudgetEur: 42000,
      );
      service.addEmail(email);

      service.executeAction(
        emailId: email.id,
        actionId: email.actions.first.actionId,
      );

      final json = service.toJson();
      final restoredService = EmailInboxGeneratorService.fromJson(json);

      expect(restoredService.emails.length, equals(1));
      final restoredEmail = restoredService.emails.first;
      expect(restoredEmail.id, equals(email.id));
      expect(restoredEmail.subject, equals(email.subject));
      expect(restoredEmail.category, equals(EmailCategory.trainingAndCamp));
      expect(restoredEmail.actions.length, equals(3));
      expect(restoredEmail.actions.first.status, equals(InboxActionStatus.completed));
      expect(restoredEmail.actions[1].status, equals(InboxActionStatus.disabled));
    });

    test('generateDailyMorningBriefing creates realistic batch of daily emails', () {
      final date = DateTime(2026, 7, 10);
      final briefingEmails = service.generateDailyMorningBriefing(
        currentDate: date,
        teamName: 'Orzeł Warszawa Cycling Team',
        teamId: 'team_orzel',
        injuredRiderNames: ['Piotr Havik'],
      );

      expect(briefingEmails, isNotEmpty);
      expect(
        briefingEmails.any((e) => e.category == EmailCategory.medicalReport),
        isTrue,
      );
      expect(service.emails.length, equals(briefingEmails.length));
    });
  });
}

