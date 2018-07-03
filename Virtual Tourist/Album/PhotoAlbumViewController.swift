//
//  PhotoAlbumViewController.swift
//  Virtual Tourist
//
//  Created by Raghav Sai Cheedalla on 6/21/18.
//  Copyright © 2018 Swift Enthusiast. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var albumCollectionView: UICollectionView!
    @IBOutlet weak var btnNewCollection: UIBarButtonItem!
    
    var travelPin: Pin!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupMapView()
        setupCollectionView()
        getFlickrPhotos()
    }
    
    fileprivate func setupCollectionView() {
//        albumCollectionView.delegate = self
//        albumCollectionView.dataSource = self
    }
    
    fileprivate func setupMapView() {
        // Do any additional setup after loading the view.
        mapView.delegate = self
        let travelAnnotation = TravelAnnotation(travelId: travelPin.objectID.uriRepresentation().absoluteString, coordinate: CLLocationCoordinate2DMake(travelPin.latitude, travelPin.longitude))
        mapView.addAnnotation(travelAnnotation)
        var region = MKCoordinateRegionMake(travelAnnotation.coordinate, MKCoordinateSpanMake(0.5, 0.5))
        region.center = travelAnnotation.coordinate
        mapView.setRegion(region, animated: false)
    }
    
    fileprivate func getFlickrPhotos() {
        let networkManager = NetworkManager.sharedInstance
        networkManager.getPhotosFor(latitude: travelPin.latitude, longitude: travelPin.longitude) {
            
        }
    }
    
    //MARK: Action methods
    @IBAction func btnNewCollectionAction(_ sender: Any) {
        
    }
}

extension PhotoAlbumViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let annotation = annotation as? TravelAnnotation else { return nil }
        let annotationIdentifier = "TravelAnnotationIdentifier"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: annotationIdentifier)
        if annotationView == nil {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: annotationIdentifier)        }
        else {
            annotationView!.annotation = annotation
        }
        return annotationView
    }
}

//extension PhotoAlbumViewController: UICollectionViewDataSource, UICollectionViewDelegate {
//
//    func numberOfSections(in collectionView: UICollectionView) -> Int {
//        return 1
//    }
//
//    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        return 20
//    }
//
//    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        return nil
//    }
//
//}
