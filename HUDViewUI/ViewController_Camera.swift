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
