/// Configuration for external APIs
/// IMPORTANT: Replace the placeholder API key with your actual YouTube Data API v3 key
/// from Google Cloud Console: https://console.cloud.google.com/apis/credentials
class AppConfig {
  // YouTube Data API v3 configuration
  static const String youtubeApiKey = 'AIzaSyAjS8ezAYm-FvN-rXBTWSyKIxLbDJ4LHmo';

  // YouTube API base URL
  static const String youtubeApiBaseUrl = 'www.googleapis.com';

  // Default max results for API calls
  static const int defaultMaxResults = 25;

  // Whether to use the YouTube Data API (true) or fall back to RSS (false)
  static bool get useYouTubeApi => youtubeApiKey.isNotEmpty && youtubeApiKey != 'YOUR_YOUTUBE_API_KEY_HERE';
}
