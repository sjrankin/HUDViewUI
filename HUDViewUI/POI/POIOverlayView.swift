//
//  POIOverlayView.swift
//  HUDViewUI
//
//  Created by Stuart Rankin on 10/26/26.
//  Adapted from POIOverlayView in HUDView.
//

import Foundation
import UIKit
import CoreLocation

/// Draws the points of interest over the camera so that they slide in and out of view as the phone turns.
///
/// Each point is projected through the same pinhole camera the horizon line uses: its direction (bearing relative to the way
/// the phone faces, and elevation angle relative to the level horizon) is turned into the camera's axes using the phone's
/// pitch, then rolled with the horizon. So a point at the same height as you sits just below the line, and the farther away
/// it is, the lower the curve of the Earth drops it.
class POIOverlayView: UIView
{
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        backgroundColor = .clear
    }
    
    required init?(coder: NSCoder)
    {
        super.init(coder: coder)
        isUserInteractionEnabled = false
        backgroundColor = .clear
    }
    
    /// The most markers shown at once, nearest first.
    static let MaxMarkers = 10
    static let EarthRadius: Double = 6_371_000
    
    /// Points of interest to consider, with distance and bearing from the user's location.
    func SetPOIs(_ NewPOIs: [POIVisibilityService.VisiblePOI])
    {
        POIs = NewPOIs
        for (_, Marker) in Markers
        {
            Marker.removeFromSuperview()
        }
        Markers.removeAll()
    }
    
    /// The angle in degrees above the level (positive) or below it (negative) at which a point `Distance` meters away is seen.
    /// The Earth's surface curves away, so a point at your own height ends up below the level by `Distance² / (2R)`.
    static func ElevationAngle(PointHeight: Double, UserHeight: Double, Distance: Double) -> Double
    {
        let Drop = (Distance * Distance) / (2.0 * EarthRadius)
        return atan2(PointHeight - UserHeight - Drop, Distance) * 180.0 / .pi
    }
    
    /// Where a direction falls in the view, or nil if it is behind the camera.
    /// - Parameters:
    ///   - Relative: Degrees the direction is to the right of the way the phone faces.
    ///   - Elevation: Degrees above the level horizon.
    ///   - Pose: The horizon's center, roll and the camera's pitch.
    ///   - Focal: The camera's focal length in points.
    func Project(Relative: Double, Elevation: Double, Pose: (Center: CGPoint, Angle: CGFloat, Pitch: Double),
                 Focal: CGFloat) -> CGPoint?
    {
        let Azimuth = Relative * .pi / 180.0
        let Rise = Elevation * .pi / 180.0
        let DX = sin(Azimuth) * cos(Rise)
        let DY = cos(Azimuth) * cos(Rise)
        let DZ = sin(Rise)
        // The camera looks `Pitch` above the level: its forward axis is (0, cos, sin) and its up axis is (0, -sin, cos).
        let Forward = DY * cos(Pose.Pitch) + DZ * sin(Pose.Pitch)
        guard Forward > 0.05 else
        {
            return nil
        }
        let Up = -DY * sin(Pose.Pitch) + DZ * cos(Pose.Pitch)
        let SX = Focal * CGFloat(DX / Forward)
        let SY = -Focal * CGFloat(Up / Forward)
        // The horizon is rolled about the middle of the view, and everything rolls with it.
        let Middle = CGPoint(x: bounds.midX, y: bounds.midY)
        return CGPoint(x: Middle.x + SX * cos(Pose.Angle) - SY * sin(Pose.Angle),
                       y: Middle.y + SX * sin(Pose.Angle) + SY * cos(Pose.Angle))
    }
    
    /// Moves every marker to where it belongs; call it whenever the heading or the phone's attitude changes.
    /// With `OnHorizon` (the horizon is locked) every point sits on the horizon line, whatever its height or distance.
    func Update(Facing: Double, UserHeight: Double, Pose: (Center: CGPoint, Angle: CGFloat, Pitch: Double),
                Focal: CGFloat, OnHorizon: Bool = false)
    {
        let Margin: CGFloat = 60
        let Allowed = bounds.insetBy(dx: -Margin, dy: -Margin)
        var Shown: [(Item: POIVisibilityService.VisiblePOI, Point: CGPoint)] = []
        for Item in POIs
        {
            var Relative = Item.bearing - Facing
            while Relative > 180.0
            {
                Relative -= 360.0
            }
            while Relative < -180.0
            {
                Relative += 360.0
            }
            let Elevation = OnHorizon ? 0.0
                : POIOverlayView.ElevationAngle(PointHeight: Item.poi.elevation ?? 0.0, UserHeight: UserHeight,
                                                Distance: Item.distance)
            if let Point = Project(Relative: Relative, Elevation: Elevation, Pose: Pose, Focal: Focal),
               Allowed.contains(Point)
            {
                Shown.append((Item, Point))
            }
        }
        let Nearest = Shown.sorted { $0.Item.distance < $1.Item.distance }.prefix(POIOverlayView.MaxMarkers)
        let Keep = Set(Nearest.map { $0.Item.poi.id })
        for (ID, Marker) in Markers where !Keep.contains(ID)
        {
            Marker.removeFromSuperview()
            Markers[ID] = nil
        }
        for Entry in Nearest
        {
            let ID = Entry.Item.poi.id
            let Marker: POIMarkerView
            if let Existing = Markers[ID]
            {
                Marker = Existing
            }
            else
            {
                Marker = POIMarkerView(Entry.Item)
                Markers[ID] = Marker
                addSubview(Marker)
            }
            Marker.Place(DotAt: Entry.Point)
            //Nearest on top.
            Marker.layer.zPosition = CGFloat(-Entry.Item.distance)
        }
    }
    
    /// Takes every marker off the screen, for when the horizon (and so the plot) is out of sight.
    func Clear()
    {
        for (_, Marker) in Markers
        {
            Marker.removeFromSuperview()
        }
        Markers.removeAll()
    }
    
    private var POIs: [POIVisibilityService.VisiblePOI] = []
    private var Markers: [UUID: POIMarkerView] = [:]
}
