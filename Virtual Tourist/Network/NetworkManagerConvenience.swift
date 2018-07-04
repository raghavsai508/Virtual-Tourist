//
//  NetworkManagerConvenience.swift
//  Virtual Tourist
//
//  Created by Raghav Sai Cheedalla on 7/2/18.
//  Copyright © 2018 Swift Enthusiast. All rights reserved.
//

import Foundation
import UIKit

extension NetworkManager {
    
    func getPhotosFor(latitude: Double, longitude: Double, completionHandlerForPhotos: @escaping (_ photoURLs: [URL]?, _ error: NSError?) -> Void) -> URLSessionTask? {
        
        let methodParameters = [
            Constants.FlickrParameterKeys.Method: Constants.FlickrParameterValues.SearchMethod,
            Constants.FlickrParameterKeys.APIKey: Constants.FlickrParameterValues.APIKey,
            Constants.FlickrParameterKeys.BoundingBox: bboxString(latitude: latitude, longitude: longitude),
            Constants.FlickrParameterKeys.SafeSearch: Constants.FlickrParameterValues.UseSafeSearch,
            Constants.FlickrParameterKeys.Extras: Constants.FlickrParameterValues.MediumURL,
            Constants.FlickrParameterKeys.Format: Constants.FlickrParameterValues.ResponseFormat,
            Constants.FlickrParameterKeys.NoJSONCallback: Constants.FlickrParameterValues.DisableJSONCallback,
            Constants.FlickrParameterKeys.PerPage: Constants.FlickrParameterValues.PerPage
        ] as [String: AnyObject]
        
        let request = URLRequest(url: flickrURLFromParameters(methodParameters))
        return taskForURLRequest(request) { (dataObject, error) in
            if error != nil {
                completionHandlerForPhotos(nil,error)
            } else {
                var flickrPhotoURLs:[URL] = []
                if let photos = dataObject?[Constants.FlickrResponseKeys.Photos] as? [String: AnyObject], let photosArray = photos[Constants.FlickrResponseKeys.Photo] as? [[String: AnyObject]] {
                    for photoObject in photosArray {
                        let photoURL = URL(string: photoObject[Constants.FlickrResponseKeys.MediumURL] as! String)!
                        flickrPhotoURLs.append(photoURL)
                    }
                }
                completionHandlerForPhotos(flickrPhotoURLs, nil)
            }
        }
    }
    
    func getImage(forURL url: URL, completionHandlerForImage: @escaping (_ image: UIImage) -> Void) -> URLSessionTask? {
        let request = URLRequest(url: url)
        return taskForURLRequest(request, completionHandlerForRequest: { (dataObject, error) in
            print(dataObject)
        })
    }
    
    
    // MARK: Helper for Creating a URL from Parameters
    private func flickrURLFromParameters(_ parameters: [String:AnyObject]) -> URL {
        
        var components = URLComponents()
        components.scheme = Constants.Flickr.APIScheme
        components.host = Constants.Flickr.APIHost
        components.path = Constants.Flickr.APIPath
        components.queryItems = [URLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        
        return components.url!
    }
    
    private func bboxString(latitude: Double, longitude: Double) -> String {
        // ensure bbox is bounded by minimum and maximums
        let minimumLon = max(longitude - Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.0)
        let minimumLat = max(latitude - Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.0)
        let maximumLon = min(longitude + Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.1)
        let maximumLat = min(latitude + Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.1)
        return "\(minimumLon),\(minimumLat),\(maximumLon),\(maximumLat)"
    }
}
