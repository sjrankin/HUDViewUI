//
//  ToastView.swift
//  HUDViewUI
//
//  Created by Stuart Rankin on 10/24/26.
//

import Foundation
import UIKit

class Toast: UIView
{
    /// Handles the user tap on the toast.
    var OnTap: (() -> Void)?
    let HeadingLabel = Toast.MakeLabel(IsBold: true)
    let PositionLabel = Toast.MakeLabel()
    let AltitudeLabel = Toast.MakeLabel()
    
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        CreateToast()
    }
    
    required init?(coder: NSCoder)
    {
        super.init(coder: coder)
        CreateToast()
    }
    
    func CreateToast()
    {
        backgroundColor = UIColor.black.withAlphaComponent(0.75)
        layer.cornerRadius = 16
        layer.cornerCurve = .continuous
        clipsToBounds = true
        
        let Stack = UIStackView(arrangedSubviews: [HeadingLabel, PositionLabel, AltitudeLabel])
        Stack.axis = .vertical
        Stack.spacing = 4
        Stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(Stack)
        NSLayoutConstraint.activate([
            Stack.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            Stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
            Stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
            Stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18)
                                    ])
    }
    
    func Update(Heading: Double?, Direction: String, Location: CLLocation?)
    {
        if let Heading
        {
            HeadingLabel.text = String(format: "%@ %.0f°", Direction, Heading)
        }
        else
        {
            HeadingLabel.text = "Heading unavailable"
        }
        if let Location
        {
            PositionLabel.text = String(format: "%.5f°, %.5f°", Location.coordinate.latitude, Location.coordinate.longitude)
            AltitudeLabel.text = String(format: "Altitude %.0f m   ±%.0f m", Location.altitude, Location.horizontalAccuracy)
        }
        else
        {
            PositionLabel.text = "No location"
            AltitudeLabel.text = ""
        }
    }
    
    @objc private func Tapped()
    {
        OnTap?()
    }
}

extension Toast
{
    static func MakeLabel(IsBold: Bool = false) -> UILabel
    {
        let Label = UILabel()
        Label.textColor = .white
        Label.textAlignment = .center
        Label.font = IsBold ? .systemFont(ofSize: 20, weight: .bold) :
                              .systemFont(ofSize: 20, weight: .regular)
        return Label
    }
}
