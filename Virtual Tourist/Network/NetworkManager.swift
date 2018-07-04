//
//  NetworkManager.swift
//  Virtual Tourist
//
//  Created by Raghav Sai Cheedalla on 7/2/18.
//  Copyright © 2018 Swift Enthusiast. All rights reserved.
//

import UIKit

class NetworkManager: NSObject {

    static let sharedInstance = NetworkManager()
    // shared session
    var session = URLSession.shared

    override init() {
        super.init()
    }

    //MARK: URLRequest
    func taskForURLRequest(_ urlRequest: URLRequest, completionHandlerForRequest: @escaping (_ result: AnyObject?, _ error: NSError?) -> Void) -> URLSessionDataTask? {
        
        let task = session.dataTask(with: urlRequest as URLRequest) { (data, response, error) in
            
            func sendError(_ error: String) {
                print(error)
                let userInfo = [NSLocalizedDescriptionKey : error]
                completionHandlerForRequest(nil, NSError(domain: "taskForURLRequest", code: 1, userInfo: userInfo))
            }
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                sendError("There was an error with your request: \(error!.localizedDescription)")
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                sendError("No data was returned by the request!")
                return
            }
            
            // Parse the data and use the data (happens in completion handler) s
            self.convertDataWithCompletionHandler(data, completionHandlerForConvertData: completionHandlerForRequest)
        }
        
        /* Start the request */
        task.resume()
        
        return task
    }
    
    
    private func convertDataWithCompletionHandler(_ data: Data, completionHandlerForConvertData: (_ result: AnyObject?, _ error: NSError?) -> Void) {
        
        var parsedResult: AnyObject! = nil
        do {
            parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as AnyObject
        } catch {
            let userInfo = [NSLocalizedDescriptionKey : "Could not parse the data as JSON: '\(data)'"]
            completionHandlerForConvertData(nil, NSError(domain: "convertDataWithCompletionHandler", code: 1, userInfo: userInfo))
        }
    
        completionHandlerForConvertData(parsedResult, nil)
    }
}
