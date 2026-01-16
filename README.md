# ClosedBikeSensor 🚲

An iOS app for measuring passing distances while cycling using your iPhone's LiDAR sensor. Funcionaly inspired by the [OpenBikeSensor](https://www.openbikesensor.org/) project, but this app leverages the built-in LiDAR capabilities of modern iPhones for a simpler, hardware-integrated solution.

## Overview

Mount your phone on the left side of your handlebar using a 3D-printed mirror attachment (STL files in repo) that redirects the LiDAR beam and camera sideways. This allows you to measure passing traffic while keeping the phone facing forward for easy navigation and interaction.

### Key Features
- **LiDAR Precision**: Uses ARKit to process real-time depth data (optimal range: 0.5m – 5m).
- **Physical Trigger**: Use the **volume up button** as a tactile shutter while riding, or tap the screen.
- **Privacy First**: All data (GPS, photos, measurements) is stored locally via SwiftData. No cloud, no ads.
- **Visual Feedback**: Color-coded markers: Red (≤1.0m), Yellow (≤1.5m), and Green (>1.5m).

## Requirements

- iPhone 12 Pro or newer (LiDAR sensor required)
- iOS 26.0 or later
- Camera and Location permissions
- Left-side handlebar mount + 3D-printed mirror attachment

## How To Use

1. **Hardware Setup**: Mount the phone on the left side of your handlebar. The mirror attachment must redirect the camera/LiDAR 90° to the left.
2. **First Run**: Grant camera and location permissions. 
3. **Capture**: In the **Live** tab, press the volume button when a car passes. The crosshair indicates the sampling area (adjustable in "Edit" mode).
4. **Analysis**: 
   - **Sessions**: View ride statistics and charts.
   - **Map**: See color-coded measurement markers on an interactive map.

## Technical Implementation

- **Data Capture**: A background queue samples and smoothes LiDAR depth data around the crosshair to reduce jitter.
- **Storage**: Photos are compressed and stored alongside GPS data using **SwiftData**.
- **Accuracy**: Optimized for matte surfaces; accuracy can be calibrated by adjusting the crosshair offset.

## Project Status

This is a student side project built to learn iOS development. I utilized AI assistance specifically for setting up the ARKit/LiDAR communication and boilerplate logic. While functional and reliable for its intended purpose, it is a work in progress.

### Future Ideas
- CSV/GPX export for data analysis.
- OpenBikeSensor community data sharing.
- Automatic measurement triggering via CoreML.

## Architecture
- **Models**: `MeasurePoint`, `MeasureSession` (SwiftData)
- **Logic**: `DistanceRetrieval` (ARKit processing), `CaptureManager` (Persistence)
- **Views**: SwiftUI-based views for Onboarding, Live Tracking, Lists, and Maps.
