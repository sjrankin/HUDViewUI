//
//  ViewController_CompassBar.swift
//  HUDViewUI
//
//  Created by Stuart Rankin on 10/25/26.
//

import UIKit
import AVFoundation
import Combine

extension ViewController
{
    /// Initialize the location manger. Supplies the heading and current location.
    func InitializeLocation()
    {
        LM.RequestPermission()
        
        LM.$AuthorizationStatus
            .removeDuplicates()
            .sink
        {
            [weak self] Status in
            guard self != nil else
            {
                return
            }
        }
        .store(in: &Cancellables)
        
        LM.TrueHeadingPublisher
            .compactMap { $0 }
            .sink
        {
            [weak self] Heading in
            guard let self else
            {
                return
            }
            self.CompassBar.Heading = Heading
            self.Overlay?.SetHeading(Heading)
            self.CompassHeading.text = "\(Int(Heading.rounded()))°"
        }
        .store(in: &Cancellables)
        
        LM.$CurrentLocation
            .sink
        {
            [weak self] Location in
            self?.Overlay?.SetLocation(Location)
        }
        .store(in: &Cancellables)
    }
}
