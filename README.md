# ClosedBikeSensor — Passing Distance Measurement for Cyclists

iOS-App zur Messung von Überholabständen beim Radfahren via iPhone LiDAR.  
Funktional inspiriert vom [OpenBikeSensor](https://www.openbikesensor.org/)-Projekt — ohne zusätzliche Hardware.

---

## 📱 Überblick

Das iPhone wird mit einem 3D-gedruckten Spiegelaufsatz links am Lenker montiert. Der Aufsatz lenkt den LiDAR-Strahl und die Kamera um 90° nach links um — so können Überholabstände gemessen werden, während das Display nach vorne zeigt und bedienbar bleibt.

### ✨ Features

- **LiDAR-Präzision** — ARKit verarbeitet Tiefendaten in Echtzeit (optimaler Bereich: 0,5 m – 5 m)
- **Physischer Auslöser** — Lautstärke-hoch-Taste als taktiler Shutter beim Fahren, alternativ Tipp auf den Bildschirm
- **Privacy First** — alle Daten (GPS, Fotos, Messungen) werden lokal via SwiftData gespeichert. Keine Cloud, keine Werbung
- **Farbkodierung** — Rot (≤ 1,0 m), Gelb (≤ 1,5 m), Grün (> 1,5 m)
- **Kartenansicht** — alle Messpunkte farbkodiert auf interaktiver Karte, filterbar nach Session
- **Session-Verwaltung** — mehrere Fahrten getrennt verwalten, benennen und analysieren

---

## 📋 Voraussetzungen

- iPhone 12 Pro oder neuer (LiDAR-Sensor erforderlich)
- iOS 26.0 oder neuer
- Kamera- und Standortberechtigung
- Linke Lenkerhalterung
- 3D-gedruckter Spiegelaufsatz (STL-Dateien im Repo, in Arbeit)

---

## 🚀 Verwendung

### 1. Hardware-Setup
iPhone links am Lenker montieren. Der Spiegelaufsatz muss Kamera und LiDAR um 90° nach links umlenken.

### 2. Erster Start
Kamera- und Standortberechtigung erteilen (geführter Onboarding-Flow).

### 3. Messen
Im **Live**-Tab Lautstärketaste drücken, wenn ein Auto überholt. Das Fadenkreuz zeigt den Messbereich — im Bearbeitungsmodus (oben rechts) anpassbar.

### 4. Auswertung

| Tab | Inhalt |
|-----|--------|
| **Sessions** | Statistiken, Charts und Einzelmessungen pro Fahrt |
| **Karte** | Alle Messpunkte auf interaktiver Karte, nach Session filterbar |

---

## 🏗️ Technologie-Stack

|                  |                                      |
|------------------|--------------------------------------|
| **Plattform**    | iOS 26+, Swift                       |
| **UI**           | SwiftUI                              |
| **AR / Depth**   | ARKit (LiDAR, `sceneDepth`)          |
| **Datenbank**    | SwiftData                            |
| **Karte**        | MapKit                               |
| **Standort**     | CoreLocation                         |

---

## 📁 Projektstruktur

```
ClosedBikeSensor/
├── Models/
│   ├── MeasurePoint.swift          # Einzelne Messung (Distanz, GPS, Foto, Datum)
│   └── MeasureSession.swift        # Fahrt-Session mit Statistiken (min/max/avg/median)
├── Logic/
│   ├── DistanceRetrieval.swift     # ARKit-Tiefenverarbeitung, ROI-Filterung, Glättung
│   ├── CaptureManager.swift        # Session-Lifecycle, GPS, Foto-Komprimierung, SwiftData
│   ├── RetrievalConfig.swift       # Singleton: App-State, Berechtigungen, Konfiguration
│   └── LocationPermissionManager.swift
├── Views/
│   ├── ContentView.swift           # Root: Onboarding oder Haupt-App
│   ├── MainTabView.swift           # Tab-Navigation (Live / Sessions / Karte)
│   ├── LiveCaptureView.swift       # AR-Kameravorschau, Distanzanzeige, Capture-Button
│   ├── SessionSelectorView.swift   # Horizontaler Session-Picker mit Erstellen/Bearbeiten
│   ├── MapView.swift               # Interaktive Karte mit farbkodierten Messpunkten
│   ├── OnboardingView.swift        # 3-schrittiger Onboarding-Flow
│   └── PermissionCard.swift        # Wiederverwendbare Berechtigungskarte
└── ClosedBikeSensorApp.swift       # App-Einstiegspunkt, SwiftData ModelContainer
```

---

## ⚙️ Technische Details

### Tiefenverarbeitung

Ein Hintergrund-Queue sampelt und glättet LiDAR-Tiefendaten im konfigurierbaren ROI (Region of Interest) um das Fadenkreuz. Confidence-basiertes Filtering verwirft unsichere Pixel; ein temporaler Glättungspuffer (konfigurierbare Größe) reduziert Jitter.

### Datenspeicherung

Fotos werden auf max. 1024 px (längste Seite) skaliert und als JPEG (70 %) komprimiert, zusammen mit GPS-Koordinaten via SwiftData gespeichert.

### Genauigkeit

Optimiert für matte Oberflächen. Die Fadenkreuz-Offset-Kalibrierung gleicht Montageungenauigkeiten aus — einstellbar über zwei Slider im Bearbeitungsmodus.

---

## 🗺️ Projektstatus

Studentisches Nebenprojekt zum Erlernen von iOS-Entwicklung. KI-Unterstützung wurde gezielt für ARKit/LiDAR-Kommunikation und Boilerplate-Logik eingesetzt. Die App ist funktionsfähig und für ihren Zweck zuverlässig — aber ein laufendes Projekt.

### Ideen für die Zukunft

- CSV/GPX-Export für externe Analyse
- Datenaustausch mit der OpenBikeSensor-Community
- Automatische Auslösung via CoreML
