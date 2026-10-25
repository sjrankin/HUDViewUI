//
//  LocationManager.swift
//  HUDViewUI
//
//  Created by Stuart Rankin on 10/24/26.
//

import Foundation
import CoreLocation
import Combine

@MainActor class LocationManager: NSObject, ObservableObject
{
    private let LM = CLLocationManager()
    
    @Published var AuthorizationStatus: CLAuthorizationStatus = .notDetermined
    var IsAuthorized: Bool
    {
        AuthorizationStatus == .authorizedWhenInUse || AuthorizationStatus == .authorizedAlways
    }
    
    @Published var CurrentLocation: CLLocation?
    @Published var CurrentHeading: CLHeading?
    
    /// The Simulator has no compass, so no heading ever arrives there and everything that needs one (the compass bar, the
    /// horizon line, the points of interest) stays hidden. In the Simulator only the device "points" to due north.
    static let SimulatorHeading: Double = 0
    
    /// The heading in degrees for `Heading`, true north if the phone has a fix and magnetic north if it does not. In the Simulator,
    /// which has no compass, it is `SimulatorHeading`. Nil when there is none.
    static func HeadingValue(_ Heading: CLHeading?) -> Double?
    {
        if let True = Heading?.trueHeading, True >= 0
        {
            return True
        }
        if let Magnetic = Heading?.magneticHeading
        {
            return Magnetic
        }
#if targetEnvironment(simulator)
        return SimulatorHeading
#else
        return nil
#endif
    }
    
    var TrueHeading: Double?
    {
        LocationManager.HeadingValue(CurrentHeading)
    }
    
    /// Publishes the heading each time it changes. Uses the value the publisher delivers, because `@Published` sends it
    /// before the property itself is updated.
    var TrueHeadingPublisher: AnyPublisher<Double?, Never>
    {
        $CurrentHeading
            .map { LocationManager.HeadingValue($0) }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
    
    var CompassDirection: String
    {
        guard let Heading = TrueHeading else
        {
            return "—"
        }
        return LocationManager.DirectionName(Heading)
    }
    
    static func DirectionName(_ Heading: Double?) -> String
    {
        guard let Heading else
        {
            return "?"
        }
        switch Heading
        {
            case 0..<22.5, 337.5...360:
                return "N"
            case 22.5..<67.5:
                return "NE"
            case 67.5..<112.5:
                return "E"
            case 112.5..<157.5:
                return "SE"
            case 157.5..<202.5:
                return "S"
            case 202.5..<247.5:
                return "SW"
            case 247.5..<292.5:
                return "W"
            case 292.5..<337.5:
                return "NW"
            default:
                return "—"
        }
    }
    
    override init()
    {
        super.init()
        LM.delegate = self
        LM.desiredAccuracy = kCLLocationAccuracyBest
        LM.headingFilter = 1 // Update every 1 degree change
        AuthorizationStatus = LM.authorizationStatus
    }
    
    /// Request location permission
    func RequestPermission()
    {
        LM.requestWhenInUseAuthorization()
    }
    
    /// Start updating location and heading
    func StartUpdating()
    {
        guard IsAuthorized else { return }
        LM.startUpdatingLocation()
        if CLLocationManager.headingAvailable()
        {
            LM.startUpdatingHeading()
        }
    }
    
    /// Stop updating location and heading
    func StopUpdating()
    {
        LM.stopUpdatingLocation()
        LM.stopUpdatingHeading()
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate
{
    nonisolated func locationManager(_ manager: CLLocationManager,
                                     didUpdateLocations locations: [CLLocation])
    {
        guard let location = locations.last else
        {
            return
        }
        Task
        {
            @MainActor in
            self.CurrentLocation = location
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager,
                                     didUpdateHeading newHeading: CLHeading)
    {
        Task
        {
            @MainActor in
            self.CurrentHeading = newHeading
        }
    }
    
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager)
    {
        Task
        {
            @MainActor in
            self.AuthorizationStatus = manager.authorizationStatus
            if self.IsAuthorized
            {
                self.StartUpdating()
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error)
    {
        print("Location manager error: \(error.localizedDescription)")
    }
}
