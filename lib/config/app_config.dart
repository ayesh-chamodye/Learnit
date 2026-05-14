/// Configuration for external APIs
/// IMPORTANT: Replace the placeholder API key with your actual YouTube Data API v3 key
/// from Google Cloud Console: https://console.cloud.google.com/apis/credentials
class AppConfig {
  // YouTube Data API v3 configuration
  static const String youtubeApiKey = 'AIzaSyAjS8ezAYm-FvN-rXBTWSyKIxLbDJ4LHmo';

  // YouTube API base URL
  static const String youtubeApiBaseUrl = 'www.googleapis.com';

  // e-Thaksalawa API configuration
  static const String ethaksalawaBaseUrl = 'v0-json-url-service.vercel.app';
  static const String ethaksalawaApiPath = '/api/e-thaksalawa';
  static const int ethaksalawaCacheTimeoutHours = 24; // Cache duration in hours

  // Default max results for API calls
  static const int defaultMaxResults = 25;

  // Whether to use the YouTube Data API (true) or fall back to RSS (false)
  static bool get useYouTubeApi => youtubeApiKey.isNotEmpty && youtubeApiKey != 'YOUR_YOUTUBE_API_KEY_HERE';

  // URLs for downloading JSON data files (set these to your hosted JSON endpoints)
  // These JSON files should contain arrays of course/pdf objects matching the model structures
  static const String coursesJsonUrl = 'https://v0-json-url-service.vercel.app/api/e-thaksalawa/courses';
  static const String pdfsJsonUrl = 'https://v0-json-url-service.vercel.app/api/scrape/past-papers';
}