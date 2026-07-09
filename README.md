# LearnIt

**LearnIt** is a comprehensive, cross-platform learning mobile application built with Flutter that aggregates educational resources including PDFs, videos, and web content for students. It provides a unified interface to access past papers, model papers, teacher guides, term test papers, textbooks, and YouTube educational content with built-in progress tracking and offline capabilities.

## 🎯 Features

### Resource Access
- **PDF Materials**: Browse and view past papers, model papers, teacher guides, term tests, and textbooks
- **Video Courses**: Access educational videos from Channel NIE and Ethaksalawa YouTube channels
- **Multi-Format Support**: View PDFs, HTML content, and video lectures in a single app
- **Search Functionality**: Find resources across all content types

### Learning Features
- **Progress Tracking**: Monitor your learning journey with detailed progress metrics
  - Track video watch progress and completion
  - Monitor PDF reading progress (page-by-page)
  - View completion status and timestamps
- **Learning Statistics**: Dashboard showing:
  - Total videos watched and completed
  - Total PDFs read and completed
  - Watch time analytics
  - Learning streaks and last activity
- **Category Organization**: Resources organized into intuitive categories:
  - Past Papers
  - Model Papers
  - Teacher Guides
  - Term Test Papers
  - Text Books

### User Experience
- **Dark/Light Theme**: Full Material Design 3 theming support with preference persistence
- **Material Design 3**: Modern UI with rounded corners, proper spacing, and accessibility
- **AdMob Integration**: Monetization through banner ads
- **Cross-Platform**: Available on Android, iOS, Windows, macOS, Linux, and Web
- **Settings Management**: Customize theme preferences and app behavior

## 📱 Tech Stack

- **Language**: Dart (50%)
- **Framework**: Flutter 3.11.5+
- **Architecture**: Modular structure with clear separation of concerns
- **State Management**: Widget-based state management
- **Storage**: SharedPreferences for local data persistence
- **HTTP Client**: Dio for robust API calls with timeout handling
- **Key Libraries**:
  - `flutter_pdfview` - PDF viewing
  - `youtube_player_flutter` - YouTube video playback
  - `webview_flutter` - HTML content rendering
  - `video_player` - Video playback support
  - `google_mobile_ads` - AdMob integration
  - `shared_preferences` - Local data persistence
  - `file_picker` - File selection capability
  - `http` & `dio` - Network requests

## 📁 Project Structure

```
lib/
├── main.dart                      # App entry point, theme configuration
├── config/
│   └── app_config.dart           # API configuration flags
├── models/
│   ├── course_model.dart         # YouTube course/video data model
│   ├── pdf_model.dart            # PDF resource data model
│   └── video_model.dart          # Video metadata model
├── screens/
│   ├── splash_screen.dart        # App initialization screen
│   ├── home_screen.dart          # Main navigation hub (bottom nav)
│   ├── category_screen.dart      # PDF category browser
│   ├── courses_screen.dart       # Video courses listing
│   ├── course_category_screen.dart# Course subcategories
│   ├── pdf_viewer_screen.dart    # PDF reading interface
│   ├── video_player_screen.dart  # Video playback screen
│   ├── html_viewer_screen.dart   # Web content renderer
│   ├── progress_screen.dart      # Learning analytics dashboard
│   └── settings_screen.dart      # User preferences
├── services/
│   ├── api_service.dart          # PDF & video API integration
│   ├── api_client.dart           # Dio HTTP client configuration
│   ├── youtube_api_service.dart  # YouTube Data API interface
│   ├── ethaksalawa_service.dart  # Ethaksalawa content service
│   └── progress_service.dart     # Learning progress persistence
└── widgets/                      # Reusable UI components

android/                           # Android native code
ios/                              # iOS native code
web/                              # Web platform files
windows/                          # Windows native code
macos/                            # macOS native code
linux/                            # Linux native code
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (^3.11.5)
- Dart SDK (included with Flutter)
- Android SDK (for Android development)
- Xcode (for iOS development)

### Installation

1. **Clone the repository**
```bash
git clone https://github.com/ayesh-chamodye/Learnit.git
cd Learnit
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Run the app**
```bash
# Android
flutter run -d android

# iOS
flutter run -d ios

# Web
flutter run -d chrome

# Windows/macOS/Linux
flutter run -d windows  # or macos/linux
```

4. **Build for production**
```bash
# Android APK
flutter build apk

# iOS IPA
flutter build ios

# Web
flutter build web
```

## 🔌 API Integration

### Data Sources
- **PDF Resources**: Fetched from `v0-json-url-service.vercel.app` with pagination support
- **YouTube Videos**: 
  - Optional YouTube Data API integration (configurable)
  - Fallback RSS feed parsing from YouTube channels
  - Supported channels: Channel NIE, Ethaksalawa

### Progress Storage
- **Local Storage**: All progress data stored in device's SharedPreferences
- **Offline Capable**: Learning progress works without internet connection
- **Sync**: Manual refresh required for updated content

## ⚙️ Configuration

### App Config
Edit `lib/config/app_config.dart` to configure:
- YouTube API usage (enabled/disabled)
- API endpoints
- Timeout values
- Feature flags

### Theme Customization
Modify `lib/main.dart` to adjust:
- Color scheme and Material Design 3 colors
- Typography
- Component theming (AppBar, BottomNav, Cards, etc.)

## 🎓 Learning Features

### Progress Tracking
The app automatically tracks:
- **Video Progress**: Saves watch position and marks videos as complete when 95%+ watched
- **PDF Progress**: Tracks current page and total pages read
- **Timestamps**: Records first access, last access, and completion time

### Statistics Dashboard
View your learning metrics:
- Videos watched and completed counts
- PDFs read and completed counts
- Total watch time
- Activity streaks
- Last active date

## 🔐 Security & Privacy

- No user authentication required
- All data stored locally on device
- No tracking or telemetry beyond analytics
- AdMob integration for monetization
- Standard Flutter security practices

## 🐛 Known Limitations

- Offline content requires manual download (not yet implemented)
- YouTube API key required for full video functionality
- AdMob IDs need to be configured for production builds
- Limited search across local cached data

## 📊 Architecture Highlights

### Service Layer
- **ApiService**: Handles PDF fetching with pagination and caching logic
- **YouTubeApiService**: Manages YouTube Data API requests
- **ProgressService**: Manages all learning progress persistence
- **ApiClient**: Centralized Dio configuration with timeouts and error handling

### Data Models
- **CourseItem**: Represents video courses with flexible JSON parsing
- **PdfItem**: Represents PDF resources with metadata
- **VideoItem**: Video metadata for playback
- **LearningProgress**: Comprehensive progress tracking model
- **LearningStats**: Aggregate learning statistics

### UI Architecture
- **Bottom Navigation**: Four main tabs (Resources, Courses, Progress, Settings)
- **Responsive Design**: Adapts to different screen sizes
- **Material Design 3**: Modern, accessible UI components
- **Theme Support**: Full dark mode support with Material color schemes

## 🚧 Future Roadmap

- [ ] Offline content sync
- [ ] User authentication and cloud backup
- [ ] Personalized recommendations
- [ ] Advanced search with filters
- [ ] Study groups and collaboration
- [ ] Push notifications for new content
- [ ] Bookmark and note-taking features
- [ ] Advanced analytics dashboard

## 📝 License

This project is private and under development.

## 👨‍💻 Contributing

This is a personal project. For contributions or suggestions, please open an issue.

## 📧 Support

For issues or questions, please refer to the GitHub issues section.

---

**Built with ❤️ using Flutter**
