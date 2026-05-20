import 'package:flutter/foundation.dart';

/// Google Maps が利用できるプラットフォームか
bool get isGoogleMapsSupported {
  if (kIsWeb) return true;
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
    case TargetPlatform.iOS:
      return true;
    default:
      return false;
  }
}
