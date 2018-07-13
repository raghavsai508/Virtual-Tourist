//
//  ViewController.swift
//  Virtual Tourist
//
//  Created by Raghav Sai Cheedalla on 6/21/18.
//  Copyright © 2018 Swift Enthusiast. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class TravelLocationsViewController: UIViewController, NSFetchedResultsControllerDelegate {
    
    var dataController: DataController!
    var fetchedResultsController: NSFetchedResultsController<Pin>!
    var pins: [Pin] = []
    
    let photoAlbumIdentifier = "showTravelLocations"
    
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupMapView()
        setupFetchedResultsController()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        saveMapState();
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchedResultsController = nil
    }
    
    fileprivate func setupMapView() {
        // Do any additional setup after loading the view, typically from a nib.
        let longPressGR = UILongPressGestureRecognizer(target: self, action: #selector(addMapAnnotation(gestureRecognizer:)))
        mapView.delegate = self
        mapView.addGestureRecognizer(longPressGR)
        
        let userDefaults = UserDefaults.standard
        if let locationData = userDefaults.value(forKey: Constants.MapStateKey) as? [String: Double] {
            let span = MKCoordinateSpanMake(locationData[Constants.MapState.LatitudeDelta]!, locationData[Constants.MapState.LongitudeDelta]!)
            let center = CLLocationCoordinate2DMake(locationData[Constants.MapState.Latitude]!, locationData[Constants.MapState.Longitude]!)
            let region = MKCoordinateRegionMake(center, span)
            mapView.setRegion(region, animated: false)
        }
    }
    
    fileprivate func setupFetchedResultsController() {
        let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
            if let pinsFetched = fetchedResultsController.fetchedObjects {
                pins = pinsFetched
                for pin in pinsFetched {
                    let annotation = TravelAnnotation(travelId: pin.objectID.uriRepresentation().absoluteString, coordinate: CLLocationCoordinate2DMake(pin.latitude, pin.longitude))
                    mapView.addAnnotation(annotation)
                }
            }
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    fileprivate func saveMapState() {
        let userDefaults = UserDefaults.standard
        let saveLocationState: [String: Double] = [Constants.MapState.Latitude: mapView.centerCoordinate.latitude,
                                                   Constants.MapState.Longitude: mapView.centerCoordinate.longitude,
                                                   Constants.MapState.LatitudeDelta: mapView.region.span.latitudeDelta,
                                                   Constants.MapState.LongitudeDelta: mapView.region.span.longitudeDelta]
        userDefaults.set(saveLocationState, forKey: Constants.MapStateKey)
        userDefaults.synchronize()
    }
    
    @objc func addMapAnnotation(gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .ended {
            let mapPoint = gestureRecognizer.location(in: mapView)
            let coordinates = mapView.convert(mapPoint, toCoordinateFrom: mapView)
            
            let pin = Pin(context: dataController.viewContext)
            pin.currentPageNumber = 1 // by default set to 1
            pin.pageNumbers = 1 // by default set to 1
            pin.latitude = coordinates.latitude
            pin.longitude = coordinates.longitude
            pin.creationDate = Date()
            do {
                try dataController.viewContext.save()
                pins.append(pin)
                let annotation = TravelAnnotation(travelId: pin.objectID.uriRepresentation().absoluteString, coordinate: coordinates)
                mapView.addAnnotation(annotation)
            } catch let error as NSError {
                fatalError("The fetch could not store the location: \(error.userInfo)")
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == photoAlbumIdentifier {
            let photoAlbumViewController = segue.destination as! PhotoAlbumViewController
            photoAlbumViewController.dataController = dataController
            photoAlbumViewController.travelPin = sender as! Pin
        }
    }
}

extension TravelLocationsViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {        
        if let travelAnnotation = view.annotation as? TravelAnnotation {
            let url = URL(string: travelAnnotation.travelId!)!
            let pinObjectId = dataController.viewContext.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: url)
            let filteredPins = pins.filter{ $0.objectID == pinObjectId }
            if filteredPins.count > 0 {
                let pin = filteredPins.first
                performSegue(withIdentifier: photoAlbumIdentifier, sender: pin)
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let annotation = annotation as? TravelAnnotation else { return nil }
        let annotationIdentifier = "TravelAnnotationIdentifier"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: annotationIdentifier)
        if annotationView == nil {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: annotationIdentifier)
        } else {
            annotationView!.annotation = annotation
        }
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        saveMapState()
    }
}
