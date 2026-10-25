//
//  CameraView.swift
//  HUDViewUI
//
//  Created by Stuart Rankin on 10/24/26.
//

import UIKit
import AVFoundation

class CameraLiveView: UIView
{
    override class var layerClass: AnyClass
    {
        AVCaptureVideoPreviewLayer.self
    }
    
    var PreviewLayer: AVCaptureVideoPreviewLayer
    {
        layer as! AVCaptureVideoPreviewLayer
    }
}
