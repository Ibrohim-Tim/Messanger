//
//  LocationPickerViewController.swift
//  Messanger
//
//  Created by Ibrahim Timurkaev on 24.09.2024.
//

import UIKit
import MapKit
import CoreLocation

protocol LocationPickerViewControllerDelegate: AnyObject {
    func locationDidSelect(location: CLLocation)
}

class LocationPickerViewController: UIViewController {
    
    enum Target {
        case send
        case show(CLLocation)
    }
    
    weak var delegate: LocationPickerViewControllerDelegate?
    
    private let target: Target
    
    private let manager = CLLocationManager()
    private var location: CLLocation?
        
    private let mapView: MKMapView = {
        let mapView = MKMapView()
        mapView.translatesAutoresizingMaskIntoConstraints = false
        return mapView
    }()
    
    init(target: Target) {
        self.target = target
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Местоположение"

        view.backgroundColor = .white
        
        switch target {
        case .send:
            setupSendButton()
        case .show:
            break
        }
        setupMapViewLayout()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        switch target {
        case .send:
            manager.requestWhenInUseAuthorization()
            manager.delegate = self
            manager.startUpdatingLocation()
        case .show(let cLLocation):
            displayLocation(cLLocation)
        }
    }
    
    private func setupSendButton() {
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                title: "Send",
                style: .plain,
                target: self,
                action: #selector(sendButtonTapped)
            )
    }
    
    private func setupMapViewLayout() {
        view.addSubview(mapView)
        
        mapView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).activate()
        mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor).activate()
        mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor).activate()
        mapView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).activate()
    }
    
    @objc
    private func sendButtonTapped() {
        guard let location = location else { return }
        
        delegate?.locationDidSelect(location: location)
        
        navigationController?.popViewController(animated: true)
    }
    
    private func displayLocation(_ location: CLLocation) {
        let span = MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        let region = MKCoordinateRegion(center: location.coordinate, span: span)
        
        mapView.setRegion(region, animated: true)
        
        let pin = MKPointAnnotation()
        pin.coordinate = location.coordinate
        
        mapView.addAnnotation(pin)
    }
}

extension LocationPickerViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            manager.stopUpdatingLocation()
            
            self.location = location
            
            displayLocation(location)
        }
    }
}
