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
    
    let photoAlbumIdentifier = "showTravelLocations"
    
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupMapView()
        setupFetchedResultsController()
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
    }
    
    fileprivate func setupFetchedResultsController() {
        let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "Pins")
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
            if let pins = fetchedResultsController.fetchedObjects {
                for pin in pins {
                    let annotation = TravelAnnotation(travelId: pin.objectID.uriRepresentation().absoluteString, coordinate: CLLocationCoordinate2DMake(pin.latitude, pin.longitude))
                    mapView.addAnnotation(annotation)
                }
            }
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    @objc func addMapAnnotation(gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .ended {
            let mapPoint = gestureRecognizer.location(in: mapView)
            let coordinates = mapView.convert(mapPoint, toCoordinateFrom: mapView)
            
            let pin = Pin(context: dataController.viewContext)
            let annotation = TravelAnnotation(travelId: pin.objectID.uriRepresentation().absoluteString, coordinate: coordinates)
            
            pin.latitude = annotation.coordinate.latitude
            pin.longitude = annotation.coordinate.longitude
            pin.creationDate = Date()
            do {
                try dataController.viewContext.save()
                mapView.addAnnotation(annotation)
            } catch {
                fatalError("The fetch could not store the location: \(error.localizedDescription)")
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == photoAlbumIdentifier {
            let photoAlbumViewController = segue.destination as! PhotoAlbumViewController
            photoAlbumViewController.travelPin = sender as! Pin
        }
    }
}

extension TravelLocationsViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let travelAnnotation = view.annotation as? TravelAnnotation, let pins = fetchedResultsController.fetchedObjects {
            let filteredPins = pins.filter { $0.objectID.uriRepresentation().absoluteString == travelAnnotation.travelId }
            if filteredPins.count > 0 {
                let pin = filteredPins[0]
                performSegue(withIdentifier: photoAlbumIdentifier, sender: pin)
            }
        }
    }
    
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
