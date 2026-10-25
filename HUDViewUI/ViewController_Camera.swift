//
//  ViewController_Camera.swift
//  HUDViewUI
//
//  Created by Stuart Rankin on 10/24/26.
//

import Foundation
import UIKit
import AVFoundation

extension ViewController
{
    @IBAction func SelfieButtonHandler(_ sender: Any)
    {
        InSelfieMode.toggle()
        SelfieButton.isSelected = InSelfieMode
        let Position:AVCaptureDevice.Position = InSelfieMode ? .front : .back
        SessionQueue.async
        {
            self.UseCamera(Position)
        }
    }
    
    func UseCamera(_ Position: AVCaptureDevice.Position)
    {
        guard let Device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: Position),
              let NewInput = try? AVCaptureDeviceInput(device: Device) else
        {
            return
        }
        Session.beginConfiguration()
        if let Old = CurrentInput
        {
            Session.removeInput(Old)
        }
        if Session.canAddInput(NewInput)
        {
            Session.addInput(NewInput)
            CurrentInput = NewInput
        }
        else if let Old = CurrentInput
        {
            Session.addInput(Old)
        }
        Session.commitConfiguration()
        // The horizon's distance from the middle of the picture depends on this camera's field of view.
        let FieldOfView = Double(Device.activeFormat.videoFieldOfView)
        let IsFront = Position == .front
        DispatchQueue.main.async
        {
            self.Overlay?.FieldOfView = FieldOfView
            self.Overlay?.IsFrontCamera = IsFront
            self.Overlay?.setNeedsLayout()
            self.ApplyInterfaceOrientation()
        }
    }
    
    /// Tells the overlay and the camera preview which way the interface is turned. Call it whenever the layout changes (the screen
    /// rotating always does that) and when a camera has been chosen.
    func ApplyInterfaceOrientation()
    {
        let Orientation = view.window?.windowScene?.effectiveGeometry.interfaceOrientation ?? .portrait
        Overlay?.Orientation = Orientation
        // The picture has to be turned with the interface, or the camera shows sideways in landscape. The selfie camera's sensor
        // sits turned half a circle the other way round from the back camera's, so its two landscape angles are swapped.
        let IsFront = Overlay?.IsFrontCamera ?? false
        let Angle: CGFloat
        switch Orientation
        {
            case .landscapeRight:
                Angle = IsFront ? 180 : 0
                
            case .landscapeLeft:
                Angle = IsFront ? 0 : 180
                
            case .portraitUpsideDown:
                Angle = 270
                
            default:
                Angle = 90
        }
        if let Connection = LiveView.PreviewLayer.connection, Connection.isVideoRotationAngleSupported(Angle)
        {
            Connection.videoRotationAngle = Angle
        }
    }
    
    func RequestCameraAccess()
    {
        AVCaptureDevice.requestAccess(for: .video)
        {
            granted in
            guard granted else
            {
                return
            }
            self.SessionQueue.async
            {
                self.UseCamera(.back)
                self.Session.startRunning()
            }
        }
    }
}
