# ClosedBikeSensor

An iOS app for measuring passing distances while cycling using your iPhone's LiDAR sensor. Inspired by the OpenBikeSensor project, but simpler and taking advantage of the LiDAR capabilities already built into modern iPhones.

## What It Does

Mount your phone on the left side of your handlebar with a mirror attachment that redirects the LiDAR beam and camera sideways. When cars pass, press the volume button (or tap the screen) to capture:
- Distance to the passing vehicle
- GPS coordinates
- Photo of the situation
- Timestamp

Everything is organized into sessions so you can analyze your rides later. The mirror setup lets you measure to the side while keeping your phone facing forward on the handlebar.

## Why This App

- **Privacy first**: All data stays on your device. No cloud sync, no telemetry, no ads.
- **Simple**: Built as a learning project to explore ARKit and SwiftData
- **Practical**: Uses hardware you already have (iPhone 12 Pro or newer) and a simple mirror attachment

## Requirements

- iPhone 12 Pro or newer (needs LiDAR sensor)
- iOS 26.0 or later
- Camera and location permissions
- Handlebar phone mount (left side)
- 3D-printed mirror attachment (STL files in repo)

## How To Use

### Hardware Setup
1. 3D print the mirror attachment (STL files available in the repo or on Makerworld)
2. Mount your phone holder on the **left side** of your handlebar
3. Install the phone with the mirror attachment - the mirror redirects the LiDAR beam and camera 90° to measure passing traffic
4. The phone faces forward, but measures to the side

### First Time Setup
Grant camera and location permissions when prompted. The app won't work without them.

### Taking Measurements
1. Open the **Live** tab
2. The crosshair shows where you're measuring (to your left side via the mirror)
3. When a car passes, press the **volume up button** on the left side of your phone (easiest to reach while riding)
4. Alternatively, tap the red capture button on screen

**Color coding**: Red (≤1.0m) means dangerous, yellow (≤1.5m) is a warning, green (>1.5m) is safe.

### Managing Sessions
Sessions start automatically. Your current session survives app restarts during the same day. To switch sessions or adjust the crosshair position, tap "Bearbeiten" (Edit) in the Live view.

### Viewing Your Data
- **Sessions tab**: See all your rides with statistics and charts
- **Map tab**: View where you took measurements with color-coded markers
- Tap any session or measurement for detailed information

## Technical Notes

### How It Works
The app uses ARKit to process LiDAR depth data in real-time. A small region of interest around the crosshair is sampled and smoothed to reduce jitter. Everything runs on a background queue to keep the UI responsive.

### Data Storage
All data is stored locally using SwiftData. Photos are automatically resized to 1024px and compressed. Nothing ever leaves your device.

### Accuracy
LiDAR works best on matte surfaces in good lighting. Optimal range is 0.5m to 5m. As far as I tested it, the mirror setup works well as is fairly accurate. If measurements seem off, you can adjust the crosshair offset in edit mode.

## Project Status

This is a student's side project built to learn iOS development. It works well for its intended purpose but don't expect polish everywhere. Contributions and feedback are welcome.

## Future Ideas

- Export sessions as CSV or GPX
- Shortcuts integration for remote triggering of measurements
- Data sharing with OpenBikeSensor community
- Automatic triggering of measurements (e.g. via CoreML)

## Architecture

The codebase follows simple principles:
- **Models**: MeasurePoint and MeasureSession (SwiftData)
- **Backend**: DistanceRetrieval (ARKit processing) and CaptureManager (saving data)
- **Config**: RetrievalConfig singleton for shared state
- **Views**: OnboardingView, LiveDistanceView, ListView, MapView, MeasurementDetailView

## Privacy & Data

Worth emphasizing again: This app collects no data about you. Everything stays on your device. No analytics, no crash reporting, no nothing. Your measurements are yours alone.