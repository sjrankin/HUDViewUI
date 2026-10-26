//
//  POIMarkerView.swift
//  HUDViewUI
//
//  Created by Stuart Rankin on 10/26/26.
//  Adapted from POIMarker in HUDView.
//

import Foundation
import UIKit

/// One point of interest on the camera view: a dot at the exact spot, with a label of the name and distance below it.
class POIMarkerView: UIView
{
    static let DotSize: CGFloat = 16
    
    init(_ Item: POIVisibilityService.VisiblePOI)
    {
        super.init(frame: .zero)
        let Color = RadarDisplayView.Color(Named: Item.poi.type.color)
        
        Dot.backgroundColor = Color
        Dot.layer.cornerRadius = POIMarkerView.DotSize / 2
        Dot.layer.borderColor = UIColor.white.cgColor
        Dot.layer.borderWidth = 2
        Dot.layer.shadowOpacity = 0.5
        Dot.layer.shadowRadius = 3
        Dot.layer.shadowOffset = .zero
        
        Card.layer.cornerRadius = 8
        Card.layer.cornerCurve = .continuous
        Card.layer.borderWidth = 1
        Card.layer.borderColor = Color.withAlphaComponent(0.65).cgColor
        Card.clipsToBounds = true
        
        let Icon = UIImageView(image: UIImage(systemName: Item.poi.type.icon))
        Icon.tintColor = Color
        Icon.contentMode = .scaleAspectFit
        
        let Name = UILabel()
        Name.text = Item.poi.name
        Name.font = .systemFont(ofSize: 12, weight: .bold)
        Name.textColor = .black
        
        let Distance = UILabel()
        Distance.text = Item.distanceFormatted
        Distance.font = .systemFont(ofSize: 11)
        Distance.textColor = UIColor.black.withAlphaComponent(0.8)
        
        let Stack = UIStackView(arrangedSubviews: [Icon, Name, Distance])
        Stack.axis = .vertical
        Stack.alignment = .center
        Stack.spacing = 3
        Stack.translatesAutoresizingMaskIntoConstraints = false
        Card.contentView.addSubview(Stack)
        NSLayoutConstraint.activate(
            [
                Stack.topAnchor.constraint(equalTo: Card.contentView.topAnchor, constant: 6),
                Stack.bottomAnchor.constraint(equalTo: Card.contentView.bottomAnchor, constant: -6),
                Stack.leadingAnchor.constraint(equalTo: Card.contentView.leadingAnchor, constant: 8),
                Stack.trailingAnchor.constraint(equalTo: Card.contentView.trailingAnchor, constant: -8)
            ])
        
        addSubview(Card)
        addSubview(Dot)
        
        let CardSize = Stack.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        let Width = max(CardSize.width + 16, POIMarkerView.DotSize)
        let Top = POIMarkerView.DotSize + 4
        Dot.frame = CGRect(x: (Width - POIMarkerView.DotSize) / 2, y: 0,
                           width: POIMarkerView.DotSize, height: POIMarkerView.DotSize)
        Card.frame = CGRect(x: (Width - (CardSize.width + 16)) / 2, y: Top, width: CardSize.width + 16,
                            height: CardSize.height + 12)
        bounds = CGRect(x: 0, y: 0, width: Width, height: Top + Card.frame.height)
        
        let Meters = Item.distance
        Opacity = Meters < 5000 ? 1.0 : (Meters < 20000 ? 0.9 : (Meters < 50000 ? 0.8 : 0.7))
        alpha = Opacity
    }
    
    required init?(coder: NSCoder)
    {
        fatalError("init(coder:) is not supported")
    }
    
    /// Puts the dot (not the whole marker) at `Point`.
    func Place(DotAt Point: CGPoint)
    {
        center = CGPoint(x: Point.x, y: Point.y - POIMarkerView.DotSize / 2 + bounds.height / 2)
    }
    
    private(set) var Opacity: CGFloat = 1.0
    private let Dot = UIView()
    private let Card = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialLight))
}
