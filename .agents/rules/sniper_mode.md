# Zasady Trybu Snajpera (Sniper Mode — Hydrogen)

Te reguły obowiązują bezwzględnie przy każdym zadaniu wykonywanym z kolejki `docs/QUEUE.md`.

## 1. Ekonomia Tokenów
- **Zawsze zaczynaj od przeczytania `docs/CODE_MAP.md`**.
- **Nie skanuj całego repozytorium** (`dir`, `find`, `grep` po całym projekcie), jeśli ścieżki plików znajdują się w `docs/CODE_MAP.md`. Czytaj wyłącznie konkretne pliki potrzebne do bieżącego zadania.
- **Odpowiedzi na czacie ogranicz do maksimum 2 krótkich zdań** — cała moc ma iść w kod.

## 2. Jakość AAA i Zero Prowizorki
- **Całkowity zakaz używania `// TODO`, `placeholder`, pustych metod czy uproszczonych stylów.**
- Każdy element UI i kodu musi być ukończony w 100% produkcyjnie:
  - pełne stany `hover` / `active` / `disabled` / `focus`,
  - płynne animacje (`200–350ms`, `Curves.easeOutCubic` / `AnimationController`),
  - obsługa błędów i przypadków brzegowych (null-safety, puste listy, wartości graniczne),
  - czyste typowanie Dart bez zbędnego `dynamic`.
- **Responsywność i brak przepełnień**: używaj `LayoutBuilder`, `Expanded`/`Flexible`, `SingleChildScrollView` tak, aby uniknąć `RenderFlex overflowed` w rozdzielczościach `390x844` (mobile), `1024x768` (tablet) i `1600x900` (desktop).
- **Spójność wizualna**: stosuj wyłącznie paletę `AppColors` (`#0F1115`, `#181B22`, `#222630`, `#8E4A49`, `#D4AF37`, `#2A2F3D`), czcionkę `Inter` oraz karty `BorderRadius.circular(16)` z obramowaniem `1px`.

## 3. Transakcyjność (Odporność na Limit)
Po ukończeniu **każdego pojedynczego zadania** z `docs/QUEUE.md` wykonaj obowiązkowo wszystkie 4 kroki w tej kolejności:
1. **(a) Weryfikacja kompilacji i testów**: uruchom `flutter analyze` (na nowych/zmienionych plikach oraz powiązanych testach) i napraw wszystkie błędy lub ostrzeżenia.
2. **(b) Aktualizacja mapy kodu**: dopisz nowe pliki i główne klasy w **1 linijce** do `docs/CODE_MAP.md`.
3. **(c) Aktualizacja kolejki**: zmień w `docs/QUEUE.md` status ukończonego zadania z `- [ ]` na `- [x]`.
4. **(d) Commit transakcyjny**: wykonaj w terminalu:
   `git add -A && git commit -m "Queue: ukończono zadanie [numer]"`
