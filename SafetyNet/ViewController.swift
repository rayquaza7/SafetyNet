//
//  ViewController.swift
//  SafetyNet_SB
//
//  Created by Jake Taranov on 2022-01-15.
//

import UIKit
import CoreLocation
import Alamofire
import GooglePlaces


var locationsTuple: [(lat: CLLocationDegrees, long: CLLocationDegrees)] = []
var counter = 0

class ViewController: UIViewController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
	}
	
	@IBOutlet weak var homeLocation: UITextField!
	@IBOutlet weak var destinationTextField: UITextField!
	@IBOutlet weak var userDate: UIDatePicker!
	
	//This function is called when we click submit
	@IBAction func submit(_ sender: Any) {
		mainLoop()
	}
	
	//This is the main loop that will be running while the app is active.
	func mainLoop(){
		//While the date has not passed
		while(!isDatePassed(userDate: userDate.date)){
			grabLocation()
			tenMinuteTimer()
		}
		
		//The following code is executed when the time has passed
		
		//Pseudocode
		// if safeLocation != lastKnownLoation:
		//    for number in emergency Contacts:
		//          send emergency message to number
		// else:
		//      We can exit without needing to do anything
		//
		//
		
		//We want to now check if the user is at their "Safe Location", If they are then great, we can exit if not then we need to send out notifications to their network
		
	}
	
	
	//Return true if the date has passed, OW returns false
	func isDatePassed(userDate: Date) -> Bool{
		let delta = Date().distance(to: userDate)
		return delta < 0
	}
	
	//10 minute timer, so that we can grab the location after 10 mins.
	func tenMinuteTimer(){
		var timer = Timer()
		timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false, block: {_ in self.mainLoop()})
	}
	
	//grabs the current location of the user
	func grabLocation() {
		let labelRect = CGRect(x: 50, y: 100, width: 200, height: 100)
		let label = UILabel(frame: labelRect)
		LocationManager.shared.getUserLocation {[weak self] location in
			DispatchQueue.main.async {
				guard self != nil else {
					return
				}
				//print(location.coordinate.latitude, location.coordinate.longitude)
				locationsTuple.append((lat: location.coordinate.latitude, long: location.coordinate.longitude))
				//print(locationsTuple[counter])
				print(locationsTuple[counter])
				//                label.text = "Coordiantes: \(locationsTuple[counter])"
				//                label.numberOfLines = 2
				//self!.view.addSubview(label)
				counter += 1
			}
		}
	}
	
	func sendText(){
		print("In sendText()")
		if let accountSID = ProcessInfo.processInfo.environment["TWILIO_SID"],
		   let authToken = ProcessInfo.processInfo.environment["TWILIO_AUTH"]{
			
			let url = "https://api.twilio.com/2010-04-01/Accounts/\(accountSID)/Messages"
			let parameters = ["From": "18252557134", "To": "17789296671", "Body": "Hello from Swift!"]
			
			AF.request(url, method: .post, parameters: parameters)
				.authenticate(username: accountSID, password: authToken)
				.responseJSON { response in
					debugPrint(response)
				}
		}
	}
	
	// Present the Autocomplete view controller when the button is pressed.
	@IBAction @objc func autocompleteClicked(_ sender: UITextField) {
		let autocompleteController = GMSAutocompleteViewController()
		autocompleteController.delegate = self
		
		// Specify the place data types to return.
		let fields: GMSPlaceField = GMSPlaceField(rawValue: UInt(GMSPlaceField.name.rawValue) |
												  UInt(GMSPlaceField.placeID.rawValue))
		autocompleteController.placeFields = fields
		
		// Specify a filter.
		let filter = GMSAutocompleteFilter()
		filter.type = .address
		autocompleteController.autocompleteFilter = filter
		
		// Display the autocomplete view controller.
		present(autocompleteController, animated: true, completion: nil)
	}
}

extension ViewController: GMSAutocompleteViewControllerDelegate {
	
	// Handle the user's selection.
	func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
		homeLocation.text = place.name
		print("Place name: \(place.name)")
		print("Place ID: \(place.placeID)")
		print("Place attributions: \(place.attributions)")
		dismiss(animated: true, completion: nil)
	}
	
	func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
		// TODO: handle the error.
		print("Error: ", error.localizedDescription)
	}
	
	// User canceled the operation.
	func wasCancelled(_ viewController: GMSAutocompleteViewController) {
		dismiss(animated: true, completion: nil)
	}
	
	// Turn the network activity indicator on and off again.
	func didRequestAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
		UIApplication.shared.isNetworkActivityIndicatorVisible = true
	}
	
	func didUpdateAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
		UIApplication.shared.isNetworkActivityIndicatorVisible = false
	}
}
