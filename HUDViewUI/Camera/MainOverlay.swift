//
//  MainOverlay.swift
//  HUDViewUI
//
//  Created by Stuart Rankin on 10/25/26.
//

import Foundation
import UIKit
import Combine
import CoreMotion
import CoreLocation

class MainOverlay: UIView
{
    var LastGravity = CMAcceleration()
    var LockedHorizon = false
    
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        CreateOverlay()
    }
    
    required init?(coder: NSCoder)
    {
        super.init(coder: coder)
        CreateOverlay()
    }
    
    func CreateOverlay()
    {
        backgroundColor = UIColor.clear
        clipsToBounds = true
        HorizonLine.strokeColor = UIColor.systemRed.withAlphaComponent(0.85).cgColor
        HorizonLine.lineWidth = 4.0
        layer.addSublayer(HorizonLine)
        addSubview(POIMarkers)
    }
    
    override func layoutSubviews()
    {
        super.layoutSubviews()
        POIMarkers.frame = bounds
        DrawHorizon(LastGravity)
    }
    
    let HorizonLine = CAShapeLayer()
    let POIMarkers = POIOverlayView()
    
    /// The compass heading (the way the top of the phone points) and the user's height above sea level.
    private var DeviceHeading: Double = 0.0
    private var UserHeight: Double = 0.0
    
    func SetHeading(_ NewHeading: Double)
    {
        DeviceHeading = NewHeading
        DrawHorizon(LastGravity)
    }
    
    func SetLocation(_ Location: CLLocation?)
    {
        guard let Location else
        {
            POIMarkers.SetPOIs([])
            return
        }
        UserHeight = Location.altitude
        //Route waypoints are not shown on the camera view.
        let Nearby = POIVisibilityService.nearestPOIs(from: Location.coordinate,
                                                      maxDistance: 12742 * 1000, //diameter of the earth in meters
                                                      limit: 500)
        POIMarkers.SetPOIs(Nearby.filter { $0.poi.type != .route })
        DrawHorizon(LastGravity)
    }
    
    /// The camera's field of view, in degrees, along the long side of its picture (the preview's vertical side in portrait). The
    /// view controller sets this when a camera is chosen; the horizon's distance from the middle of the view depends on it.
    var FieldOfView: Double = 63.0
    /// True for the selfie camera, which looks out of the screen's side of the phone, so its elevation has the opposite sign.
    var IsFrontCamera: Bool = false
    
    /// Where the horizon is in this view for a phone held in portrait: the middle of the line and how far it is tilted (radians,
    /// clockwise on screen). Returns nil when the phone is nearly flat, where the horizon is out of sight.
    ///
    /// The camera's elevation above the horizon is the sine-inverse of gravity's component along the camera's axis, and the horizon
    /// is that far (in focal lengths) from the middle of the picture, on the side gravity points to on the screen.
    func HorizonPose(_ Gravity: CMAcceleration) -> (Center: CGPoint, Angle: CGFloat, Pitch: Double)?
    {
        guard bounds.width > 0, bounds.height > 0 else
        {
            return nil
        }
        if LockedHorizon
        {
            return (CGPoint(x: bounds.midX, y: bounds.midY), 0.0, 0.0)
        }
        // Gravity's direction on the screen (screen y points down), as a unit vector. Gravity comes in the phone's own
        // axes; `Screen` turns it into the screen's axes, which are different once the interface has turned to landscape.
        let Screen = ScreenComponents(Gravity)
        let OnScreen = CGPoint(x: Screen.Right, y: -Screen.Up)
        let Length = hypot(OnScreen.x, OnScreen.y)
        guard Length > 0.15, bounds.width > 0, bounds.height > 0 else
        {
            return nil
        }
        let Direction = CGPoint(x: OnScreen.x / Length, y: OnScreen.y / Length)
        
        let Along = IsFrontCamera ? -Gravity.z : Gravity.z
        let Elevation = asin(max(-1.0, min(1.0, Along)))
        
        // tan() grows without limit looking straight up or down: keep the line a finite distance away.
        let Offset = max(-3000.0, min(3000.0, FocalPoints * tan(Elevation)))
        
        let Center = CGPoint(x: bounds.width / 2.0 + Direction.x * Offset,
                             y: bounds.height / 2.0 + Direction.y * Offset)
        return (Center, CGFloat(atan2(-Screen.Right, -Screen.Up)), Elevation)
    }
    
    /// The camera's focal length in points. The video fills the view and is 3:4 in portrait (4:3 in landscape), so its long
    /// side, in points, is:
    var FocalPoints: CGFloat
    {
        let LongSide = Orientation.isLandscape ? max(bounds.width, bounds.height * 4.0 / 3.0)
                                               : max(bounds.height, bounds.width * 4.0 / 3.0)
        return LongSide / (2.0 * tan(FieldOfView * .pi / 180.0 / 2.0))
    }
    
    /// The way the interface is turned (set by the view controller whenever the screen rotates). The phone's own axes never
    /// change, but which of them points to the right and to the top of the screen does.
    var Orientation: UIInterfaceOrientation = .portrait
    {
        didSet
        {
            if Orientation != oldValue
            {
                setNeedsLayout()      // `layoutSubviews` draws the horizon again for the new orientation
            }
        }
    }
    
    /// Gravity's components along the screen's right and up directions. (For the interface in landscape, the screen's "up" is
    /// along the phone's own X axis, one way or the other, and its "right" is along Y.)
    func ScreenComponents(_ Gravity: CMAcceleration) -> (Right: Double, Up: Double)
    {
        switch Orientation
        {
            case .landscapeRight:
                // Home indicator on the right: the phone's top points left, its right edge points up.
                return (-Gravity.y, Gravity.x)
                
            case .landscapeLeft:
                // Home indicator on the left: the phone's top points right, its right edge points down.
                return (Gravity.y, -Gravity.x)
                
            case .portraitUpsideDown:
                return (-Gravity.x, -Gravity.y)
                
            default:
                return (Gravity.x, Gravity.y)
        }
    }
    
    func SetHorizonLock(to IsLocked: Bool)
    {
        if LockedHorizon != IsLocked
        {
            LockedHorizon = IsLocked
        }
    }
    
    /// Moves the horizon line to where it belongs for the phone's current gravity vector.
    func DrawHorizon(_ Gravity: CMAcceleration)
    {
        LastGravity = Gravity
        guard let Pose = HorizonPose(Gravity) else
        {
            HorizonLine.isHidden = true
            POIMarkers.Clear()
            return
        }
        HorizonLine.isHidden = false
        //The points of interest hang off the same pose; the selfie camera looks the other way, so none are shown for it.
        if IsFrontCamera
        {
            POIMarkers.Clear()
        }
        else
        {
            POIMarkers.Update(Facing: LocationManager.FacingHeading(DeviceHeading, Orientation: Orientation),
                              UserHeight: UserHeight, Pose: Pose, Focal: FocalPoints, OnHorizon: LockedHorizon)
        }
        // A line longer than the view can ever show, centered on the layer's own position, so its ends are never seen.
        let Reach = hypot(bounds.width, bounds.height)
        let Path = UIBezierPath()
        Path.move(to: CGPoint(x: -Reach, y: 0))
        Path.addLine(to: CGPoint(x: Reach, y: 0))
        HorizonLine.path = Path.cgPath
        // No implicit animation: the line should follow the phone, not glide behind it.
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        HorizonLine.position = Pose.Center
        HorizonLine.transform = CATransform3DMakeRotation(Pose.Angle, 0, 0, 1)
        CATransaction.commit()
    }
}
