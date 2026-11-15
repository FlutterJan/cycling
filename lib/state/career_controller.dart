import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../engine/simulation/post_stage_recovery_processor.dart';
import '../engine/simulation/stage_results_calculator.dart';
import '../engine/simulation/stage_simulation_loop.dart';
import '../models/career/career_save.dart';
import '../models/career/season_calendar.dart';
import '../models/race/tour_race.dart';
import '../models/rider/rider.dart';
import '../models/rider/rider_contract.dart';
import '../models/team/bike_manufacturer_deal.dart';
import '../models/team/cycling_team.dart';
import '../models/team/sponsor_contract.dart';
import '../services/career/bike_manufacturer_negotiation_service.dart';
import '../services/career/finance_and_budget_service.dart';
import '../services/career/race_calendar_selection_service.dart';
import '../services/career/scouting_and_youth_academy_service.dart';
import '../services/career/sponsor_negotiation_service.dart';
import '../services/career/team_chemistry_and_builder_service.dart';
import '../services/career/training_and_camps_service.dart';
import '../services/career/transfer_market_service.dart';
import '../services/database/custom_mod_importer_service.dart';
import '../services/database/save_game_manager.dart';
import '../services/database/save_service.dart';

/// Stan menedżera kariery dla warstwy prezentacji (UI).
class CareerUiState {
  final CareerSave? save;
  final bool isLoading;
  final String? errorMessage;
  final List<CareerSaveMetadata> availableSaves;
  final int? activeSlotNumber; // 1-5 (lub 0 dla auto-save)
  final List<SaveSlotInfo> slots; // 5 slotów użytkownika
  final SaveSlotInfo? autoSaveSlot; // Dedykowany slot Auto-Save

  const CareerUiState({
    this.save,
    this.isLoading = false,
    this.errorMessage,
    this.availableSaves = const [],
    this.activeSlotNumber,
    this.slots = const [],
    this.autoSaveSlot,
  });

  bool get hasActiveSave => save != null;

  CareerUiState copyWith({
    CareerSave? save,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    List<CareerSaveMetadata>? availableSaves,
    int? activeSlotNumber,
    bool clearActiveSlot = false,
    List<SaveSlotInfo>? slots,
    SaveSlotInfo? autoSaveSlot,
  }) {
    return CareerUiState(
      save: save ?? this.save,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      availableSaves: availableSaves ?? this.availableSaves,
      activeSlotNumber: clearActiveSlot ? null : (activeSlotNumber ?? this.activeSlotNumber),
      slots: slots ?? this.slots,
      autoSaveSlot: autoSaveSlot ?? this.autoSaveSlot,
    );
  }
}

/// Kontroler stanu kariery zarządzający życiem drużyny kolarskiej, finansami i kalendarzem sezonu.
class CareerController extends StateNotifier<CareerUiState> {
  CareerController() : super(const CareerUiState()) {
    refreshSavedGamesList();
    refreshSlotsList();
  }

  /// Odświeża listę 5 slotów zapisu oraz slotu Auto-Save
  Future<void> refreshSlotsList() async {
    try {
      final allSlots = await SaveGameManager.getAllSlots(includeAutoSave: true);
      final userSlots = allSlots.where((s) => !s.isAutoSave).toList();
      final autoSlot = allSlots.firstWhere((s) => s.isAutoSave, orElse: () => SaveSlotInfo.empty(0));

      state = state.copyWith(
        slots: userSlots,
        autoSaveSlot: autoSlot.isOccupied ? autoSlot : null,
      );
    } catch (e) {
      // Błąd odczytu slotów nie blokuje działania aplikacji
    }
  }

  /// Odświeża listę dostępnych slotów zapisu na dysku
  Future<void> refreshSavedGamesList() async {
    try {
      final list = await SaveService.listSavedGames();
      state = state.copyWith(availableSaves: list);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Błąd odczytu listy zapisów: $e');
    }
  }

  /// Ładuje istniejącą grę z pliku o podanym ID
  Future<bool> loadSave(String saveId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final loadedSave = await SaveService.loadCareerSave(saveId);
      if (loadedSave != null) {
        state = state.copyWith(save: loadedSave, isLoading: false);
        await refreshSlotsList();
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Nie znaleziono pliku zapisu o ID: $saveId',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Błąd podczas wczytywania gry: $e',
      );
      return false;
    }
  }

  /// Ładuje stan kariery z wybranego slotu (1-5)
  Future<bool> loadFromSlot(int slotNumber) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final loadedSave = await SaveGameManager.loadFromSlot(slotNumber);
      if (loadedSave != null) {
        state = state.copyWith(
          save: loadedSave,
          activeSlotNumber: slotNumber,
          isLoading: false,
        );
        await refreshSlotsList();
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Slot #$slotNumber jest pusty lub uszkodzony.',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Błąd odczytu slotu #$slotNumber: $e',
      );
      return false;
    }
  }

  /// Ładuje stan kariery ze slotu Auto-Save
  Future<bool> loadAutoSave() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final loadedSave = await SaveGameManager.loadAutoSave();
      if (loadedSave != null) {
        state = state.copyWith(
          save: loadedSave,
          activeSlotNumber: 0,
          isLoading: false,
        );
        await refreshSlotsList();
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Brak pliku Auto-Save na dysku.',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Błąd wczytywania Auto-Save: $e',
      );
      return false;
    }
  }

  /// Tworzy nową karierę z kompletnym światem wyścigowym w wybranym slocie (domyślnie Slot 1).
  /// Obsługuje zespoły istniejące oraz własny zespół gracza (Custom Team).
  Future<bool> startNewCareer({
    required String saveName,
    required String playerManagerName,
    required String playerTeamId,
    CareerDifficulty difficulty = CareerDifficulty.normal,
    int seasonYear = 2026,
    int targetSlotNumber = 1,
    CyclingTeam? customTeam,
    List<Rider>? customRoster,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final newSave = await SaveService.createNewCareer(
        saveName: saveName,
        playerManagerName: playerManagerName,
        playerTeamId: playerTeamId,
        difficulty: difficulty,
        seasonYear: seasonYear,
        customTeam: customTeam,
        customRoster: customRoster,
      );

      // Zapisujemy od razu do slotu 1 (lub wybranego przez gracza)
      await SaveGameManager.saveToSlot(
        slotNumber: targetSlotNumber,
        save: newSave,
      );

      state = state.copyWith(
        save: newSave,
        activeSlotNumber: targetSlotNumber,
        isLoading: false,
      );
      await refreshSavedGamesList();
      await refreshSlotsList();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Błąd podczas tworzenia nowej kariery: $e',
      );
      return false;
    }
  }

  /// Zapisuje bieżący stan gry do wskazanego slotu (1-5)
  Future<SaveSlotInfo?> saveToSlot(int slotNumber, {String? customSaveName}) async {
    final curSave = state.save;
    if (curSave == null) return null;

    try {
      final slotInfo = await SaveGameManager.saveToSlot(
        slotNumber: slotNumber,
        save: curSave,
        customSaveName: customSaveName,
      );

      state = state.copyWith(activeSlotNumber: slotNumber);
      await SaveService.saveCareer(curSave);
      await refreshSavedGamesList();
      await refreshSlotsList();
      return slotInfo;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Nie udało się zapisać do slotu #$slotNumber: $e');
      return null;
    }
  }

  /// Wykonuje automatyczny zapis kariery (Auto-Save)
  Future<SaveSlotInfo?> performAutoSave() async {
    final curSave = state.save;
    if (curSave == null) return null;

    try {
      final slotInfo = await SaveGameManager.performAutoSave(
        save: curSave,
        originatingSlotNumber: state.activeSlotNumber,
      );
      await refreshSlotsList();
      return slotInfo;
    } catch (e) {
      return null;
    }
  }

  /// Zapisuje bieżący stan gry na dysku (do aktywnego slotu lub Auto-Save)
  Future<void> saveCurrentGame({bool isAutoSave = false}) async {
    final curSave = state.save;
    if (curSave == null) return;

    try {
      if (isAutoSave) {
        await SaveGameManager.performAutoSave(
          save: curSave,
          originatingSlotNumber: state.activeSlotNumber,
        );
      } else {
        final slot = state.activeSlotNumber ?? 1;
        await SaveGameManager.saveToSlot(
          slotNumber: slot,
          save: curSave,
        );
        state = state.copyWith(activeSlotNumber: slot);
      }
      await SaveService.saveCareer(curSave, isAutoSave: isAutoSave);
      await refreshSavedGamesList();
      await refreshSlotsList();
    } catch (e) {
      state = state.copyWith(errorMessage: 'Nie udało się zapisać stanu gry: $e');
    }
  }

  /// Usuwa dany slot zapisu (1-5)
  Future<bool> deleteSlot(int slotNumber) async {
    try {
      final ok = await SaveGameManager.deleteSlot(slotNumber);
      if (state.activeSlotNumber == slotNumber) {
        state = state.copyWith(clearActiveSlot: true);
      }
      await refreshSlotsList();
      return ok;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Błąd usuwania slotu #$slotNumber: $e');
      return false;
    }
  }

  /// Kopiuje stan zapisu ze slotu do innego slotu
  Future<SaveSlotInfo?> copySlot({required int sourceSlot, required int targetSlot}) async {
    try {
      final info = await SaveGameManager.copySlot(
        sourceSlot: sourceSlot,
        targetSlot: targetSlot,
      );
      await refreshSlotsList();
      return info;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Błąd kopiowania slotu: $e');
      return null;
    }
  }

  /// Eksportuje wybrany slot do przenośnego formatu JSON (do przeniesienia na Mac/PC/telefon)
  Future<String> exportSlotAsPortableJson(int slotNumber) async {
    return SaveGameManager.exportSaveAsPortableJson(
      slotNumber: slotNumber,
      inMemorySave: state.activeSlotNumber == slotNumber ? state.save : null,
    );
  }

  /// Eksportuje aktualny stan aktywnej kariery do przenośnego formatu JSON
  Future<String> exportActiveSaveAsPortableJson() async {
    final curSave = state.save;
    if (curSave == null) {
      throw StateError('Brak aktywnego stanu gry.');
    }
    return SaveGameManager.exportSaveAsPortableJson(
      slotNumber: state.activeSlotNumber ?? 1,
      inMemorySave: curSave,
    );
  }

  /// Waliduje przenośny plik zapisu przed zaimportowaniem
  SaveValidationResult validatePortableSave(String dataString) {
    return SaveGameManager.validatePortableSave(dataString);
  }

  /// Importuje przenośny plik zapisu do wybranego slotu (1-5)
  Future<SaveSlotInfo> importPortableSave({
    required String dataString,
    required int targetSlotNumber,
  }) async {
    final slotInfo = await SaveGameManager.importPortableSave(
      dataString: dataString,
      targetSlotNumber: targetSlotNumber,
    );
    await refreshSlotsList();
    return slotInfo;
  }

  /// Usuwa dany plik zapisu (legacy SaveService)
  Future<void> deleteSave(String saveId) async {
    try {
      await SaveService.deleteCareerSave(saveId);
      if (state.save?.id == saveId) {
        state = state.copyWith(save: null);
      }
      await refreshSavedGamesList();
    } catch (e) {
      state = state.copyWith(errorMessage: 'Błąd usuwania zapisu: $e');
    }
  }

  /// Przechodzi do kolejnego dnia w kalendarzu (Daily Progression)
  void advanceCalendarDay() {
    final curSave = state.save;
    if (curSave == null) return;

    final nextDate = curSave.currentDate.add(const Duration(days: 1));
    final calendar = curSave.calendar;

    // Sprawdzamy, czy w danym dniu rozpoczyna się nowy wyścig
    String? newActiveRaceId = calendar.activeRaceId;
    if (newActiveRaceId == null) {
      for (final race in calendar.races) {
        if (!calendar.completedRaceIds.contains(race.id) &&
            race.startMonth == nextDate.month &&
            race.startDay == nextDate.day) {
          newActiveRaceId = race.id;
          break;
        }
      }
    }

    final updatedCalendar = (newActiveRaceId != null && newActiveRaceId != calendar.activeRaceId)
        ? calendar.startRace(newActiveRaceId)
        : calendar;

    // Symulacja autonomicznych ruchów transferowych AI w każdy poniedziałek podczas okna transferowego
    CareerSave advancedSave = curSave.copyWith(
      currentDate: nextDate,
      calendar: updatedCalendar,
    );

    if (nextDate.weekday == DateTime.monday &&
        TransferMarketService.isTransferWindowOpen(nextDate)) {
      advancedSave = TransferMarketService.simulateAiTransferMarket(
        currentSave: advancedSave,
        maxAiTransfersPerWeek: 3,
      );
    }

    // Comiesięczne rozliczenie finansowe klubu i rozwój adeptów w akademii (1. dzień nowego miesiąca)
    if (curSave.currentDate.month != nextDate.month) {
      advancedSave = FinanceAndBudgetService.processMonthlySettlement(save: advancedSave);
      advancedSave = ScoutingAndYouthAcademyService.processMonthlyAcademyDevelopment(save: advancedSave);
    }

    state = state.copyWith(save: advancedSave);

    saveCurrentGame(isAutoSave: true);
  }

  /// Przesuwa czas w grze o 1 dzień (synonim advanceCalendarDay)
  void advanceDay() => advanceCalendarDay();

  /// Składa oficjalną ofertę kontraktową kolarzowi i przeprowadza negocjacje z jego agentem
  AgentNegotiationResult submitTransferOffer({
    required String riderId,
    required int annualSalaryEur,
    required int contractDurationYears,
    required RiderRole proposedRole,
    int winBonusEur = 15000,
  }) {
    final curSave = state.save;
    if (curSave == null) {
      throw StateError('Brak aktywnego zapisu gry.');
    }

    final result = TransferMarketService.submitContractOffer(
      currentSave: curSave,
      riderId: riderId,
      offeringTeamId: curSave.playerTeamId,
      annualSalaryEur: annualSalaryEur,
      contractDurationYears: contractDurationYears,
      proposedRole: proposedRole,
      winBonusEur: winBonusEur,
    );

    state = state.copyWith(save: result.updatedSave);
    saveCurrentGame();
    return result.negotiationResult;
  }

  /// Pobiera listę kolarzy z wygasającymi kontraktami w bieżącym roku
  List<Rider> getExpiringContractRiders() {
    final curSave = state.save;
    if (curSave == null) return const [];
    return TransferMarketService.getExpiringContractRiders(
      allRiders: curSave.riders,
      currentSeasonYear: curSave.currentSeasonYear,
    );
  }

  /// Zmienia przypisaną rolę kolarza w drużynie gracza (np. z Domestique na Lidera)
  void updateRiderRole({
    required String riderId,
    required RiderRole newRole,
  }) {
    final curSave = state.save;
    if (curSave == null) return;

    final updatedRiders = curSave.riders.map((r) {
      if (r.id == riderId) {
        return r.copyWith(
          contract: r.contract.copyWith(role: newRole),
        );
      }
      return r;
    }).toList();

    state = state.copyWith(
      save: curSave.copyWith(riders: updatedRiders),
    );
    saveCurrentGame(isAutoSave: false);
  }

  /// Aktualizuje stan zapisu gry i zapisuje zmiany na dysku
  void updateSave(CareerSave updatedSave) {
    state = state.copyWith(save: updatedSave);
    saveCurrentGame(isAutoSave: false);
  }

  /// Aktualizuje dane pojedynczego kolarza w bazie aktywnego zapisu gry
  void updateRider(Rider updatedRider) {
    final curSave = state.save;
    if (curSave == null) return;

    final updatedRiders = curSave.riders.map((r) {
      if (r.id == updatedRider.id) {
        return updatedRider;
      }
      return r;
    }).toList();

    state = state.copyWith(
      save: curSave.copyWith(riders: updatedRiders),
    );
    saveCurrentGame(isAutoSave: false);
  }

  /// Aktualizuje dane pojedynczej drużyny w bazie aktywnego zapisu gry
  void updateTeam(CyclingTeam updatedTeam) {
    final curSave = state.save;
    if (curSave == null) return;

    final updatedTeams = curSave.teams.map((t) {
      if (t.id == updatedTeam.id) {
        return updatedTeam;
      }
      return t;
    }).toList();

    state = state.copyWith(
      save: curSave.copyWith(teams: updatedTeams),
    );
    saveCurrentGame(isAutoSave: false);
  }

  /// Aktualizuje stan po zakończeniu etapu wyścigu:
  /// - przetwarza regenerację kolarzy ([PostStageRecoveryProcessor]),
  /// - przyznaje nagrody finansowe,
  /// - aktualizuje klasyfikacje generalną, punktową i górską,
  /// - przesuwa etap lub kończy wyścig.
  Future<void> completeStageAndApplyRecovery({
    required StageSummaryReport stageSummary,
    required StageSimulationState simulationState,
  }) async {
    final curSave = state.save;
    if (curSave == null) return;

    final playerTeam = curSave.playerTeam;
    final teamRiders = curSave.playerRoster;

    // 1. Wyliczamy regenerację fizjologiczną i zyski finansowe zespołu gracza
    final recoveryResult = PostStageRecoveryProcessor.processStageRecovery(
      teamRiders: teamRiders,
      team: playerTeam,
      stageNumber: stageSummary.stageNumber,
      officialResults: stageSummary.results,
      simulationState: simulationState,
      teamFacilities: TeamRecoveryFacilities(
        hasCompressionBoots: curSave.medicalCenterLevel >= 2,
        hasCryoCabin: curSave.medicalCenterLevel >= 4,
        nutritionProtocol: curSave.medicalCenterLevel >= 3
            ? RecoveryNutritionProtocol.worldTourElite
            : RecoveryNutritionProtocol.advanced,
        hasSleepOptimizationKit: curSave.serviceCourseLevel >= 3,
        massageQualityLevel: (curSave.medicalCenterLevel * 20).clamp(20, 100),
      ),
      incidents: simulationState.incidentHistory,
    );

    // 2. Aktualizujemy listę kolarzy
    final Map<String, Rider> updatedRidersMap = {
      for (final r in curSave.riders) r.id: r,
    };
    for (final updatedRider in recoveryResult.updatedRiders) {
      updatedRidersMap[updatedRider.id] = updatedRider;
    }

    // 3. Obsługa nagród finansowych z podziałem (Prize Money Split: 70% kolarze, 30% klub)
    final prizeMoneyEur = recoveryResult.teamTotalPrizeMoneyEur;
    CareerSave saveWithPrize = curSave.copyWith(
      riders: updatedRidersMap.values.toList(),
    );

    if (prizeMoneyEur > 0) {
      saveWithPrize = FinanceAndBudgetService.processRacePrizeMoney(
        save: saveWithPrize,
        raceName: '${stageSummary.stageNumber}. etap: ${stageSummary.stageName}',
        totalPrizeWonEur: prizeMoneyEur,
      );
    }

    // 4. Aktualizacja kalendarza wyścigowego
    SeasonCalendar updatedCalendar = curSave.calendar;
    final activeRace = updatedCalendar.activeRace;

    if (activeRace != null) {
      final isLastStage = updatedCalendar.activeStageIndex >= activeRace.stages.length - 1;

      if (isLastStage) {
        // Wyścig zakończony – wpis do historii
        final winnerResult = stageSummary.results.isNotEmpty ? stageSummary.results.first : null;
        final historyEntry = RaceHistoryEntry(
          raceId: activeRace.id,
          raceName: activeRace.name,
          seasonYear: curSave.currentSeasonYear,
          winnerRiderId: winnerResult?.riderId ?? '',
          winnerRiderName: winnerResult?.riderName ?? 'Zwycięzca',
          winnerTeamId: winnerResult?.teamId ?? '',
          winnerTeamName: winnerResult?.teamId ?? '',
          winnerTotalTimeSeconds: winnerResult?.officialFinishTimeSeconds.toInt() ?? 0,
          completedDate: curSave.currentDate,
        );
        updatedCalendar = updatedCalendar.completeActiveRace(historyEntry);
      } else {
        // Przechodzimy do kolejnego etapu
        updatedCalendar = updatedCalendar.advanceToNextStage();
      }
    }

    // 5. Aktualizacja zgrania składów po wspólnym etapie
    final updatedSquads = TeamChemistryAndBuilderService.updateSquadsAfterStage(
      squads: curSave.dedicatedSquads,
      stageFinisherRiderIds: stageSummary.results.map((r) => r.riderId).toList(),
    );

    final updatedSave = saveWithPrize.copyWith(
      calendar: updatedCalendar,
      dedicatedSquads: updatedSquads,
      currentDate: curSave.currentDate.add(const Duration(days: 1)),
      lastSavedAt: DateTime.now(),
    );

    state = state.copyWith(save: updatedSave);
    await saveCurrentGame(isAutoSave: true);
  }

  /// Ulepsza infrastrukturę zespołu
  void upgradeFacility(String facilityType) {
    final curSave = state.save;
    if (curSave == null) return;

    int costEur = 0;
    int currentLevel = 1;

    switch (facilityType) {
      case 'serviceCourse':
        currentLevel = curSave.serviceCourseLevel;
        costEur = (currentLevel + 1) * 250000;
        break;
      case 'windTunnel':
        currentLevel = curSave.windTunnelLevel;
        costEur = (currentLevel + 1) * 350000;
        break;
      case 'medicalCenter':
        currentLevel = curSave.medicalCenterLevel;
        costEur = (currentLevel + 1) * 300000;
        break;
    }

    if (curSave.playerCashBalanceEur < costEur || currentLevel >= 5) {
      state = state.copyWith(errorMessage: 'Niewystarczające środki w budżecie lub maksymalny poziom.');
      return;
    }

    final updatedTeams = curSave.teams.map((t) {
      if (t.id == curSave.playerTeamId) {
        return t.copyWith(cashBalanceEur: t.cashBalanceEur - costEur);
      }
      return t;
    }).toList();

    final newLedgerEntry = CareerFinanceLedgerEntry(
      id: 'upg_${DateTime.now().millisecondsSinceEpoch}',
      date: curSave.currentDate,
      category: FinanceCategory.facilityUpgrade,
      amountEur: -costEur,
      description: 'Rozbudowa bazy ($facilityType) na poziom ${currentLevel + 1}',
    );

    CareerSave newSave = curSave.copyWith(
      teams: updatedTeams,
      financeLedger: [newLedgerEntry, ...curSave.financeLedger],
    );

    if (facilityType == 'serviceCourse') {
      newSave = newSave.copyWith(serviceCourseLevel: currentLevel + 1);
    } else if (facilityType == 'windTunnel') {
      newSave = newSave.copyWith(windTunnelLevel: currentLevel + 1);
    } else if (facilityType == 'medicalCenter') {
      newSave = newSave.copyWith(medicalCenterLevel: currentLevel + 1);
    }

    state = state.copyWith(save: newSave);
    saveCurrentGame();
  }

  /// Wyznacza 1-3 Głównych Liderów drużyny gracza (Franchise Riders)
  void assignFranchiseLeaders(
    List<({String riderId, FranchiseRoleFocus focus, int priorityRank})> assignments,
  ) {
    final curSave = state.save;
    if (curSave == null) return;

    final result = TeamChemistryAndBuilderService.setFranchiseLeaders(
      currentSave: curSave,
      leaderAssignments: assignments,
    );

    final updatedSave = result.updatedSave.copyWith(
      franchiseLeaders: result.assignedLeaders,
    );

    state = state.copyWith(save: updatedSave);
    saveCurrentGame();
  }

  /// Tworzy dedykowany pociąg pomocników wokół lidera (np. pod Tour de France lub Klasyki)
  void createDedicatedSquad({
    required String squadName,
    required String leaderRiderId,
    required List<String> domestiqueRiderIds,
    required String targetSeasonObjective,
  }) {
    final curSave = state.save;
    if (curSave == null) return;

    final squadId = 'squad_${DateTime.now().millisecondsSinceEpoch}';
    final newSquad = TeamChemistryAndBuilderService.createDedicatedSquad(
      squadId: squadId,
      squadName: squadName,
      leaderRiderId: leaderRiderId,
      domestiqueRiderIds: domestiqueRiderIds,
      targetObjective: targetSeasonObjective,
      allRiders: curSave.riders,
    );

    final updatedSquads = [...curSave.dedicatedSquads, newSquad];
    final updatedSave = curSave.copyWith(dedicatedSquads: updatedSquads);

    state = state.copyWith(save: updatedSave);
    saveCurrentGame();
  }

  /// Zapisuje lub aktualizuje oficjalny skład wyścigowy na dany wyścig
  void saveRaceLineup({
    required String raceId,
    required String raceName,
    required String leaderRiderId,
    required List<String> domestiqueRiderIds,
  }) {
    final curSave = state.save;
    if (curSave == null) return;

    final existingIndex = curSave.dedicatedSquads.indexWhere(
      (s) => s.targetSeasonObjective == raceId || s.name == 'Skład: $raceName',
    );

    DedicatedSquad squad;
    if (existingIndex >= 0) {
      squad = curSave.dedicatedSquads[existingIndex].copyWith(
        leaderRiderId: leaderRiderId,
        domestiqueRiderIds: domestiqueRiderIds,
        targetSeasonObjective: raceId,
      );
    } else {
      final squadId = 'squad_${raceId}_${DateTime.now().millisecondsSinceEpoch}';
      squad = TeamChemistryAndBuilderService.createDedicatedSquad(
        squadId: squadId,
        squadName: 'Skład: $raceName',
        leaderRiderId: leaderRiderId,
        domestiqueRiderIds: domestiqueRiderIds,
        targetObjective: raceId,
        allRiders: curSave.riders,
      );
    }

    final updatedSquads = List<DedicatedSquad>.from(curSave.dedicatedSquads);
    if (existingIndex >= 0) {
      updatedSquads[existingIndex] = squad;
    } else {
      updatedSquads.add(squad);
    }

    CareerSave updatedSave = curSave.copyWith(dedicatedSquads: updatedSquads);

    // Automatyczna rejestracja w wyścigu jeśli drużyna ma prawo startu a jeszcze nie jest na liście
    final race = curSave.calendar.getRaceById(raceId);
    if (race != null && !race.participatingTeamIds.contains(curSave.playerTeamId)) {
      final status = RaceCalendarSelectionService.determineWildcardStatus(
        race: race,
        team: curSave.playerTeam,
        applications: curSave.wildcardApplications,
      );
      if (status.hasGuaranteedEntry || status == WildcardStatus.granted) {
        updatedSave = RaceCalendarSelectionService.registerTeamForRace(
          save: updatedSave,
          raceId: raceId,
        );
      }
    }

    state = state.copyWith(save: updatedSave);
    saveCurrentGame();
  }

  /// Organizuje zgrupowanie treningowe / obóz wysokogórski dla wybranego pociągu
  TrainingCampResult conductTrainingCamp({
    required DedicatedSquad squad,
    required TrainingCampType campType,
  }) {
    final curSave = state.save;
    if (curSave == null) {
      throw StateError('Brak aktywnego zapisu gry.');
    }

    final campAction = TeamChemistryAndBuilderService.conductTrainingCamp(
      currentSave: curSave,
      squad: squad,
      campType: campType,
    );

    // Zastępujemy zaktualizowany skład na liście
    final updatedSquads = curSave.dedicatedSquads.map((s) {
      return s.id == squad.id
          ? s.copyWith(
              cohesionScore: campAction.result.newCohesionScore,
              trainingCampsCount: s.trainingCampsCount + 1,
            )
          : s;
    }).toList();

    final finalSave = campAction.updatedSave.copyWith(dedicatedSquads: updatedSquads);

    state = state.copyWith(save: finalSave);
    saveCurrentGame();

    return campAction.result;
  }

  /// Przeprowadza audyt hierarchii i harmonii w szatni
  TeamHierarchyAudit? analyzeTeamHierarchy() {
    final curSave = state.save;
    if (curSave == null) return null;

    return TeamChemistryAndBuilderService.analyzeTeamHierarchy(
      teamRoster: curSave.playerRoster,
      franchiseLeaders: curSave.franchiseLeaders,
      squads: curSave.dedicatedSquads,
      team: curSave.playerTeam,
    );
  }

  /// Zwraca listę firm i korporacji poszukujących partnerstwa w peletonie
  List<PotentialSponsorCompany> getProspectiveSponsors({
    SponsorTier? tierFilter,
    SponsorIndustry? industryFilter,
  }) {
    return SponsorNegotiationService.getProspectingList(
      tierFilter: tierFilter,
      industryFilter: industryFilter,
    );
  }

  /// Składa pakiet ofertowy (Pitch Deck) sponsorowi i zwraca oficjalną decyzję zarządu
  SponsorPitchResult submitSponsorPitchDeck(SponsorPitchDeck pitchDeck) {
    final curSave = state.save;
    if (curSave == null) {
      throw StateError('Brak aktywnego zapisu gry.');
    }

    return SponsorNegotiationService.evaluatePitchDeck(
      currentSave: curSave,
      pitchDeck: pitchDeck,
    );
  }

  /// Podpisuje oficjalny kontrakt ze sponsorem i inkasuje pierwszą transzę finansową
  void acceptSponsorContract(SponsorContract contract) {
    final curSave = state.save;
    if (curSave == null) return;

    final updatedSave = SponsorNegotiationService.signSponsorContract(
      currentSave: curSave,
      contract: contract,
    );

    state = state.copyWith(save: updatedSave);
    saveCurrentGame();
  }

  /// Zwraca oferty producentów rowerów dostosowane do dywizji i budżetu zespołu
  List<ManufacturerOfferOption> getAvailableBikeManufacturerOffers() {
    final curSave = state.save;
    if (curSave == null) return const [];
    return BikeManufacturerNegotiationService.getAvailableManufacturerOffers(curSave);
  }

  /// Składa oficjalną ofertę negocjacyjną producentowi rowerów
  ManufacturerNegotiationResult submitBikeManufacturerProposal(
    ManufacturerNegotiationProposal proposal,
  ) {
    final curSave = state.save;
    if (curSave == null) {
      throw StateError('Brak aktywnego zapisu gry.');
    }

    return BikeManufacturerNegotiationService.evaluateProposal(
      currentSave: curSave,
      proposal: proposal,
    );
  }

  /// Podpisuje kontrakt ze sponsorem technicznym i dostarcza nową flotę rowerów
  void acceptBikeManufacturerDeal({
    required BikeManufacturerDeal deal,
    required ManufacturerDealTier dealTier,
    int initialPurchaseCostEur = 0,
  }) {
    final curSave = state.save;
    if (curSave == null) return;

    final updatedSave = BikeManufacturerNegotiationService.signManufacturerDeal(
      currentSave: curSave,
      deal: deal,
      dealTier: dealTier,
      initialPurchaseCostEur: initialPurchaseCostEur,
    );

    state = state.copyWith(save: updatedSave);
    saveCurrentGame();
  }

  /// Przeprowadza wspólną kampanię badawczą w tunelu aerodynamicznym z producentem rowerów
  WindTunnelTestReport conductWindTunnelTest(WindTunnelCampaignType campaignType) {
    final curSave = state.save;
    if (curSave == null) {
      throw StateError('Brak aktywnego zapisu gry.');
    }

    final result = BikeManufacturerNegotiationService.conductWindTunnelTest(
      currentSave: curSave,
      campaignType: campaignType,
    );

    state = state.copyWith(save: result.updatedSave);
    saveCurrentGame();
    return result.report;
  }

  /// Oblicza całościowy wskaźnik technologiczny sprzętu zespołu (0 - 100 pkt)
  double getTeamEquipmentProwessRating() {
    final curSave = state.save;
    if (curSave == null) return 50.0;
    return BikeManufacturerNegotiationService.calculateTeamEquipmentProwess(
      curSave.playerTeam,
    );
  }

  /// Zwraca listę dostępnych prestiżowych baz obozów wysokogórskich (Teide, Sierra Nevada, Livigno itd.)
  List<AltitudeCampLocation> getAvailableAltitudeCampLocations() {
    return TrainingAndCampsService.availableCampLocations;
  }

  /// Organizuje i realizuje zgrupowanie wysokogórskie dla wybranej grupy kolarzy
  AltitudeCampOutcome conductAltitudeTrainingCamp({
    required AltitudeCampLocation location,
    required List<String> riderIds,
    required int durationDays,
  }) {
    final curSave = state.save;
    if (curSave == null) {
      throw StateError('Brak aktywnego zapisu gry.');
    }

    final result = TrainingAndCampsService.conductAltitudeCamp(
      currentSave: curSave,
      location: location,
      riderIds: riderIds,
      durationDays: durationDays,
    );

    state = state.copyWith(save: result.updatedSave);
    saveCurrentGame();
    return result.outcome;
  }

  /// Zmienia indywidualny plan treningowy kolarza i aplikuje adaptację fizjologiczną
  void setRiderTrainingFocus({
    required String riderId,
    required RiderTrainingFocus focus,
    TrainingIntensity intensity = TrainingIntensity.moderate,
  }) {
    final curSave = state.save;
    if (curSave == null) return;

    final rider = curSave.getRiderById(riderId);
    if (rider == null) return;

    final updatedRider = TrainingAndCampsService.applyWeeklyTrainingFocus(
      rider: rider,
      focus: focus,
      intensity: intensity,
      coachStaffLevel: curSave.playerTeam.staff.trainersLevel,
    );

    final updatedRiders = curSave.riders.map((r) => r.id == riderId ? updatedRider : r).toList();
    final updatedSave = curSave.copyWith(riders: updatedRiders);

    state = state.copyWith(save: updatedSave);
    saveCurrentGame();
  }

  // ===========================================================================
  // KALENDARZ STARTOWY I DZIKIE KARTY (WILDCARDS)
  // ===========================================================================

  /// Zwraca zintegrowany przegląd całego kalendarza sezonu dla drużyny gracza
  List<TeamRaceCalendarEntry> getCalendarOverview() {
    final curSave = state.save;
    if (curSave == null) return const [];

    return RaceCalendarSelectionService.getCalendarOverviewForTeam(
      save: curSave,
      teamId: curSave.playerTeamId,
    );
  }

  /// Ustala aktualny status prawa startu / dzikiej karty drużyny gracza w danym wyścigu
  WildcardStatus getRaceWildcardStatus(TourRace race) {
    final curSave = state.save;
    if (curSave == null) return WildcardStatus.notEligible;

    return RaceCalendarSelectionService.determineWildcardStatus(
      race: race,
      team: curSave.playerTeam,
      applications: curSave.wildcardApplications,
    );
  }

  /// Przeprowadza symulację ewaluacji wniosku o Dziką Kartę (podgląd szans)
  WildcardEvaluation? evaluateWildcardForRace(TourRace race) {
    final curSave = state.save;
    if (curSave == null) return null;

    return RaceCalendarSelectionService.evaluateWildcardApplication(
      save: curSave,
      race: race,
      team: curSave.playerTeam,
    );
  }

  /// Składa oficjalny wniosek drużyny gracza o Dziką Kartę do organizatora wyścigu
  WildcardApplication? applyForWildcard(String raceId) {
    final curSave = state.save;
    if (curSave == null) return null;

    final updatedSave = RaceCalendarSelectionService.applyForWildcard(
      save: curSave,
      raceId: raceId,
    );

    state = state.copyWith(save: updatedSave);
    saveCurrentGame();

    // Zwracamy złożony wniosek
    return updatedSave.wildcardApplications.firstWhere(
      (a) => a.raceId == raceId && a.teamId == updatedSave.playerTeamId,
    );
  }

  /// Rejestruje drużynę w wyścigu (np. ProSeries / Class 1)
  void registerForRace(String raceId) {
    final curSave = state.save;
    if (curSave == null) return;

    final updatedSave = RaceCalendarSelectionService.registerTeamForRace(
      save: curSave,
      raceId: raceId,
    );

    state = state.copyWith(save: updatedSave);
    saveCurrentGame();
  }

  /// Wycofuje drużynę z wyścigu nieobowiązkowego
  void withdrawFromRace(String raceId) {
    final curSave = state.save;
    if (curSave == null) return;

    final updatedSave = RaceCalendarSelectionService.withdrawTeamFromRace(
      save: curSave,
      raceId: raceId,
    );

    state = state.copyWith(save: updatedSave);
    saveCurrentGame();
  }

  /// Przeprowadza całościową alokację dzikich kart dla wszystkich Grand Tourów i Monumentów
  void simulateSeasonWildcardAllocation() {
    final curSave = state.save;
    if (curSave == null) return;

    final updatedSave = RaceCalendarSelectionService.simulateSeasonWildcardAllocation(
      save: curSave,
    );

    state = state.copyWith(save: updatedSave);
    saveCurrentGame();
  }

  // ===========================================================================
  // MENEDŻER FINANSOWY KLUBU (CASHFLOW & BUDGET)
  // ===========================================================================

  /// Generuje szczegółowy raport przepływu gotówki za bieżący lub wybrany miesiąc
  MonthlyCashflowReport? getMonthlyCashflowReport({int? targetYear, int? targetMonth}) {
    final curSave = state.save;
    if (curSave == null) return null;

    return FinanceAndBudgetService.generateMonthlyCashflowReport(
      save: curSave,
      targetYear: targetYear,
      targetMonth: targetMonth,
    );
  }

  /// Przeprowadza manualnie comiesięczne rozliczenie finansowe
  void executeMonthlyFinancialSettlement() {
    final curSave = state.save;
    if (curSave == null) return;

    final updatedSave = FinanceAndBudgetService.processMonthlySettlement(
      save: curSave,
    );

    state = state.copyWith(save: updatedSave);
    saveCurrentGame();
  }

  /// Zleca profesjonalne badania laboratoryjne dla wybranej grupy kolarzy
  PhysiologicalTestingOutcome conductPhysiologicalTesting({
    required List<String> riderIds,
    required PhysiologicalTestType testType,
  }) {
    final curSave = state.save;
    if (curSave == null) {
      throw StateError('Brak aktywnego zapisu gry.');
    }

    final outcome = FinanceAndBudgetService.conductPhysiologicalTesting(
      save: curSave,
      riderIds: riderIds,
      testType: testType,
    );

    state = state.copyWith(save: outcome.updatedSave);
    saveCurrentGame();
    return outcome;
  }

  /// Sprzedaje zawodnika innemu klubowi z tytułu aktywacji klauzuli wykupu (Release Clause)
  RiderBuyoutTransferResult sellRiderViaBuyout({
    required String riderId,
    required String buyingTeamId,
    int? customBuyoutFeeEur,
  }) {
    final curSave = state.save;
    if (curSave == null) {
      throw StateError('Brak aktywnego zapisu gry.');
    }

    final result = FinanceAndBudgetService.processRiderBuyoutSale(
      save: curSave,
      riderId: riderId,
      buyingTeamId: buyingTeamId,
      customBuyoutFeeEur: customBuyoutFeeEur,
    );

    state = state.copyWith(save: result.updatedSave);
    saveCurrentGame();
    return result;
  }

  /// Dokonuje zakupu pakietu serwisowo-sprzętowego (szytki WT, łańcuchy, koła dyskowe)
  void purchaseEquipmentPackage(EquipmentConsumablePackage package) {
    final curSave = state.save;
    if (curSave == null) return;

    final updatedSave = FinanceAndBudgetService.purchaseEquipmentPackage(
      save: curSave,
      package: package,
    );

    state = state.copyWith(save: updatedSave);
    saveCurrentGame();
  }

  // ===========================================================================
  // SKAUTING MŁODZIEŻY & AKADEMIA ROZWOJOWA (YOUTH ACADEMY)
  // ===========================================================================

  /// Zwraca pełną pulę obserwowanych adeptów w skautingu
  List<ScoutedProspect> getScoutedProspects() {
    final curSave = state.save;
    if (curSave == null) return const [];
    if (curSave.scoutingProspects.isEmpty) {
      final initialPool = ScoutingAndYouthAcademyService.generateInitialScoutingPool(
        seasonYear: curSave.currentSeasonYear,
      );
      state = state.copyWith(save: curSave.copyWith(scoutingProspects: initialPool));
      saveCurrentGame();
      return initialPool;
    }
    return curSave.scoutingProspects;
  }

  /// Zwraca aktualny stan Akademii Młodzieżowej
  YouthAcademy? getYouthAcademy() {
    return state.save?.youthAcademy;
  }

  /// Wysyła skauta na zawody w celu weryfikacji i zawężenia widełek parametrów
  ScoutingMissionOutcome sendScoutOnMission(
    ScoutingSource source, {
    String? targetRegion,
  }) {
    final curSave = state.save;
    if (curSave == null) {
      throw StateError('Brak aktywnego zapisu gry.');
    }

    final outcome = ScoutingAndYouthAcademyService.sendScoutOnMission(
      save: curSave,
      source: source,
      targetRegion: targetRegion,
    );

    state = state.copyWith(save: outcome.updatedSave);
    saveCurrentGame();
    return outcome;
  }

  /// Zaprasza adepta na testy laboratoryjne do Service Course (100% odkrycia parametrów)
  ProspectLabTestingOutcome testProspectInLab(String prospectId) {
    final curSave = state.save;
    if (curSave == null) {
      throw StateError('Brak aktywnego zapisu gry.');
    }

    final outcome = ScoutingAndYouthAcademyService.inviteProspectToLabTesting(
      save: curSave,
      prospectId: prospectId,
    );

    state = state.copyWith(save: outcome.updatedSave);
    saveCurrentGame();
    return outcome;
  }

  /// Zapisuje adepta do Akademii Młodzieżowej
  void enrollProspectInAcademy(String prospectId) {
    final curSave = state.save;
    if (curSave == null) return;

    final updatedSave = ScoutingAndYouthAcademyService.enrollProspectInAcademy(
      save: curSave,
      prospectId: prospectId,
    );

    state = state.copyWith(save: updatedSave);
    saveCurrentGame();
  }

  /// Promuje wychowanka do pierwszego zespołu jako zawodowca (Neo-Pro)
  void promoteProspectToProTeam(
    String prospectId, {
    RiderRole role = RiderRole.neoPro,
    int? monthlySalaryEur,
  }) {
    final curSave = state.save;
    if (curSave == null) return;

    final updatedSave = ScoutingAndYouthAcademyService.promoteProspectToProTeam(
      save: curSave,
      prospectId: prospectId,
      role: role,
      monthlySalaryEur: monthlySalaryEur,
    );

    state = state.copyWith(save: updatedSave);
    saveCurrentGame();
  }

  /// Rozbudowuje Akademię Młodzieżową na wyższy poziom (1 -> 5)
  void upgradeYouthAcademy() {
    final curSave = state.save;
    if (curSave == null) return;

    final updatedSave = ScoutingAndYouthAcademyService.upgradeYouthAcademy(
      save: curSave,
    );

    state = state.copyWith(save: updatedSave);
    saveCurrentGame();
  }

  // ===========================================================================
  // MODDING & REAL NAME PACK SERVICE
  // ===========================================================================

  /// Waliduje składnię i strukturę JSON dla paczki modyfikacji
  ModValidationResult validateModJson(String jsonContent) {
    return CustomModImporterService.validateModJson(jsonContent);
  }

  /// Aplikuje paczkę modyfikacji z formatu JSON do aktywnego zapisu gry
  Future<ModApplyResult> applyModFromJson(String jsonContent) async {
    final curSave = state.save;
    if (curSave == null) {
      throw StateError('Brak aktywnego zapisu gry.');
    }

    final validation = CustomModImporterService.validateModJson(jsonContent);
    if (!validation.isValid) {
      final firstError = validation.errors.isNotEmpty
          ? validation.errors.first.message
          : 'Niepoprawny plik modyfikacji.';
      throw FormatException(firstError);
    }

    final package = await CustomModImporterService.importModFromBytes(
      utf8.encode(jsonContent),
    );

    final outcome = CustomModImporterService.applyModPackage(
      save: curSave,
      package: package,
    );

    state = state.copyWith(save: outcome.updatedSave);
    await saveCurrentGame();
    return outcome;
  }

  /// Aplikuje oficjalny sample pack (2026 WorldTour Real Name Pack z Tadejem Pogačarem, Vingegaardem itp.)
  Future<ModApplyResult> applySampleRealNamePack() async {
    final sampleJson = CustomModImporterService.generateSampleRealNamePackJson();
    return applyModFromJson(sampleJson);
  }

  /// Zapisuje podaną paczkę modyfikacji jako domyślny preset dla nowych karier
  Future<bool> saveModAsDefaultWorld(CustomModPackage package) async {
    return CustomModImporterService.saveModAsDefaultPreset(package);
  }

  /// Sprawdza, czy na dysku zapisany jest domyślny preset Real Name Pack
  Future<bool> hasDefaultModPreset() async {
    return CustomModImporterService.hasDefaultModPreset();
  }

  /// Usuwa domyślny preset modu
  Future<bool> deleteDefaultModPreset() async {
    return CustomModImporterService.deleteDefaultModPreset();
  }

  /// Wczytuje domyślny preset modu (jeśli istnieje)
  Future<CustomModPackage?> loadDefaultModPreset() async {
    return CustomModImporterService.loadDefaultModPreset();
  }

  /// Zwraca kod JSON gotowego wzorca 2026 WorldTour Real Name Pack
  String generateSampleRealNamePackJson() {
    return CustomModImporterService.generateSampleRealNamePackJson();
  }

  /// Dodaje autorski wyścig stworzony w Kreatorze Etapów do kalendarza aktywnej kariery
  Future<bool> addCustomRaceToCalendar(TourRace race) async {
    final curSave = state.save;
    if (curSave == null) return false;

    final updatedRaces = List<TourRace>.from(curSave.calendar.races)..add(race);
    final updatedCalendar = curSave.calendar.copyWith(races: updatedRaces);
    final updatedSave = curSave.copyWith(
      calendar: updatedCalendar,
      lastSavedAt: DateTime.now(),
    );

    state = state.copyWith(save: updatedSave);
    await saveCurrentGame();
    return true;
  }

  /// Eksportuje aktualny stan świata aktywnej kariery do formatu JSON modu
  String exportCurrentWorldAsModJson() {
    final curSave = state.save;
    if (curSave == null) {
      throw StateError('Brak aktywnego zapisu gry.');
    }
    return CustomModImporterService.exportCurrentSaveAsModJson(curSave);
  }
}

/// Globalny dostawca Riverpod dla trybu kariery
final careerProvider =
    StateNotifierProvider<CareerController, CareerUiState>((ref) {
  return CareerController();
});

final careerControllerProvider = careerProvider;

