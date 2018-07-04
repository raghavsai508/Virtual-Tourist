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
    
    var travelAnnotation: TravelAnnotation!
    var dataController: DataController!
    
    var fetchedResultsController:NSFetchedResultsController<Photo>!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let url = URL(string: travelAnnotation.travelId!)!
        let pinObjectId = dataController.viewContext.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: url)
        let pin = dataController.viewContext.object(with: pinObjectId!) as! Pin
        
        setupFetchedResultsController(forPin: pin)
        setupMapView()
        setupCollectionView()
    }
    
    fileprivate func setupFetchedResultsController(forPin pin: Pin) {
        let fetchRequest:NSFetchRequest<Photo> = Photo.fetchRequest()
        let predicate = NSPredicate(format: "pin == %@", pin)
        fetchRequest.predicate = predicate
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "\(pin)-photos")
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
            if fetchedResultsController.fetchedObjects?.count == 0 {
                getFlickrPhotos()
            }
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    fileprivate func setupCollectionView() {
        albumCollectionView.delegate = self
        albumCollectionView.dataSource = self
    }
    
    fileprivate func setupMapView() {
        // Do any additional setup after loading the view.
        mapView.delegate = self
        mapView.addAnnotation(travelAnnotation)
        var region = MKCoordinateRegionMake(travelAnnotation.coordinate, MKCoordinateSpanMake(0.5, 0.5))
        region.center = travelAnnotation.coordinate
        mapView.setRegion(region, animated: false)
    }
    
    fileprivate func getFlickrPhotos() {
        let backgroundContext: NSManagedObjectContext! = dataController?.backgroundContext
        let networkManager = NetworkManager.sharedInstance
        networkManager.getPhotosFor(latitude: travelAnnotation.coordinate.latitude, longitude: travelAnnotation.coordinate.longitude) { [weak self](flickrURLS, error) in
            guard let strongSelf = self else {
                return
            }
            backgroundContext.perform {
                if error == nil, let flickrURLS = flickrURLS  {
                    for photoURL in flickrURLS {
                        let photo = Photo(context: backgroundContext)
                        photo.photoUrl = photoURL.absoluteString
                        try? backgroundContext.save()
                    }
                }
            }
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
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: annotationIdentifier)
        } else {
            annotationView!.annotation = annotation
        }
        return annotationView
    }
    
}

extension PhotoAlbumViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return fetchedResultsController.sections?.count ?? 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[0].numberOfObjects ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let photo = fetchedResultsController.object(at: indexPath)
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoCollectionViewCell.reuseIdentifier, for: indexPath) as! PhotoCollectionViewCell
        
        
        return cell
    }

}

extension PhotoAlbumViewController: NSFetchedResultsControllerDelegate {
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        DispatchQueue.main.async {
            switch type {
            case .insert:
                self.albumCollectionView.insertItems(at: [indexPath!])
                break
            case .delete:
                self.albumCollectionView.deleteItems(at: [indexPath!])
                break
            case .update, .move:
                self.albumCollectionView.reloadItems(at: [indexPath!])
                break
            }
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        DispatchQueue.main.async {
            let indexSet = IndexSet(integer: sectionIndex)
            switch type {
            case .insert: self.albumCollectionView.insertSections(indexSet)
            case .delete: self.albumCollectionView.deleteSections(indexSet)
            case .update, .move:
                fatalError("Invalid change type in controller(_:didChange:atSectionIndex:for:). Only .insert or .delete should be possible.")
            }
        }
    }
}

