import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/rider/rider.dart';
import 'package:pro_peloton_manager/models/team/cycling_team.dart';
import 'package:pro_peloton_manager/services/generators/world_teams_generator.dart';
import 'package:pro_peloton_manager/ui/screens/in_game_database_roster_editor_screen.dart';

void main() {
  late List<CyclingTeam> sampleTeams;
  late List<Rider> sampleRiders;

  setUp(() {
    final generated = WorldTeamsGenerator.generateWorldTourSystem(seed: 101);
    sampleTeams = generated.teams.take(3).toList();
    final teamIds = sampleTeams.map((t) => t.id).toSet();
    sampleRiders = generated.allRiders
        .where((r) => teamIds.contains(r.contract.teamId))
        .take(12)
        .toList();
  });

  group('DatabaseEditorCodec', () {
    test('validates clean database without errors', () {
      final issues = DatabaseEditorCodec.validateDatabase(
        teams: sampleTeams,
        riders: sampleRiders,
      );
      expect(issues.where((i) => i.isError), isEmpty);
    });

    test('detects invalid HEX color and empty team name', () {
      final brokenTeam = sampleTeams.first.copyWith(
        name: '',
        primaryJerseyColorHex: 'INVALID',
      );
      final issues = DatabaseEditorCodec.validateDatabase(
        teams: [brokenTeam],
        riders: sampleRiders,
      );
      expect(issues.where((i) => i.isError).length, 2);
    });

    test('exports and imports teams and riders JSON roundtrip', () {
      final jsonText = DatabaseEditorCodec.exportToJson(
        teams: sampleTeams,
        riders: sampleRiders,
      );
      final imported = DatabaseEditorCodec.importFromJson(jsonText);
      expect(imported.teams.length, sampleTeams.length);
      expect(imported.riders.length, sampleRiders.length);
      expect(imported.teams.first.id, sampleTeams.first.id);
      expect(imported.riders.first.id, sampleRiders.first.id);
    });
  });

  group('InGameDatabaseRosterEditorScreen responsive layouts', () {
    Future<void> pumpAtSize(
      WidgetTester tester,
      Size size, {
      void Function(List<CyclingTeam>, List<Rider>)? onApply,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: InGameDatabaseRosterEditorScreen(
            initialTeams: sampleTeams,
            initialRiders: sampleRiders,
            onApplyDatabase: onApply,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('renders cleanly at 1600x900 desktop and supports add + undo + apply', (tester) async {
      List<CyclingTeam>? appliedTeams;
      List<Rider>? appliedRiders;

      await pumpAtSize(
        tester,
        const Size(1600, 900),
        onApply: (teams, riders) {
          appliedTeams = teams;
          appliedRiders = riders;
        },
      );

      expect(find.text('Edytor Bazy Danych i Składów'), findsOneWidget);
      expect(find.text('Drużyny w Bazie'), findsOneWidget);
      expect(find.text('+ Kolarz'), findsOneWidget);

      await tester.tap(find.text('+ Kolarz'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('Jan Nowak'), findsWidgets);

      await tester.tap(find.byTooltip('Cofnij (1)'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('Cofnięto ostatnią zmianę.'), findsOneWidget);

      await tester.tap(find.text('Zastosuj Zmiany'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(appliedTeams, isNotNull);
      expect(appliedRiders, isNotNull);
      expect(appliedTeams!.length, sampleTeams.length);
    });

    testWidgets('renders cleanly at 1024x768 tablet without overflow', (tester) async {
      await pumpAtSize(tester, const Size(1024, 768));
      expect(find.text('Edytor Bazy Danych i Składów'), findsOneWidget);
      expect(find.text('Edytor Kolarza'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly at 390x844 mobile and switches tabs', (tester) async {
      await pumpAtSize(tester, const Size(390, 844));
      expect(find.text('Edytor Bazy Danych i Składów'), findsOneWidget);
      expect(find.text('Drużyny'), findsOneWidget);
      expect(find.text('Skład'), findsOneWidget);
      expect(find.text('Edytor'), findsOneWidget);

      await tester.tap(find.text('Skład'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('+ Kolarz'), findsOneWidget);

      await tester.tap(find.text('Edytor'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('Edytor Kolarza'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
