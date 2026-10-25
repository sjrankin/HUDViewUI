//
//  CompassBarView.swift
//  HUDViewUI
//
//  Created by Stuart Rankin on 10/25/26.
//

import Foundation
import UIKit

class CompassBarView: UIView
{
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        Setup()
    }
    
    required init?(coder: NSCoder)
    {
        super.init(coder: coder)
        Setup()
    }
    
    func Setup()
    {
        backgroundColor = .clear
        isOpaque = false
        isUserInteractionEnabled = false
        contentMode = .redraw
    }
    
    override func draw(_ rect: CGRect)
    {
        guard let Context = UIGraphicsGetCurrentContext(), FieldOfView > 0, bounds.width > 0 else
        {
            return
        }
        let PerDegree = bounds.width / FieldOfView
        let CenterX = bounds.midX
        let HalfWidth = bounds.width / 2.0
        let Bottom = bounds.maxY
        
        for (Bearing, Name) in CompassBarView.Directions
        {
            let BearingValue = Bearing
            //Angular difference between the marker and the heading, normalized to [-180, 180].
            var Diff = BearingValue - Heading
            while Diff > 180.0
            {
                Diff -= 360.0
            }
            while Diff < -180.0
            {
                Diff += 360.0
            }
            let Offset = CGFloat(Diff) * PerDegree
            if abs(Offset) > HalfWidth
            {
                continue
            }
            let X = CenterX + Offset
            let IsCardinal = Bearing.truncatingRemainder(dividingBy: 90.0) == 0.0
            let Distance = abs(Offset)
            let Alpha: CGFloat = Distance < HalfWidth * 0.7 ? 1.0 : (Distance < HalfWidth ? 0.7 : 0.3)
            let Color = UIColor.white.withAlphaComponent(Alpha)
            let TickHeight: CGFloat = IsCardinal ? 15 : 10
            
            let Attributes: [NSAttributedString.Key: Any] =
            [.font: UIFont.systemFont(ofSize: IsCardinal ? 20 : 15, weight: IsCardinal ? .bold : .regular),
             .foregroundColor: Color]
            let Size = (Name as NSString).size(withAttributes: Attributes)
            let TextY = Bottom - Size.height
            (Name as NSString).draw(at: CGPoint(x: X - Size.width / 2.0, y: TextY), withAttributes: Attributes)
            
            Context.setStrokeColor(Color.cgColor)
            Context.setLineWidth(2)
            Context.move(to: CGPoint(x: X, y: TextY - 4))
            Context.addLine(to: CGPoint(x: X, y: TextY - 4 - TickHeight))
            Context.strokePath()
        }
        
        Context.setStrokeColor(UIColor.systemRed.cgColor)
        Context.setLineWidth(3)
        Context.move(to: CGPoint(x: CenterX, y: Bottom))
        Context.addLine(to: CGPoint(x: CenterX, y: Bottom - 24))
        Context.strokePath()
    }
    
    var Heading: Double = 0.0
    {
        didSet
        {
            setNeedsDisplay()
        }
    }
    
    var FieldOfView: Double = 180.0
    {
        didSet
        {
            setNeedsDisplay()
        }
    }
    
    /// The 16 compass points, keyed by bearing in degrees.
    static let Directions: [Double: String] =
    [0.0: "N", 22.5: "NNE", 45.0: "NE", 67.5: "ENE", 90.0: "E", 112.5: "ESE", 135.0: "SE", 157.5: "SSE",
     180.0: "S", 202.5: "SSW", 225.0: "SW", 247.5: "WSW", 270.0: "W", 292.5: "WNW", 315.0: "NW", 337.5: "NNW"]
}
