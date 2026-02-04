# ImageFlow

This project is an image processing application developed for Codeway case study by me :)

Note: This app has been tested on Android devices only and has not yet been tested on iOS.

### Face Detection Mode
- Detects faces in real-time using Google ML Kit Face Detection
- Applies artistic grayscale filter specifically to detected face regions
- Preserves the original colors of the surrounding area for a unique visual effect
- Supports both camera capture and gallery import

### Document Scanning Mode
- Intelligent text recognition using Google ML Kit Text Recognition
- Automatic document enhancement with contrast and brightness adjustments
- Exports processed documents as high-quality PDF files
- Visual guide frame overlay for easy document positioning

## Key Features

### Batch Processing
Process multiple images simultaneously with our advanced batch processing system:
- **Multi-select from gallery** - Choose multiple images at once
- **Queue-based processing** - Efficient background processing with real-time progress tracking
- **Persistent queue** - Resumes incomplete batches after app restart
- **Auto-cleanup** - Removes stale batches older than 2 days
- **Summary view** - Review all processed results in a unified view
- **Retry mechanism** - Failed items can be retried individually or in batch

### Multi-page PDF Support
Create professional multi-page PDF documents with ease:
- **Add Page button** - Seamlessly add more pages after each scan
- **Drag-and-drop reordering** - Reorganize pages by simply dragging them
- **Page preview** - Preview all pages before final PDF export
- **Individual page removal** - Remove unwanted pages with a single tap
- **Session management** - Maintains page state throughout the scanning session

### Processing History
- Local storage of all processed scans using Hive
- View original and processed images side by side
- Access metadata and processing details
- Share processed files directly from the app

## Architecture & Best Practices

### Clean Architecture
The codebase follows Clean Architecture principles with clear separation of concerns:

```
lib/
├── core/           # Shared utilities, services, themes, and error handling
│   ├── errors/     # Custom exception types (AppException)
│   ├── services/   # Core services (ImageProcessing, PDF, Detection, etc.)
│   ├── theme/      # App theming and design tokens
│   └── utils/      # Utility functions
├── data/           # Data layer - models and repository implementations
│   ├── models/     # Data models (ScanModel, BatchJob, BatchItem)
│   └── repositories/
├── domain/         # Business logic layer
│   ├── entities/   # Domain entities
│   ├── repositories/ # Repository interfaces
│   └── usecases/   # Use cases (ProcessFace, ProcessDocument, SaveScan, etc.)
└── presentation/   # UI layer
    ├── controllers/ # GetX controllers for state management
    ├── pages/      # Screen implementations
    ├── routes/     # Navigation routing
    └── widgets/    # Reusable UI components
```

### Design Patterns & Best Practices

#### Dependency Injection
- All services and repositories are registered via GetX's dependency injection
- Loose coupling between layers enables easy testing and maintenance

#### Repository Pattern
- Abstract repository interfaces in the domain layer
- Concrete implementations in the data layer
- Enables easy swapping of data sources

#### Use Case Pattern
- Single-responsibility use cases for each business operation
- `ProcessFaceUseCase`, `ProcessDocumentUseCase`, `SaveScanUseCase`, `GetScansUseCase`

#### Reactive State Management
- GetX reactive programming with `Rx` observables
- Real-time UI updates based on state changes
- Worker-based listeners for background operations

#### Background Processing
- Compute isolates for heavy image processing operations
- Queue-based batch processing with foreground service support
- Persistent job tracking across app sessions

#### Error Handling
- Custom `AppException` class for consistent error handling
- Graceful fallbacks for detection failures
- User-friendly error messages via snackbars

## Dependencies

### Core Framework
| Package | Purpose |
|---------|---------|
| flutter | UI framework |
| get | State management & dependency injection |

### ML Kit & Image Processing
| Package | Purpose |
|---------|---------|
| google_mlkit_face_detection | Face detection and contour extraction |
| google_mlkit_text_recognition | OCR for document text detection |
| google_mlkit_document_scanner | Native document scanning |
| image | Image manipulation and processing |

### Media & Files
| Package | Purpose |
|---------|---------|
| camera | Camera access and preview |
| image_picker | Gallery image selection |
| pdf | PDF generation |
| path_provider | File system paths |

### Storage & Utilities
| Package | Purpose |
|---------|---------|
| hive | Local NoSQL database |
| hive_flutter | Flutter bindings for Hive |
| uuid | Unique ID generation |
| intl | Date/time formatting |

### Sharing & Platform
| Package | Purpose |
|---------|---------|
| share_plus | Native sharing functionality |
| open_file | Open files with default apps |
| permission_handler | Runtime permissions |

### Development
| Package | Purpose |
|---------|---------|
| very_good_analysis | Strict lint rules |
| flutter_test | Testing framework |

## Getting Started

### Prerequisites
- Flutter SDK >= 3.2.0 < 4.0.0
- Dart SDK (included with Flutter)
- Android Studio / Xcode for platform-specific builds
- Physical device recommended (camera features)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd ImageFlow
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

### Platform-Specific Setup

#### Android
- Minimum SDK: 21 (Android 5.0)
- Camera and storage permissions are requested at runtime
- ML Kit models are downloaded on first use

#### iOS
- Minimum iOS version: 12.0
- Add camera and photo library usage descriptions to `Info.plist`:
  ```xml
  <key>NSCameraUsageDescription</key>
  <string>ImageFlow needs camera access for scanning</string>
  <key>NSPhotoLibraryUsageDescription</key>
  <string>ImageFlow needs photo library access to import images</string>
  ```

## Advanced Features

### Batch Processing Workflow
1. Select multiple images from the gallery
2. Choose processing intent (Face or Document)
3. Monitor real-time progress on the batch processing screen
4. Review all results in the summary view
5. Retry failed items or export successful ones

### Multi-page PDF Workflow
1. Scan your first document page
2. Tap "Add Page" to scan additional pages
3. Reorder pages by dragging them
4. Remove unwanted pages with the delete button
5. Tap "Export PDF" to generate the final document
