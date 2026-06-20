import SwiftUI
import MapKit
import CoreLocation

//All Map Data

class MapViewModel: NSObject, ObservableObject , CLLocationManagerDelegate{
    
    @Published var MapView = MKMapView()
    
    //Region
    @Published var region : MKCoordinateRegion! //based on your location it will set up the screen
    
    //Alert
    @Published var permissionDenied = false
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        //Checking Permissions for location access
        if #available(iOS 14.0, *) {
            switch manager.authorizationStatus {
            case .denied: 
                //Alert
                permissionDenied.toggle()
            case .notDetermined:
                //Request
                manager.requestWhenInUseAuthorization()
            default: 
                ()
            }
        } else {
            // Fallback on earlier versions
        }
        
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        
    }
}
