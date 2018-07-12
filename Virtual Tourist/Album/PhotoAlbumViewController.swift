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
    var dataController: DataController!
    
    var fetchedResultsController: NSFetchedResultsController<Photo>!

    fileprivate let kLeftPadding: CGFloat = 4.5
    fileprivate let kRightPadding: CGFloat = 4.5
    fileprivate static var imageDownloadCount: Int = -1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupFetchedResultsController()
        setupMapView()
        setupCollectionView()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchedResultsController = nil
    }
    
    fileprivate func setupFetchedResultsController() {
        let fetchRequest:NSFetchRequest<Photo> = Photo.fetchRequest()
        let predicate = NSPredicate(format: "pin == %@", travelPin)
        fetchRequest.predicate = predicate
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
            if fetchedResultsController.fetchedObjects?.count == 0 {
                btnNewCollection.isEnabled = false
                getFlickrPhotos()
            } else {
                PhotoAlbumViewController.imageDownloadCount = fetchedResultsController.fetchedObjects!.count
                btnNewCollection.isEnabled = true
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
        let travelAnnotation = TravelAnnotation(travelId: travelPin.objectID.uriRepresentation().absoluteString, coordinate: CLLocationCoordinate2DMake(travelPin.latitude, travelPin.longitude))
        mapView.addAnnotation(travelAnnotation)
        var region = MKCoordinateRegionMake(travelAnnotation.coordinate, MKCoordinateSpanMake(0.5, 0.5))
        region.center = travelAnnotation.coordinate
        mapView.setRegion(region, animated: false)
    }
    
    fileprivate func getFlickrPhotos() {
        let networkManager = NetworkManager.sharedInstance
        let _ = networkManager.getPhotosFor(latitude: travelPin.latitude, longitude: travelPin.longitude, withPageNumber: Int(travelPin.currentPageNumber)) { [weak self](flickrURLS, pages, error) in
            DispatchQueue.main.async {
                guard let strongSelf = self else {
                    return
                }
                
                let pageNumber = Int(strongSelf.travelPin.currentPageNumber) + 1
                if pageNumber >= pages {
                    strongSelf.travelPin.currentPageNumber = 1
                } else {
                    strongSelf.travelPin.currentPageNumber = Int64(pageNumber)
                }
                strongSelf.travelPin.pageNumbers = Int64(pages)
                try? strongSelf.dataController.viewContext.save()
                
                if error == nil, let flickrURLS = flickrURLS  {
                    PhotoAlbumViewController.imageDownloadCount = flickrURLS.count
                    for photoURL in flickrURLS {
                        let photo = Photo(context: strongSelf.dataController.viewContext)
                        photo.photoUrl = photoURL.absoluteString
                        photo.pin = strongSelf.travelPin
                        do {
                            try strongSelf.dataController.viewContext.save()
                        } catch let error as NSError {
                            fatalError("The fetch could not store the photo: \(error.userInfo)")
                        }
                    }
                }
            }
        }
    }
    
    //MARK: Action methods
    @IBAction func btnNewCollectionAction(_ sender: Any) {
        if let photos = fetchedResultsController.fetchedObjects {
            for photo in photos {
                dataController.viewContext.delete(photo)
                try? dataController.viewContext.save()
            }
            getFlickrPhotos()
        }
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

extension PhotoAlbumViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return fetchedResultsController.sections?.count ?? 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[0].numberOfObjects ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let photo = fetchedResultsController.object(at: indexPath)
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoCollectionViewCell.reuseIdentifier, for: indexPath) as! PhotoCollectionViewCell
        if let photoData = photo.photo {
            let image = UIImage(data: photoData)
            cell.photoImageView.image = image
        } else {
            let networkManager = NetworkManager.sharedInstance
            let photoId = photo.objectID
            let _ = networkManager.getImage(forURL: URL(string: photo.photoUrl!)!) { (image) in
                
                DispatchQueue.main.async {
                    if let image = image {
                        let photoObject = self.dataController.viewContext.object(with: photoId) as! Photo
                        cell.photoImageView.image = image
                        photoObject.photo = UIImagePNGRepresentation(image)
                        try? self.dataController.viewContext.save() 
                    }
                    PhotoAlbumViewController.imageDownloadCount = PhotoAlbumViewController.imageDownloadCount - 1
                    self.updateImageCollectionButton()
                }
            }
        }
        
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let photo = fetchedResultsController.object(at: indexPath)
        dataController.viewContext.delete(photo)
        try? dataController.viewContext.save()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (view.bounds.size.width/3.0)-kRightPadding-kLeftPadding
        let size = CGSize(width: width, height: width)
        return size
    }
   
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsMake(0, kLeftPadding/2, 0, kRightPadding/2)
    }
    
    func updateImageCollectionButton() {
        if PhotoAlbumViewController.imageDownloadCount == 0 {
            btnNewCollection.isEnabled = true
        } else {
            btnNewCollection.isEnabled = false
        }
    }
    
}

extension PhotoAlbumViewController: NSFetchedResultsControllerDelegate {
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
            case .insert:
                albumCollectionView.insertItems(at: [newIndexPath!])
                break
            case .delete:
                albumCollectionView.deleteItems(at: [indexPath!])
                break
            case .update, .move:
                break
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        let indexSet = IndexSet(integer: sectionIndex)
        switch type {
            case .insert: self.albumCollectionView.insertSections(indexSet)
            case .delete: self.albumCollectionView.deleteSections(indexSet)
            case .update, .move:
                fatalError("Invalid change type in controller(_:didChange:atSectionIndex:for:). Only .insert or .delete should be possible.")
        }
    }
}

