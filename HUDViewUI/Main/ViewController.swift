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
        InitializeCompassBar()
        InitializeMotion()
        InitializeLocation()
        
        CompassHeading.text = "Hi!"
        LiveView.PreviewLayer.session = Session
        LiveView.PreviewLayer.videoGravity = .resizeAspectFill
        SelfieButton.changesSelectionAsPrimaryAction = true
        
        RequestCameraAccess()

        let Actual = MainOverlay(frame: .zero)
        Actual.translatesAutoresizingMaskIntoConstraints = false
        LiveView.addSubview(Actual)
        //Actual.DrawHorizon(Pitch: 0.0, Yaw: 0.0)
        Actual.DrawHorizon(CMAcceleration())
        NSLayoutConstraint.activate(
            [
                Actual.topAnchor.constraint(equalTo: LiveView.topAnchor),
                Actual.bottomAnchor.constraint(equalTo: LiveView.bottomAnchor),
                Actual.leadingAnchor.constraint(equalTo: LiveView.leadingAnchor),
                Actual.trailingAnchor.constraint(equalTo: LiveView.trailingAnchor)
            ]
        )
        Overlay = Actual
    }
    
    override func viewDidLayoutSubviews()
    {
        super.viewDidLayoutSubviews()
        // A rotation of the screen always lays the views out again, so this is where the horizon and the camera follow it.
        ApplyInterfaceOrientation()
    }
    
    /// Initialize the motion manager. Supplies pitch, roll, and yaw.
    func InitializeMotion()
    {
        Motion.Start()
        Motion.$Gravity
            .sink
        {
            // @Published sends the new value before the property holds it, so use `NewGravity`, not `self.Motion.Gravity`.
            [weak self] NewGravity in
            guard let self else
            {
                return
            }
            self.Gravity = NewGravity
            self.Overlay?.DrawHorizon(NewGravity)
        }
        .store(in: &Cancellables)
    }
    
    @IBAction func RadarButtonHandler(_ sender: Any)
    {
    }
    
    @IBAction func HorizonLockHandler(_ sender: Any)
    {
        HorizonIsLocked.toggle()
        HorizonLockButton.isSelected = HorizonIsLocked
        Overlay?.SetHorizonLock(to: HorizonIsLocked)
    }
    
    func InitializeCompassLabel()
    {
        CompassHeading.backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 0.0, alpha: 1.0)
        CompassHeading.layer.cornerRadius = 10
        CompassHeading.layer.cornerCurve = .continuous
        CompassHeading.clipsToBounds = true
    }
    
    func InitializeCompassBar()
    {
        //The bar itself (the full-width black view), not the heading label's narrow container.
        let Bar: UIView = CompassBarControl
        Bar.insertSubview(CompassBar, at: 0)
        CompassBar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate(
            [
                CompassBar.topAnchor.constraint(equalTo: Bar.topAnchor),
                CompassBar.bottomAnchor.constraint(equalTo: Bar.bottomAnchor),
                CompassBar.leadingAnchor.constraint(equalTo: Bar.leadingAnchor),
                CompassBar.trailingAnchor.constraint(equalTo: Bar.trailingAnchor)
            ])
    }
    
    // MARK: - Storyboard outlets.
    @IBOutlet weak var SelfieButton: UIBarButtonItem!
    @IBOutlet weak var RadarViewButton: UIBarButtonItem!
    @IBOutlet weak var HorizonLockButton: UIBarButtonItem!
    @IBOutlet weak var CurrentLocationButton: UIBarButtonItem!
    @IBOutlet weak var CompassHeading: UILabel!
    @IBOutlet weak var LiveView: CameraLiveView!
    @IBOutlet weak var CompassBarControl: UIView!
    
    // MARK: - Live View
    let Session = AVCaptureSession()
    let SessionQueue = DispatchQueue(label: "HudViewUI")
    var CurrentInput: AVCaptureDeviceInput?
    var Overlay: MainOverlay?
    var CompassBar = CompassBarView()
    
    // MARK: - Location manager
    var LM = LocationManager()

    // MARK: - Horizon lock
    var HorizonIsLocked = false
    
    // MARK: - Motion manager
    var Motion = MotionManager()
    var Gravity = CMAcceleration()
    
    // MARK: - Combine-required
    var Cancellables = Set<AnyCancellable>()
    
    // MARK: - Camera
    var InSelfieMode: Bool = false
    
    // MARK: - Toast
    var ToastPopup: Toast?
    var ToastSubscription: AnyCancellable?
}

