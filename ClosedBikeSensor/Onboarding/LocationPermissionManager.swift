//
//  LocationPermissionManager.swift
//  ClosedBikeSensor
//
//  Created by Martin Reisinger on 30.09.25.
//
//  Manages location permission requests and status updates. Integrates with RetrievalConfig
//  to update app-wide location authorization state.
//

import Combine
import CoreLocation

class LocationPermissionManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private let config = RetrievalConfig.shared
    
    override init() {
        super.init()
        locationManager.delegate = self
    }
    
    func checkStatus() {
        let status = locationManager.authorizationStatus
        Task { @MainActor in
            config.isLocationAuthorized = (status == .authorizedWhenInUse || status == .authorizedAlways)
        }
    }
    
    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            config.isLocationAuthorized = (status == .authorizedWhenInUse || status == .authorizedAlways)
        }
    }
}
