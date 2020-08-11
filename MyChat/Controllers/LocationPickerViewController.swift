//
//  LocationPickerViewController.swift
//  MyChat
//
//  Created by Aditya Ambekar on 09/08/20.
//  Copyright © 2020 Radioactive Apps. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit

final class LocationPickerViewController: UIViewController {

    public var completion: ((CLLocationCoordinate2D) -> Void)?
    private var coordinates: CLLocationCoordinate2D?
    private var isPickable = true
    
    private var map: MKMapView = {
        
        let map = MKMapView()
        
        return map
    }()
    
    init(coordinates: CLLocationCoordinate2D?) {
        
        self.coordinates = coordinates
        self.isPickable =  (coordinates == nil)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        map.isUserInteractionEnabled = true
        
        if isPickable {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Send",
                                                                style: .done,
                                                                target: self,
                                                                action: #selector(sendButtonPressed))
            let gesture = UITapGestureRecognizer(target: self,
                                              action: #selector(didPressedMap(_:) ))
            gesture.numberOfTouchesRequired = 1
            gesture.numberOfTapsRequired = 1
            map.addGestureRecognizer(gesture)
        }
        else {
            //show loc
            guard let coordinates = self.coordinates else {
                return
            }
            
            let pin = MKPointAnnotation()
            pin.coordinate = coordinates
            map.addAnnotation(pin)
        }
        view.addSubview(map)
        
    }
    
    @objc func sendButtonPressed() {
        
        guard let coordinates = coordinates else {
            return
        }
        navigationController?.popViewController(animated: true)
        completion?(coordinates)
    }
    
    @objc func didPressedMap(_ gesture: UITapGestureRecognizer) {
        
        let locationInView = gesture.location(in: map)
        let coordinates = map.convert(locationInView, toCoordinateFrom: map)
        self.coordinates = coordinates
        
        //need to delete previous pins
        for annotation in map.annotations {
            map.removeAnnotation(annotation)
        }
        
        //drop a pin
        let pin = MKPointAnnotation()
        pin.coordinate = coordinates
        map.addAnnotation(pin)
        
        
    }
    
    override func viewDidLayoutSubviews() {
        
        super.viewDidLayoutSubviews()
        map.frame = view.bounds
    }

}
