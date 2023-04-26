//
//  MapViewController.swift
//  TravelBookProject
//
//  Created by ahmetburakozturk on 23.04.2023.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

class MapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var titleTextFiled: UITextField!
    @IBOutlet weak var subtitleTextField: UITextField!
    @IBOutlet weak var myMapView: MKMapView!
    
    var locationManager = CLLocationManager()
    var choosenLatitude = Double()
    var choosenLongitude = Double()
    
    var selectedText = ""
    var selectedId : UUID?
    
    var appDelegate : AppDelegate?
    var context : NSManagedObjectContext?
    
    var annotationLatitude = Double()
    var annotationLongitude = Double()
    var annotationTitle = String()
    
    @IBOutlet weak var saveButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        myMapView.delegate = self
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        
        let mapLongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(selectLocation(gestRec:)))
        mapLongPressGestureRecognizer.minimumPressDuration = 3
        myMapView.addGestureRecognizer(mapLongPressGestureRecognizer)
        
        appDelegate = UIApplication.shared.delegate as? AppDelegate
        context = appDelegate!.persistentContainer.viewContext
        
        if selectedText != ""{
            getSingleData()
        } else{
            saveButton.isHidden = false
            titleTextFiled.isEnabled = true
            subtitleTextField.isEnabled = true
        }
        
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation{
            return nil
        }
        
        let reuseId = "myAnnotation"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKMarkerAnnotationView
        if pinView == nil{
            pinView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView?.canShowCallout = true
            pinView?.tintColor = UIColor.blue
            let button = UIButton(type: UIButton.ButtonType.detailDisclosure)
            pinView?.rightCalloutAccessoryView = button
        }else {
            pinView?.annotation = annotation
        }
        return pinView
    }
    
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if selectedText != ""{
            let reqLocation = CLLocation(latitude: annotationLatitude, longitude: annotationLongitude)
            CLGeocoder().reverseGeocodeLocation(reqLocation){(placeMarks ,error) in
                if let placemark = placeMarks{
                    if placemark.count > 0 {
                        let newplaceMark = MKPlacemark(placemark: placemark[0])
                        let item = MKMapItem(placemark: newplaceMark)
                        item.name = self.annotationTitle
                        let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
                        item.openInMaps(launchOptions: launchOptions)
                    }
                }
            }
        }
    }
    
    func getSingleData(){
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Location")
        let id = selectedId?.uuidString
        request.predicate = NSPredicate(format: "id = %@", id!)
        request.returnsObjectsAsFaults = false
        do{
            let results = try context!.fetch(request)
            if results.count > 0{
                for result in results as! [NSManagedObject]{
                    var latitude = 0.0
                    var longitude = 0.0
                    let annotation = MKPointAnnotation()
                    if let title = result.value(forKey: "title") as? String{
                        annotation.title = title
                        titleTextFiled.text = title
                        annotationTitle = title
                        if let subtitle = result.value(forKey: "subtitle") as? String{
                            annotation.subtitle = subtitle
                            subtitleTextField.text = subtitle
                            if let resultLatitude = result.value(forKey: "latitude") as? Double{
                                latitude = resultLatitude
                                if let resultLongitude = result.value(forKey: "longitude") as? Double{
                                    longitude = resultLongitude
                                }
                            }
                        }
                    }
                    let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                    let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                    let region = MKCoordinateRegion(center: coordinate, span: span)
                    annotation.coordinate = coordinate
                    myMapView.setRegion(region, animated: true)
                    myMapView.addAnnotation(annotation)
                    annotationLatitude = latitude
                    annotationLongitude = longitude
                    saveButton.isHidden = true
                    titleTextFiled.isEnabled = false
                    subtitleTextField.isEnabled = false
                }
            }
        }catch{
            print("fetch error!")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if selectedText == ""{
            let coordinate = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
            let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            let region = MKCoordinateRegion(center: coordinate, span: span)
            myMapView.setRegion(region, animated: true)
        }
    }
    
    
    @objc func selectLocation(gestRec: UILongPressGestureRecognizer){
        if gestRec.state == .began{
            let selectedPoint = gestRec.location(in: myMapView)
            let coordinate = self.myMapView.convert(selectedPoint, toCoordinateFrom: self.myMapView)
            choosenLatitude = coordinate.latitude
            choosenLongitude = coordinate.longitude
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            if let title = titleTextFiled.text{
                annotation.title = title
            }
            if let subtitle = subtitleTextField.text{
                annotation.subtitle = subtitle
            }
            self.myMapView.addAnnotation(annotation)
            
        }
        
    }
    


    @IBAction func saveButtonClicked(_ sender: Any) {
        let locationTable = NSEntityDescription.insertNewObject(forEntityName: "Location", into: context!)
        if let title = titleTextFiled.text{
            if title != ""{
                locationTable.setValue(titleTextFiled.text!, forKey: "title")
            }
        }
        if let subtitle = subtitleTextField.text{
            if subtitle != "" {
                locationTable.setValue(subtitleTextField.text!, forKey: "subtitle")
            }
        }
        locationTable.setValue(choosenLatitude, forKey: "latitude")
        locationTable.setValue(choosenLongitude, forKey: "longitude")
        locationTable.setValue(UUID(), forKey: "id")

        do{
            try context!.save()
            NotificationCenter.default.post(name: NSNotification.Name("newDataAdded"), object: nil)
            self.navigationController?.popViewController(animated: true)
        }catch{
            print("Error!")
        }
        
        
    }
}
