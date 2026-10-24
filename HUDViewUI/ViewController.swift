//
//  ViewController.swift
//  HUDViewUI
//
//  Created by Stuart Rankin on 10/24/26.
//

import UIKit
import AVFoundation
import Combine

class ViewController: UIViewController
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        InitializeCompassLabel()
        
        CompassHeading.text = ""
        LiveView.PreviewLayer.session = Session
        LiveView.PreviewLayer.videoGravity = .resizeAspectFill
        SelfieButton.changesSelectionAsPrimaryAction = true
        
        RequestCameraAccess()
        
        LM.RequestPermission()
        
        LM.$CurrentHeading
            .sink
        {
            [weak self] _ in
            guard let self else
            {
                return
            }
            if let Heading = self.LM.TrueHeading
            {
                self.CompassHeading.text = "\(Int(Heading.rounded()))°"
            }
        }
        .store(in: &Cancellables)
        
        LM.$AuthorizationStatus
            .removeDuplicates()
            .sink
        {
            [weak self] Status in
            guard self != nil else
            {
                return
            }
            print("Status=\(Status)")
        }
        .store(in: &Cancellables)
    }
    
    @IBAction func RadarButtonHandler(_ sender: Any)
    {
    }
    
    func InitializeCompassLabel()
    {
        CompassHeading.backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 0.0, alpha: 1.0)
        CompassHeading.layer.cornerRadius = 10
        CompassHeading.layer.cornerCurve = .continuous
        CompassHeading.clipsToBounds = true
    }

    // MARK: - Storyboard outlets.
    @IBOutlet weak var SelfieButton: UIBarButtonItem!
    @IBOutlet weak var RadarViewButton: UIBarButtonItem!
    @IBOutlet weak var CurrentLocationButton: UIBarButtonItem!
    @IBOutlet weak var CompassHeading: UILabel!
    @IBOutlet weak var LiveView: CameraLiveView!
    
    // MARK: - Locals
    let Session = AVCaptureSession()
    let SessionQueue = DispatchQueue(label: "HudViewUI")
    var CurrentInput: AVCaptureDeviceInput?
    
    // MARK: - Location manager
    var LM = LocationManager()
    
    // MARK: - Combine-required
    var Cancellables = Set<AnyCancellable>()
    
    // MARK: - Camera
    var InSelfieMode: Bool = false
    
    // MARK: - Toast
    var ToastPopup: Toast?
    var ToastSubscription: AnyCancellable?
}

