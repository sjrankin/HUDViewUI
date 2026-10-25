//
//  ViewController_Location.swift
//  HUDViewUI
//
//  Created by Stuart Rankin on 10/24/26.
//

import Foundation
import UIKit
import Combine

extension ViewController
{
    @IBAction func LocationButtonHandler(_ sender: Any)
    {
        if ToastPopup == nil
        {
            ShowToast()
        }
        else
        {
            HideToast()
        }
        CurrentLocationButton.isSelected = ToastPopup != nil
    }
    
    func ShowToast()
    {
        let NewToast = Toast()
        NewToast.translatesAutoresizingMaskIntoConstraints = false
        NewToast.alpha = 0
        NewToast.OnTap = { [weak self] in self?.HideToast() }
        view.addSubview(NewToast)
        NSLayoutConstraint.activate(
            [
                NewToast.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                NewToast.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -70)   // above the toolbar; adjust to taste
            ])
        ToastPopup = NewToast
        
        ToastSubscription = Publishers.CombineLatest(LM.TrueHeadingPublisher, LM.$CurrentLocation)
            .sink
        {
            [weak self] Heading, Location in
            self?.ToastPopup?.Update(Heading: Heading, Direction: LocationManager.DirectionName(Heading), Location: Location)
        }
        
        UIView.animate(withDuration: 0.2)
        {
            NewToast.alpha = 1
        }
    }
    
    func HideToast()
    {
        ToastSubscription = nil
        guard let OldToast = ToastPopup else
        {
            return
        }
        ToastPopup = nil
        UIView.animate(withDuration: 0.2, animations: { OldToast.alpha = 0 })
        {
            _ in
            OldToast.removeFromSuperview()
        }
    }
}
