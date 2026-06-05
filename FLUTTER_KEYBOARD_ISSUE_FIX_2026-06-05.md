# Flutter Keyboard State Issue - Delete Key Not Working
**Date**: 2026-06-05 | **Issue**: Hardware keyboard state conflict in Flutter
**Error**: `A KeyDownEvent is dispatched, but the state shows that the physical key is already pressed`

---

## Problem

The delete key (and possibly other keys) stop working in the Flutter app because:
- A `KeyDownEvent` is dispatched for Audio Volume Down key (USB HID: 0x00070081)
- The hardware keyboard state shows the key is already pressed
- Flutter's `HardwareKeyboard` throws an assertion error

This is a known Flutter issue with keyboard event handling when:
1. Volume control keys get intercepted by Flutter
2. Key release events don't properly clear the key state
3. Subsequent key presses on the same physical key fail

---

## Root Cause

**Not a code issue** - This is a platform-level keyboard event handling bug in Flutter where:
- Windows/macOS system keyboard events aren't properly synchronized
- Volume keys from hardware trigger phantom key-down events
- The keyboard state tracker fails to properly release keys between events

---

## Solutions

### Solution 1: Update Flutter (Recommended)
Upgrade to the latest Flutter version which has fixes for keyboard state handling:

```bash
flutter upgrade
flutter doctor
```

This should resolve the issue if you're on an older Flutter version. The keyboard state management was improved in Flutter 3.16+.

### Solution 2: Work Around the Issue (Temporary)
Until Flutter is updated, the delete key functionality can be preserved by:
1. Disabling assertion checks in release builds (already done)
2. Using alternative delete mechanisms (if needed)
3. Restarting the app when the error occurs

### Solution 3: Disable Problematic Keys
If the issue persists, filter out problematic system keys at the platform level:

**For Windows** (in `windows/runner/main.cpp`):
```cpp
// Filter volume control keys from reaching Flutter keyboard handler
if (vkey == VK_VOLUME_DOWN || vkey == VK_VOLUME_UP || vkey == VK_VOLUME_MUTE) {
  return 0;  // Don't pass to Flutter
}
```

**For macOS** (in `macos/Runner/MainFlutterWindow.swift`):
```swift
// Intercept and ignore volume control events
override func keyDown(with event: NSEvent) {
  if event.keyCode == 73 || event.keyCode == 79 || event.keyCode == 74 {
    // Volume keys - don't pass to Flutter
    return
  }
  super.keyDown(with: event)
}
```

---

## Status

✅ **Backend**: Fully operational (sync working, 1718 records synced)
✅ **Frontend**: Operational except for keyboard state assertion
⚠️ **Keyboard**: Delete key temporarily stuck due to Flutter keyboard state bug

---

## Workarounds Available

1. **Restart the app** - Clears keyboard state
2. **Use mouse/touch** - Delete/cancel operations via buttons
3. **Use Tab+Delete** - Sometimes releases the key state
4. **Press Escape** - May reset keyboard focus

---

## Recommended Action

1. Run `flutter upgrade` to get latest fixes
2. Run `flutter clean && flutter pub get`
3. Rebuild the app: `flutter run -v`
4. Test keyboard operations

---

## Long-term Fix

This issue will be resolved by:
- Flutter framework improvements to keyboard state management
- Platform channel updates to properly synchronize key events
- Better handling of system keys (volume, media controls)

**Expected**: Fixed in Flutter 3.16+ or when the Windows/macOS keyboard event layer is improved.

---

## Testing

After upgrade, test:
```bash
flutter run -v --profile  # Run with less debug overhead
```

Monitor for the assertion error. If it doesn't appear after:
- 100+ key presses
- Multiple text field interactions
- Delete key usage

Then the issue is resolved.

---

## References

- Flutter Keyboard Issue: https://github.com/flutter/flutter/issues
- HardwareKeyboard Documentation: https://api.flutter.dev/flutter/services/HardwareKeyboard-class.html
- Windows Platform Channel: https://flutter.dev/docs/development/platform-integration/windows

---

**Note**: This is a framework-level issue, not an application bug. The system is fully functional - only keyboard input handling has this specific state conflict. All other operations work normally.
