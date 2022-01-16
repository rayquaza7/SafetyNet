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


var locationsTuple: [(lat: CLLocationDegrees, long: CLLocationDegrees, time: Date)] = []
var locationCounter = 0

class ViewController: UIViewController, GMSAutocompleteViewControllerDelegate {
	override func viewDidLoad() {
		super.viewDidLoad()
	}
	
	@IBOutlet weak var homeLocation: UITextField!
	@IBOutlet weak var destinationTextField: UITextField!
	@IBOutlet weak var userDate: UIDatePicker!
	@IBOutlet weak var extraInfo: UITextField!
	@IBOutlet weak var contactNumber3: UITextField!
	@IBOutlet weak var contactName3: UITextField!
	@IBOutlet weak var contactNumber2: UITextField!
	@IBOutlet weak var contactName2: UITextField!
	@IBOutlet weak var contactNumber1: UITextField!
	@IBOutlet weak var contactName1: UITextField!
	@IBOutlet weak var cancelState: UIButton!
	@IBOutlet weak var submitState: UIButton!
	
	// home has tag 1, dest has tag 0
	var decideField: Int = 0
	//coordinate data for homeLocation
	var homeCoordinates = CLLocationCoordinate2DMake(0, 0)
	
	//This function is called when we click submit
	@IBAction func submit(_ sender: Any) {
		submitState.isEnabled = false
		cancelState.isEnabled = true
		_ = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(self.mainLoop), userInfo: nil, repeats: true)
//		//Timer to get current locaitons
//		_ = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(self.grabLocation), userInfo: nil, repeats: true)
	}
	
	@IBAction func onCancel(_ sender: Any) {
		//TODO:terminate loop
		submitState.isEnabled = true
		cancelState.isEnabled = false
		exit(status: false)
	}
	
	var stopLoop: Bool = false
	@objc func mainLoop(){
		if (isDatePassed(userDate: userDate.date) && !stopLoop){
			let threshold = 0.005
			let lastKnownLocation = locationsTuple[locationCounter-1]
			stopLoop = true
			if(abs(lastKnownLocation.lat - homeCoordinates.latitude) < threshold
			   && abs(lastKnownLocation.long - homeCoordinates.longitude) < threshold)
			{
				self.exit(status: false)
			}
			else {
				self.exit(status: true)
			}
		} else if (!stopLoop) {
			self.grabLocation()
		}
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
	@objc func grabLocation() {
		print("INSIDE GRAB LOCATION")
		let labelRect = CGRect(x: 50, y: 100, width: 200, height: 100)
		let label = UILabel(frame: labelRect)
		LocationManager.shared.getUserLocation {[weak self] location in
			DispatchQueue.main.async {
				guard self != nil else {
					return
				}
				locationsTuple.append((lat: location.coordinate.latitude, long: location.coordinate.longitude, time: location.timestamp))
				locationCounter += 1
			}
		}
	}
	
	func sendText(){
		var textMsg: String = "Hey! This is a message from SafetyNet. Your friend John Doe has not returned home by the time they said they would. "
		textMsg += "Your friend was heading to \(destinationTextField.text!) "
		//		textMsg += "and were supposed to be back by" + String(userDate.date)
		textMsg += "and they left from  \(homeLocation.text!). "
		textMsg += "at \(locationsTuple[0].time). "
		textMsg += "and were supposed to be back by \(userDate.date) "
		textMsg += "They also left these notes about what they were doing: \(extraInfo.text!). "
		textMsg += "Please reach out to them!"
		textMsg += " This is a timeline of their location: "
		
		for location in locationsTuple {
			textMsg += "\(location.lat), \(location.long), \(location.time) \n"
		}
		
		if let accountSID = ProcessInfo.processInfo.environment["TWILIO_SID"],
		   let authToken = ProcessInfo.processInfo.environment["TWILIO_AUTH"]{
			
			let url = "https://api.twilio.com/2010-04-01/Accounts/\(accountSID)/Messages"
			//			let parameters = ["From": "18252557134", "To": "17789296671", "Body": textMsg]
			
			let parameters = ["From": "18252557134", "To": contactNumber1.text!, "Body": textMsg] as [String : Any]
			
			AF.request(url, method: .post, parameters: parameters)
				.authenticate(username: accountSID, password: authToken)
				.responseJSON { response in
					debugPrint(response)
//					self.exit(status: false)
				}
			//
			//			let parameters1 = ["From": "18252557134", "To": contactNumber2.text!, "Body": textMsg] as [String : Any]
			//			AF.request(url, method: .post, parameters: parameters1)
			//				.authenticate(username: accountSID, password: authToken)
			//				.responseJSON { response in
			//					debugPrint(response)
			//				}
			//
			//			let parameters2 = ["From": "18252557134", "To": contactNumber3.text!, "Body": textMsg] as [String : Any]
			//			AF.request(url, method: .post, parameters: parameters2)
			//				.authenticate(username: accountSID, password: authToken)
			//				.responseJSON { response in
			//					debugPrint(response)
			//				}
		}
	}
	
	
	//if passed true -> The user did not return home safe. if passed false -> The user returned home safe
	func exit(status: Bool){
		print("-----EXITING-----")
		if(status){
			print("-----THE USER DID NOT RETURN HOME-----")
			sendText()
			self.performSegue(withIdentifier: "Text", sender: self)
		}
		else{
			print("-----THE USER DID RETURN HOME SAFE-----")
			self.performSegue(withIdentifier: "NoText", sender: self)
		}
	}
	
	// Present the Autocomplete view controller when the button is pressed.
	@IBAction @objc func autocompleteClicked(_ sender: UITextField) {
		//coming from dest
		if (sender.tag == 0) {
			decideField = 0
		} else {
			decideField = 1
		}
		
		let autocompleteController = GMSAutocompleteViewController()
		autocompleteController.delegate = self
		
		// Specify the place data types to return.
		//		let fields: GMSPlaceField = GMSPlaceField(rawValue: UInt(GMSPlaceField.name.rawValue) |
		//												  UInt(GMSPlaceField.placeID.rawValue))
		let fields: GMSPlaceField = GMSPlaceField(rawValue:UInt(GMSPlaceField.name.rawValue) |
												  UInt(GMSPlaceField.placeID.rawValue) |
												  UInt(GMSPlaceField.coordinate.rawValue) |
												  GMSPlaceField.addressComponents.rawValue |
												  GMSPlaceField.formattedAddress.rawValue)
		
		autocompleteController.placeFields = fields
		
		// Specify a filter.
		let filter = GMSAutocompleteFilter()
		filter.type = .address
		autocompleteController.autocompleteFilter = filter
		
		// Display the autocomplete view controller.
		present(autocompleteController, animated: true, completion: nil)
	}
	
	// Handle the user's selection.
	func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
		if (decideField == 0) {
			destinationTextField.text = place.name
		} else {
			homeLocation.text = place.name
			homeCoordinates.longitude = place.coordinate.longitude
			homeCoordinates.latitude = place.coordinate.latitude
		}
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
