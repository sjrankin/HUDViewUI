//
//  RadarDisplayView.swift
//  HUDViewUI
//
//  Created by Stuart Rankin on 10/25/26.
//  Adapted from RadarView in HUDView.
//

import Foundation
import UIKit

/// Draws the radar: range rings, the heading line, "N", the points of interest, and the pulse at the user's position.
/// Up on the radar is the way the phone is facing.
class RadarDisplayView: UIView
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
        contentMode = .redraw
        addGestureRecognizer(UIPinchGestureRecognizer(target: self, action: #selector(HandlePinch(_:))))
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(HandleTap(_:))))
        PulseLayer.fillColor = UIColor.systemBlue.withAlphaComponent(0.35).cgColor
        PulseLayer.opacity = 0
        layer.addSublayer(PulseLayer)
    }
    
    // MARK: - Public state
    
    /// The heading in degrees the phone is facing.
    var Heading: Double = 0.0
    {
        didSet
        {
            setNeedsDisplay()
        }
    }
    
    /// All points of interest to consider. Those beyond the current range are not drawn.
    var POIs: [POIVisibilityService.VisiblePOI] = []
    {
        didSet
        {
            setNeedsDisplay()
        }
    }
    
    /// The distance in meters at the outer ring when the zoom is 1.
    var BaseDistance: Double = 200_000.0
    {
        didSet
        {
            setNeedsDisplay()
        }
    }
    
    /// 0.25 shows four times the base distance, 8 shows one eighth of it.
    var Zoom: Double = 1.0
    {
        didSet
        {
            setNeedsDisplay()
            OnRangeChanged?()
        }
    }
    
    var EffectiveDistance: Double
    {
        BaseDistance / Zoom
    }
    
    /// The number of points of interest inside the current range.
    var VisibleCount: Int
    {
        POIs.filter { $0.distance <= EffectiveDistance }.count
    }
    
    var OnRangeChanged: (() -> Void)?
    var OnSelect: ((POIVisibilityService.VisiblePOI?) -> Void)?
    
    // MARK: - Geometry
    
    private let RingCount = 4
    private let MarkerRadius: CGFloat = 14
    private let PulseLayer = CAShapeLayer()
    private var MarkerPositions: [(Index: Int, Point: CGPoint)] = []
    
    private var RadarCenter: CGPoint
    {
        CGPoint(x: bounds.midX, y: bounds.midY)
    }
    
    private var RadarRadius: CGFloat
    {
        max(0, min(bounds.width, bounds.height) / 2.0 - 36)
    }
    
    override func layoutSubviews()
    {
        super.layoutSubviews()
        //A small layer centered on the user, scaled about its own center (the default anchor point).
        let Side = MarkerRadius * 4
        PulseLayer.bounds = CGRect(x: 0, y: 0, width: Side, height: Side)
        PulseLayer.position = RadarCenter
        PulseLayer.path = UIBezierPath(ovalIn: PulseLayer.bounds).cgPath
        StartPulse()
    }
    
    private func StartPulse()
    {
        PulseLayer.removeAllAnimations()
        let Scale = CABasicAnimation(keyPath: "transform.scale")
        Scale.fromValue = 0.5
        Scale.toValue = 1.6
        let Fade = CABasicAnimation(keyPath: "opacity")
        Fade.fromValue = 0.8
        Fade.toValue = 0.0
        let Group = CAAnimationGroup()
        Group.animations = [Scale, Fade]
        Group.duration = 2.0
        Group.repeatCount = .infinity
        PulseLayer.add(Group, forKey: "Pulse")
    }
    
    // MARK: - Drawing
    
    override func draw(_ rect: CGRect)
    {
        guard let Context = UIGraphicsGetCurrentContext(), RadarRadius > 0 else
        {
            return
        }
        let Center = RadarCenter
        let Radius = RadarRadius
        let Green = UIColor.systemGreen
        
        Context.setFillColor(Green.withAlphaComponent(0.06).cgColor)
        Context.fillEllipse(in: CGRect(x: Center.x - Radius, y: Center.y - Radius, width: Radius * 2, height: Radius * 2))
        
        DrawRings(Context, Center, Radius, Green)
        
        Context.setStrokeColor(Green.withAlphaComponent(0.2).cgColor)
        Context.setLineWidth(1)
        Context.move(to: CGPoint(x: Center.x, y: Center.y - Radius))
        Context.addLine(to: CGPoint(x: Center.x, y: Center.y + Radius))
        Context.move(to: CGPoint(x: Center.x - Radius, y: Center.y))
        Context.addLine(to: CGPoint(x: Center.x + Radius, y: Center.y))
        Context.strokePath()
        
        DrawNorth(Context, Center, Radius)
        DrawPOIs(Context, Center, Radius)
        
        Context.setFillColor(UIColor.systemBlue.cgColor)
        Context.setStrokeColor(UIColor.white.cgColor)
        Context.setLineWidth(2)
        let Dot = CGRect(x: Center.x - 8, y: Center.y - 8, width: 16, height: 16)
        Context.fillEllipse(in: Dot)
        Context.strokeEllipse(in: Dot)
    }
    
    private func DrawRings(_ Context: CGContext, _ Center: CGPoint, _ Radius: CGFloat, _ Green: UIColor)
    {
        let Attributes: [NSAttributedString.Key: Any] =
        [.font: UIFont.systemFont(ofSize: 15), .foregroundColor: Green.withAlphaComponent(0.6)]
        for Ring in 1 ... RingCount
        {
            let RingRadius = Radius * CGFloat(Ring) / CGFloat(RingCount)
            Context.setStrokeColor(Green.withAlphaComponent(0.3).cgColor)
            Context.setLineWidth(1)
            Context.strokeEllipse(in: CGRect(x: Center.x - RingRadius, y: Center.y - RingRadius,
                                             width: RingRadius * 2, height: RingRadius * 2))
            let Name = POIDistanceUnit.Current.Format(Meters: EffectiveDistance * Double(Ring) / Double(RingCount)) as NSString
            let Size = Name.size(withAttributes: Attributes)
            Name.draw(at: CGPoint(x: Center.x - Size.width / 2, y: Center.y - RingRadius - Size.height - 1),
                      withAttributes: Attributes)
        }
    }
    
    /// The yellow line points to north, with an "N" just outside the outer ring.
    private func DrawNorth(_ Context: CGContext, _ Center: CGPoint, _ Radius: CGFloat)
    {
        let Angle = -Heading * .pi / 180.0
        let EndPoint = CGPoint(x: Center.x + Radius * sin(Angle), y: Center.y - Radius * cos(Angle))
        Context.setStrokeColor(UIColor.systemYellow.withAlphaComponent(0.8).cgColor)
        Context.setLineWidth(2)
        Context.move(to: Center)
        Context.addLine(to: EndPoint)
        Context.strokePath()
        
        let Attributes: [NSAttributedString.Key: Any] =
        [.font: UIFont.systemFont(ofSize: 20, weight: .bold), .foregroundColor: UIColor.systemYellow]
        let Size = ("N" as NSString).size(withAttributes: Attributes)
        let LabelPoint = CGPoint(x: Center.x + (Radius + 20) * sin(Angle), y: Center.y - (Radius + 20) * cos(Angle))
        Context.saveGState()
        Context.translateBy(x: LabelPoint.x, y: LabelPoint.y)
        Context.rotate(by: Angle)
        ("N" as NSString).draw(at: CGPoint(x: -Size.width / 2, y: -Size.height / 2), withAttributes: Attributes)
        Context.restoreGState()
    }
    
    private func DrawPOIs(_ Context: CGContext, _ Center: CGPoint, _ Radius: CGFloat)
    {
        MarkerPositions.removeAll()
        //Farthest first so the nearest are drawn on top.
        let Sorted = POIs.enumerated().filter { $0.element.distance <= EffectiveDistance }
            .sorted { $0.element.distance > $1.element.distance }
        for (Index, Item) in Sorted
        {
            let Relative = (Item.bearing - Heading) * .pi / 180.0
            let Ratio = CGFloat(min(Item.distance / EffectiveDistance, 1.0))
            let Point = CGPoint(x: Center.x + Radius * Ratio * CGFloat(sin(Relative)),
                                y: Center.y - Radius * Ratio * CGFloat(cos(Relative)))
            MarkerPositions.append((Index, Point))
            let Color = RadarDisplayView.Color(Named: Item.poi.type.color)
            let Halo = CGRect(x: Point.x - MarkerRadius - 4, y: Point.y - MarkerRadius - 4,
                              width: (MarkerRadius + 4) * 2, height: (MarkerRadius + 4) * 2)
            Context.setFillColor(Color.withAlphaComponent(0.35).cgColor)
            Context.fillEllipse(in: Halo)
            Context.setFillColor(Color.cgColor)
            Context.fillEllipse(in: CGRect(x: Point.x - MarkerRadius, y: Point.y - MarkerRadius,
                                           width: MarkerRadius * 2, height: MarkerRadius * 2))
            if let Symbol = RadarDisplayView.Symbol(Named: Item.poi.type.icon)
            {
                let Side = MarkerRadius * 1.2
                Symbol.draw(in: CGRect(x: Point.x - Side / 2, y: Point.y - Side / 2, width: Side, height: Side))
            }
        }
    }
    
    // MARK: - Symbols and colors
    
    private static var SymbolCache: [String: UIImage] = [:]
    
    private static func Symbol(Named Name: String) -> UIImage?
    {
        if let Cached = SymbolCache[Name]
        {
            return Cached
        }
        let Image = UIImage(systemName: Name)?.withTintColor(.white, renderingMode: .alwaysOriginal)
        SymbolCache[Name] = Image
        return Image
    }
    
    static func Color(Named Name: String) -> UIColor
    {
        switch Name
        {
            case "orange": return .systemOrange
            case "brown": return .brown
            case "red": return .systemRed
            case "green": return .systemGreen
            case "blue": return .systemBlue
            case "purple": return .systemPurple
            default: return .systemGray
        }
    }
    
    // MARK: - Gestures
    
    @objc private func HandlePinch(_ Recognizer: UIPinchGestureRecognizer)
    {
        guard Recognizer.state == .changed || Recognizer.state == .ended else
        {
            return
        }
        Zoom = min(max(Zoom * Double(Recognizer.scale), 0.25), 8.0)
        Recognizer.scale = 1.0
    }
    
    @objc private func HandleTap(_ Recognizer: UITapGestureRecognizer)
    {
        let Location = Recognizer.location(in: self)
        //Test nearest-drawn (last in the list) first.
        let Hit = MarkerPositions.reversed().first
        {
            hypot($0.Point.x - Location.x, $0.Point.y - Location.y) <= MarkerRadius + 6
        }
        OnSelect?(Hit.map { POIs[$0.Index] })
    }
}
