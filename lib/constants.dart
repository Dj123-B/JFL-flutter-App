// lib/utils/constants.dart
import 'dart:io';

/// Centralized base URL for all API calls.
/// Automatically switches between Android emulator and iOS/localhost.
final String baseUrl = Platform.isAndroid
    ? "http://10.0.2.2:5000" // for Android emulator
    : "http://localhost:5000"; // for iOS/desktop
