//
//  MotionManager.swift
//  HUDViewUI
//
//  Created by Stuart Rankin on 10/25/26.
//

import Foundation
import CoreMotion
import Combine

@MainActor class MotionManager: ObservableObject
{
    let MM = CMMotionManager()
    @Published var Gravity = CMAcceleration(x: 0.0, y: -1.0, z: 0.0)
    
    var IsAvailable: Bool
    {
        MM.isDeviceMotionAvailable
    }
    
    static let ToDegrees  = 180.0 / .pi
    
    /// How much of each new reading is taken in (the rest is the old value): 1 is no smoothing. Used to
    /// reduce the natural shakiness of a hand-held phone.
    static let SmoothingWeight = 0.35
    
    /// A low-pass filter on the gravity vector, so the horizon does not tremble with the hand.
    static func Smoothed(Old: CMAcceleration, New: CMAcceleration) -> CMAcceleration
    {
        let Keep = 1.0 - SmoothingWeight
        return CMAcceleration(x: Old.x * Keep + New.x * SmoothingWeight,
                              y: Old.y * Keep + New.y * SmoothingWeight,
                              z: Old.z * Keep + New.z * SmoothingWeight)
    }
    
    func Start()
    {
        guard IsAvailable, !MM.isDeviceMotionActive else
        {
            return
        }
        // Update sixty times a second; `Smoothed` takes the shake out.
        MM.deviceMotionUpdateInterval = 1.0 / 60.0
        MM.startDeviceMotionUpdates(to: OperationQueue.main)
        {
            [weak self] (motion, error) in
            guard let self = self, let motion = motion else
            {
                return
            }
            self.Gravity = MotionManager.Smoothed(Old: self.Gravity, New: motion.gravity)
        }
    }
    
    func Stop()
    {
        MM.stopDeviceMotionUpdates()
    }
}
