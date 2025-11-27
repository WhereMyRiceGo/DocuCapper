# DocuCapper Copilot Instructions

## Project Overview
**DocuCapper** is a Flutter mobile app that captures document images, extracts text via OCR (Google ML Kit), and summarizes extracted content using OpenAI's API. The app maintains a history of scanned documents and a notes database.

## Architecture

### Core Data Flow
1. **Image Capture**: `PickImageScreen` → `ImagePicker` (gallery/camera)
2. **Text Extraction**: `OcrScreen` → `google_mlkit_text_recognition` 
3. **Summarization**: `SummaryScreen` → `OpenAIService` (GPT-4o-mini API)
4. **Persistence**: `StorageService` → `SharedPreferences` (local JSON storage)

### Key Files & Responsibilities
- **`lib/main.dart`** — Entry point; sets up MaterialApp with PickImageScreen as home
- **`lib/services/openai_service.dart`** — Static class for OpenAI API calls (summarize method)
- **`lib/services/storage_service.dart`** — Static CRUD methods for notes and scan history via SharedPreferences
- **`lib/models/{note.dart, scan_history_item.dart}`** — Data models with `toJson()`/`fromJson()` for serialization
- **`lib/screens/`** — Stateful widgets (OCR, Summary, Notes, History views); use StatefulWidget + initState for async operations

### Navigation Pattern
Uses Flutter's imperative `Navigator.push()` with `MaterialPageRoute`. Entry points:
- `PickImageScreen` (home) → `OcrScreen` (image selected)
- `OcrScreen` → `SummaryScreen` (after OCR completes)
- `PickImageScreen` → `NotesScreen` / `HistoryScreen` (sidebar navigation)

## Development Workflow

### Build & Run
```bash
flutter pub get        # Install dependencies
flutter run            # Run on connected device/emulator
flutter clean          # Clean build artifacts (try if issues persist)
```

### Testing & Linting
```bash
flutter analyze        # Check for lint issues (rules in analysis_options.yaml)
flutter test           # Run unit tests (add to test/ directory)
```

## Project Conventions & Patterns

### Serialization Pattern
All models follow `toJson()`/`fromJson()` convention:
```dart
// In models
Map<String, dynamic> toJson() => {"field": field, ...};
factory Model.fromJson(Map json) => Model(field: json["field"], ...);

// In services
final list = jsonDecode(raw) as List;
return list.map((e) => Model.fromJson(e)).toList();
```

### Async Screen Pattern
Screens that fetch data use `initState()` + `setState()`:
- Call async service methods in `initState()`
- Show loading state initially (e.g., "Summarizing...")
- Update UI via `setState()` when data arrives
- Example: `SummaryScreen` calls `OpenAIService.summarize()` in initState

### Storage Service Pattern
`StorageService` is a static utility class with two domains:
- **Notes**: `getNotes()`, `saveNote(text)` — auto-generates title from first line
- **History**: `getHistory()`, `addToHistory(imagePath, extractedText)` — tracks OCR scans
- Both use UUID (v4) for unique IDs and `DateTime.now().toString()` for timestamps

### API Error Handling
`OpenAIService.summarize()` currently:
- Returns error message string on API failure (check `data["error"]`)
- Returns fallback message if `choices` is empty
- **Improve this**: Throw typed exceptions instead of returning strings for better error propagation

## Critical Dependencies
- **`google_mlkit_text_recognition`** — Local OCR; requires Android/iOS native config
- **`image_picker`** — Requires native camera/gallery permissions
- **`http`** — Raw HTTP calls to OpenAI (no wrapper package)
- **`shared_preferences`** — Local key-value store (not encrypted; suitable for non-sensitive data)
- **`uuid`** — ID generation

## External Integration Points
- **OpenAI API**: Hardcoded key in `openai_service.dart` (⚠️ **SECURITY RISK** — move to environment variables)
- **Flutter channels**: OCR uses native ML Kit; permissions required on Android/iOS

## Common Tasks
- **Add a new screen**: Create `StatefulWidget` in `lib/screens/`; use `Navigator.push()` from caller
- **Add a data model**: Create in `lib/models/`; implement `toJson()`/`fromJson()`; add storage methods to `StorageService`
- **Add a new API call**: Create static method in service class (e.g., `openai_service.dart`); handle errors explicitly
- **Modify storage schema**: Update model's `toJson()`/`fromJson()`; **migration not implemented** — breaking changes lose data

## Communication Style
- Answer in 1-2 sentences when possible
- No introductions or explanations unless asked
- Code examples only if directly requested
