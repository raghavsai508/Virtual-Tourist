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
    
    @objc func addMapAnnotation(gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .ended {
            let mapPoint = gestureRecognizer.location(in: mapView)
            let coordinates = mapView.convert(mapPoint, toCoordinateFrom: mapView)
            
            let pin = Pin(context: dataController.viewContext)
            let annotation = TravelAnnotation(travelId: pin.objectID.uriRepresentation().absoluteString, coordinate: coordinates)
            pin.currentPageNumber = 1 // by default set to 1
            pin.pageNumbers = 1 // by default set to 1
            pin.latitude = annotation.coordinate.latitude
            pin.longitude = annotation.coordinate.longitude
            pin.creationDate = Date()
            pins.append(pin)
            do {
                try dataController.viewContext.save()
                mapView.addAnnotation(annotation)
            } catch let error as NSError {
                fatalError("The fetch could not store the location: \(error.userInfo)")
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == photoAlbumIdentifier {
            let photoAlbumViewController = segue.destination as! PhotoAlbumViewController
//            let travelAnnotation = sender as! TravelAnnotation
//            let url = URL(string: travelAnnotation.travelId!)!
//            let pinObjectId = dataController.viewContext.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: url)
//            let pin = dataController.viewContext.object(with: pinObjectId!) as! Pin
//            do {
//                let pin = dataController.viewContext.registeredObject(for: pinObjectId!) as! Pin
//                photoAlbumViewController.dataController = dataController
//                photoAlbumViewController.travelPin = pin
//            } catch {
//                fatalError("The fetch could not store the location: \(error.localizedDescription)")
//            }
            
//            let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
//            let predicate = NSPredicate(format: "SELF = %@", pinObjectId!)
//            fetchRequest.predicate = predicate
//            let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
//            fetchRequest.sortDescriptors = [sortDescriptor]
//
//            do {
//                let pins = try dataController.viewContext.fetch(fetchRequest)
//                for pin in pins {
//                    photoAlbumViewController.dataController = dataController
//                    photoAlbumViewController.travelPin = pin
//                }
//            } catch {
//                fatalError("The fetch could not store the location: \(error.localizedDescription)")
//            }
            
            photoAlbumViewController.dataController = dataController
            photoAlbumViewController.travelPin = sender as! Pin
        }
    }
}

extension TravelLocationsViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let travelAnnotation = view.annotation as? TravelAnnotation {
            let annotations = mapView.annotations as! [TravelAnnotation]
            guard let index = annotations.index(of: travelAnnotation) else {
                return
            }
            
            let pin = pins[index]
            performSegue(withIdentifier: photoAlbumIdentifier, sender: pin)
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
    
}
