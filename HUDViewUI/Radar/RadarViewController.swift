//
//  RadarViewController.swift
//  HUDViewUI
//
//  Created by Stuart Rankin on 10/25/26.
//  Adapted from RadarView in HUDView.
//

import UIKit
import Combine
import CoreLocation

/// Shows the radar of nearby points of interest. Present it inside a navigation controller.
class RadarViewController: UIViewController
{
    init(LocationSource: LocationManager)
    {
        LM = LocationSource
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder)
    {
        fatalError("init(coder:) is not supported")
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .dark
        view.backgroundColor = .black
        title = "Radar View"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self,
                                                            action: #selector(DoneTapped))
        navigationItem.rightBarButtonItem?.tintColor = .systemGreen
        
        Radar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(Radar)
        for Label in [HeadingLabel, RangeLabel, CountLabel, SelectionLabel]
        {
            Label.translatesAutoresizingMaskIntoConstraints = false
            Label.font = .monospacedDigitSystemFont(ofSize: 17, weight: .regular)
            Label.textColor = .systemGreen
            view.addSubview(Label)
        }
        SelectionLabel.textColor = .white
        SelectionLabel.textAlignment = .center
        SelectionLabel.numberOfLines = 2
        let Guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate(
            [
                HeadingLabel.topAnchor.constraint(equalTo: Guide.topAnchor, constant: 12),
                HeadingLabel.leadingAnchor.constraint(equalTo: Guide.leadingAnchor, constant: 20),
                RangeLabel.topAnchor.constraint(equalTo: HeadingLabel.bottomAnchor, constant: 4),
                RangeLabel.leadingAnchor.constraint(equalTo: HeadingLabel.leadingAnchor),
                CountLabel.topAnchor.constraint(equalTo: RangeLabel.bottomAnchor, constant: 4),
                CountLabel.leadingAnchor.constraint(equalTo: HeadingLabel.leadingAnchor),
                //The radar fills the whole safe area, so it keeps its size when the labels move in landscape.
                Radar.topAnchor.constraint(equalTo: Guide.topAnchor),
                Radar.leadingAnchor.constraint(equalTo: Guide.leadingAnchor),
                Radar.trailingAnchor.constraint(equalTo: Guide.trailingAnchor),
                Radar.bottomAnchor.constraint(equalTo: Guide.bottomAnchor),
                SelectionLabel.leadingAnchor.constraint(equalTo: Guide.leadingAnchor, constant: 20),
                SelectionLabel.trailingAnchor.constraint(equalTo: Guide.trailingAnchor, constant: -20),
                SelectionLabel.bottomAnchor.constraint(equalTo: Guide.bottomAnchor, constant: -16),
                SelectionLabel.heightAnchor.constraint(equalToConstant: 44)
            ])
        
        Radar.OnRangeChanged =
        {
            [weak self] in
            self?.UpdateLabels()
        }
        Radar.OnSelect =
        {
            [weak self] Selected in
            self?.ShowSelection(Selected)
        }
        
        LM.TrueHeadingPublisher
            .compactMap { $0 }
            .sink
        {
            [weak self] Heading in
            self?.DeviceHeading = Heading
            self?.ApplyHeading()
        }
        .store(in: &Cancellables)
        
        LM.$CurrentLocation
            .sink
        {
            [weak self] Location in
            self?.UpdatePOIs(Location)
        }
        .store(in: &Cancellables)
        
        DeviceHeading = LM.TrueHeading ?? 0
        ApplyHeading()
    }
    
    override func viewDidLayoutSubviews()
    {
        super.viewDidLayoutSubviews()
        //A rotation always lays the views out again, so the radar turns with it here.
        ApplyHeading()
    }
    
    /// The heading from the compass is the way the top of the phone points. The radar needs the way the phone is facing,
    /// which in landscape is a quarter turn from that.
    private func ApplyHeading()
    {
        let Orientation = view.window?.windowScene?.effectiveGeometry.interfaceOrientation ?? .portrait
        let Facing = LocationManager.FacingHeading(DeviceHeading, Orientation: Orientation)
        Radar.Heading = Facing
        UpdateLabels(Facing)
    }
    
    @objc private func DoneTapped()
    {
        dismiss(animated: true)
    }
    
    /// Every point of interest within the widest range (the minimum zoom shows four times the base distance).
    private func UpdatePOIs(_ Location: CLLocation?)
    {
        guard let Location else
        {
            Radar.POIs = []
            UpdateLabels()
            return
        }
        //Route waypoints are not shown on the radar.
        let Nearby = POIVisibilityService.nearestPOIs(from: Location.coordinate, maxDistance: Radar.BaseDistance * 4.0,
                                                      limit: 1000)
        Radar.POIs = Nearby.filter { $0.poi.type != .route }
        UpdateLabels()
    }
    
    private func UpdateLabels(_ Heading: Double? = nil)
    {
        let Value = Heading ?? Radar.Heading
        HeadingLabel.text = "Heading: \(Int(Value.rounded()))°"
        RangeLabel.text = "Range: \(POIDistanceUnit.Current.Format(Meters: Radar.EffectiveDistance))"
        CountLabel.text = "POIs: \(Radar.VisibleCount) of \(Radar.POIs.count)"
    }
    
    private func ShowSelection(_ Selected: POIVisibilityService.VisiblePOI?)
    {
        guard let Selected else
        {
            SelectionLabel.text = ""
            return
        }
        SelectionLabel.text = "\(Selected.poi.name)\n\(Selected.distanceFormatted) at \(Int(Selected.bearing.rounded()))°"
    }
    
    private let LM: LocationManager
    private var DeviceHeading: Double = 0.0
    private var Cancellables = Set<AnyCancellable>()
    private let Radar = RadarDisplayView()
    private let HeadingLabel = UILabel()
    private let RangeLabel = UILabel()
    private let CountLabel = UILabel()
    private let SelectionLabel = UILabel()
}
