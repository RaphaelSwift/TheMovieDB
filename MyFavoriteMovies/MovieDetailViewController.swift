//
//  MovieDetailViewController.swift
//  MyFavoriteMovies
//
//  Created by Jarrod Parkes on 1/23/15.
//  Copyright (c) 2015 Udacity. All rights reserved.
//

import UIKit

class MovieDetailViewController: UIViewController {
    
    @IBOutlet weak var posterImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var favoriteButton: UIButton!
    @IBOutlet weak var unFavoriteButton: UIButton!

    var appDelegate: AppDelegate!
    var session: NSURLSession!
    
    var movie: Movie?
    
    // MARK: - Initialization
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /* Get the app delegate */
        appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate
        
        /* Get the shared URL session */
        session = NSURLSession.sharedSession()
    }
    
    override func viewWillAppear(animated: Bool) {
        
        super.viewWillAppear(animated)
        
        if let movie = movie {
        
        unFavoriteButton.hidden = true // set it to true by default
        favoriteButton.hidden = false // set it to false by default
        titleLabel.text = movie.title // display the title
        
        /* TASK A: Get favorite movies, then update the favorite buttons */
        /* 1A. Set the parameters */
        let methodParameters = [
            "api_key" : appDelegate.apiKey,
            "session_id" : appDelegate.sessionID!
        ]
        /* 2A. Build the URL */
        let methodName = "account/\(appDelegate.userID)/favorite/movies" // /account/{id}/favorite/movies Get the list of favorite movies for an account.
        
        let urlString = appDelegate.baseURLSecureString + methodName + appDelegate.escapedParameters(methodParameters)
        
        let url = NSURL(string: urlString)!
        
        /* 3A. Configure the request */
        let request = NSMutableURLRequest(URL: url)
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        /* 4A. Make the request */
        
        let task = session.dataTaskWithRequest(request) { data, response, downloadError in
            
            if let error =  downloadError {
                println("Could not make the request")
            } else {
                /* 5A. Parse the data */
                var parsingError: NSError? = nil
                if let parsedResult = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: &parsingError) as? NSDictionary {
                    
                    /* 6A. Use the data! */
                    
                    if let resultFavoriteMovies = parsedResult["results"] as? [[String:AnyObject]] {
                        let favoriteMovies = Movie.moviesFromResults(resultFavoriteMovies)
                        for (index,favoriteMovie) in enumerate(favoriteMovies) {
                            if favoriteMovie.id == self.movie?.id {
                                dispatch_async(dispatch_get_main_queue()) {
                                self.unFavoriteButton.hidden = false
                                self.favoriteButton.hidden = true
                                
                                }
                            }
                        }
                        
                        
                        
                    }

                } else {
                    dispatch_async(dispatch_get_main_queue()) {
                        self.titleLabel.text = " Unable to parse the data"
                }
                    
                }

                
            }
            
        }
        

        
        /* 7A. Start the request */
        
        task.resume()
        
        /* TASK B: Get the poster image, then populate the image view */
        if let posterPath = movie.posterPath {
            
            /* 1B. Set the parameters */
            // There are none...
            
            /* 2B. Build the URL */
            let baseURL = NSURL(string: appDelegate.config.baseImageURLString)!
            let url = baseURL.URLByAppendingPathComponent("w342").URLByAppendingPathComponent(posterPath)
            
            /* 3B. Configure the request */
            let request = NSURLRequest(URL: url)
            
            /* 4B. Make the request */
            let task = session.dataTaskWithRequest(request) {data, response, downloadError in
                
                if let error = downloadError {
                    println(error)
                } else {
                    
                    /* 5B. Parse the data */
                    // No need, the data is already raw image data.
                    
                    /* 6B. Use the data! */
                    if let image = UIImage(data: data!) {
                        dispatch_async(dispatch_get_main_queue()) {
                            self.posterImageView!.image = image
                        }
                    }
                }
            }
        
            /* 7B. Start the request */
            task.resume()
        }
    }
}
    
    // MARK: - Favorite Actions
    
    @IBAction func unFavoriteButtonTouchUpInside(sender: AnyObject) {
        
        /* TASK: Remove movie as favorite, then update favorite buttons */
        /* 1. Set the parameters */
        let methodParamaters = [
            "api_key" : appDelegate.apiKey,
            "session_id" : appDelegate.sessionID!
        ]
        
        /* 2. Build the URL */
        let urlString = appDelegate.baseURLSecureString + "account/\(appDelegate.userID!)/favorite" + appDelegate.escapedParameters(methodParamaters)
        let url = NSURL(string: urlString)!
        
        /* 3. Configure the request */
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        request.HTTPBody = "{\n  \"media_type\": \"movie\",\n  \"media_id\": \(self.movie!.id),\n  \"favorite\": false\n}".dataUsingEncoding(NSUTF8StringEncoding)
        
        /* 4. Make the request */
        let task = session.dataTaskWithRequest(request) { data, response, uploadError in
            if let error = uploadError {
                println("Unable to make the request")
            } else {
                
                /* 5. Parse the data */
                var parsingError: NSError? = nil
                if let parsedData = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: &parsingError) as? NSDictionary {
                    println(parsedData)
                    /* 6. Use the data! */
                    if let statusCode = parsedData["status_code"] as? Int {
                        if statusCode == 13 {
                            println("the movie was successfully removed from the favorite list")
                            dispatch_async(dispatch_get_main_queue()) {
                                self.unFavoriteButton.hidden = true
                                self.favoriteButton.hidden = false
                            }
                        }
                    }
                    
                }
            }
           
        }
        
        /* 7. Start the request */
        task.resume()
    }
    
    @IBAction func favoriteButtonTouchUpInside(sender: AnyObject) {
        
        /* TASK: Add movie as favorite, then update favorite buttons */
        /* 1. Set the parameters */
        let methodParameters = [
        "api_key": appDelegate.apiKey,
        "session_id": appDelegate.sessionID!
        ]
        
        /* 2. Build the URL */
        let urlString = appDelegate.baseURLSecureString + "account/\(appDelegate.userID!)/favorite" + appDelegate.escapedParameters(methodParameters)
        let url = NSURL(string: urlString)!
        
        /* 3. Configure the request */
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        request.HTTPBody = "{\"media_type\": \"movie\",\"media_id\": \(self.movie!.id),\"favorite\": true}".dataUsingEncoding(NSUTF8StringEncoding)
        
        /* 4. Make the request */
        let task = session.dataTaskWithRequest(request) { data, response, downloadError in
            if let error = downloadError {
                println("Unable to make the request")
            } else {
                /* 5. Parse the data */
                var parsingError: NSError? = nil
                let parsedResult = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: &parsingError) as! NSDictionary
                println(parsedResult)
                if let statusCode = parsedResult["status_code"] as? Int {
                    if statusCode == 1 || statusCode == 12  {
                        println("The movie was added successufly to the favorite list")
                        dispatch_async(dispatch_get_main_queue()) {
                        self.favoriteButton.hidden = true
                        self.unFavoriteButton.hidden = false
                        }
                    }
                }
            }
            
        }
        
        /* 6. Use the data! */
        /* 7. Start the request */
        task.resume()
    }
}