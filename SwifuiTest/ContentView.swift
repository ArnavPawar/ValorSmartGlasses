//
//  ContentView.swift
//  SwifuiTest
//
//  Created by maahika gupta on 12/28/22.
//

import SwiftUI
import SwiftUIPolygonGeofence
import CoreLocation
import CoreLocationUI
import MapKit
import ActiveLookSDK

struct ContentView: View {
    @ObservedObject var compassHeading = CompassHeading()
    @StateObject private var viewModel = ContentViewModel()

    @SwiftUI.State var Glasses = MapScreen()
    @SwiftUI.State var locations = [Location]()

    @SwiftUI.State private var selectedPlace: Location?
    //let geoFence = SwiftUIPolygonGeofence
    //var activeLook: ActiveLookSDK
    
    //MapMarker(coordinate: CLLocationCoordinate2D(latitude:location.latitude,longitude: location.longitude))
    
    var body: some View {
        NavigationView{
            ZStack{
                Map(coordinateRegion: $viewModel.region,showsUserLocation: true,annotationItems:locations){
                    location in MapAnnotation(coordinate:location.coordinate){
                        ZStack{
                            Image(systemName: "mappin")
                                .resizable()
                                .padding(.bottom)
                            //.foregroundColor(.red)
                                .frame(width: 20, height: 60)
                                .scaledToFit()
                                .padding(.bottom)
                                .foregroundColor(.red)
                            
                            Text(location.name)
                                .fixedSize()
                        }
                        .onTapGesture {
                            selectedPlace = location
                        }
                    }
                }
                .ignoresSafeArea()
                
                .accentColor(Color(.systemPink))
                .onAppear{
                    viewModel.checkLocationAuthorization()
                }
                
                Circle()
                    .fill(.blue)
                    .opacity(0.3)
                    .frame(width:15,height:15)
                VStack{
                    Spacer()
                    Capsule()
                        .frame(width:5, height:50)
                    ZStack{
                        ForEach(Marker.markers(), id:\.self) {marker in
                            CompassMarkerView(marker: marker, compassDegrees: self.compassHeading.degrees)
                        }
                    }
                    .frame(width: 150, height: 150)
                    .rotationEffect(Angle(degrees: self.compassHeading.degrees))
                    .statusBar(hidden:true)
                }
                
                //}
                Spacer()
                VStack{
                    Button(action: connectGlasses) {
                        Image(systemName: "eyeglasses")
                        .frame(width: 50, height:30)
                    }
                    .foregroundColor(.white)
                    .background(.black.opacity(0.5))
                    Button(action: sendDisplay) {
                        Image(systemName: "display")
                        .frame(width: 50, height:30)
                    }
                    Button(action: stopTry) {
                        Image(systemName: "stop")
                        .frame(width: 50, height:30)
                    }
                    Spacer(minLength: -300)
                    HStack{
                        LocationButton(.currentLocation){
                            viewModel.checkLocationAuthorization()
                        }
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .labelStyle(.iconOnly)
                        .symbolVariant(.fill)
                        .padding(.leading)
                        
                        Spacer()
                        Button{
                            let getLocation = viewModel.ApplyState()
                            locations.append(getLocation)
                            //create new location
                        } label: {
                            Image(systemName:"plus")
                        }
                        .padding()
                        .background(.black.opacity(0.75))
                        .foregroundColor(.white)
                        .font(.title)
                        .clipShape(Circle())
                        .padding(.trailing)
                    }
                }
            }
            .sheet(item: $selectedPlace){ place in
                EditView(location: place){ newLocation in
                    if let index = locations.firstIndex(of: place){
                        locations[index] = newLocation
                    }
                }
            }
        }
    }
    /*func connectGlasses(){
        Glasses.runScan()
    }
    func sendDisplay(){
        Glasses.generateImageFromMap()
    }
    func stopTry(){
        Glasses.stopScanning()
    }*/
}


final class ContentViewModel: NSObject, ObservableObject, CLLocationManagerDelegate{
    
    @SwiftUI.State var Glasses = MapScreen()
    
    @Published var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude:37, longitude:-121), span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03))
    
    var locationManager = CLLocationManager()
    
    func ApplyState()->Location{
        let newRegion = Location(id: UUID(), name: "New Location", discription: "", latitude:region.center.latitude, longitude: region.center.longitude)
        return newRegion
        //ContentView.locations.append(newRegion)
    }
    func checkLocationAuthorization(){
        //guard let locationManager = locationManager else { return }
        
        switch locationManager.authorizationStatus{
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted:
            print("Allow user Location")
        case .denied:
            print("Allow user Location")
        case .authorizedAlways, .authorizedWhenInUse:
            region = MKCoordinateRegion(center:locationManager.location!.coordinate,span:MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03))
            locationManager.startUpdatingLocation()
        @unknown default:
            break
        }
    }
    
    func getCenterLocation(for mapview: MKMapView) -> CLLocation {
        let latitude = region.center.latitude
        let longitude = region.center.longitude
        return CLLocation(latitude: latitude, longitude: longitude)
    }
}


class MapScreen: UIViewController {
    let locationManager = CLLocationManager()
    let regionInMeters: Double = 10000
    var previousLocation: CLLocation?
    
    let geoCoder = CLGeocoder()
    var directionsArray: [MKDirections] = []
    
    // MARK: - Activelook init
    private let glassesName: String = "ENGO 2 090756"
    private var glassesConnected: Glasses?
    private let scanDuration: TimeInterval = 10.0
    private let connectionTimeoutDuration: TimeInterval = 5.0
    
    private var scanTimer: Timer?
    private var connectionTimer: Timer?
    
    private lazy var alookSDKToken: String = {
        guard let infoDictionary: [String: Any] = Bundle.main.infoDictionary else { return "" }
        guard let activelookSDKToken: String = infoDictionary["ACTIVELOOK_SDK_TOKEN"] as? String else { return "" }
        return activelookSDKToken
    }()
    
    private lazy var activeLook: ActiveLookSDK = {
        try! ActiveLookSDK.shared(
            token: alookSDKToken,
            onUpdateStartCallback: { SdkGlassesUpdate in
                print("onUpdateStartCallback")
            }, onUpdateAvailableCallback: { (SdkGlassesUpdate, _: () -> Void) in
                print("onUpdateAvailableCallback")
            }, onUpdateProgressCallback: { SdkGlassesUpdate in
                print("onUpdateProgressCallback")
            }, onUpdateSuccessCallback: { SdkGlassesUpdate in
                print("onUpdateSuccessCallback")
            }, onUpdateFailureCallback: { SdkGlassesUpdate in
                print("onUpdateFailureCallback")
            })
    }()
    
    
    private func startScanning() {
        activeLook.startScanning(
            onGlassesDiscovered: { [weak self] (discoveredGlasses: DiscoveredGlasses) in
                if discoveredGlasses.name == self!.glassesName{
                    discoveredGlasses.connect(
                        onGlassesConnected: { [weak self] (glasses: Glasses) in
                            guard let self = self else { return }
                            self.connectionTimer?.invalidate()
                            self.stopScanning()
                            self.glassesConnected = glasses
                            self.glassesConnected?.clear()
                        }, onGlassesDisconnected: { [weak self] in
                            guard let self = self else { return }
                            
                            let alert = UIAlertController(title: "Glasses disconnected", message: "Connection to glasses lost", preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
                                self.navigationController?.popToRootViewController(animated: true)
                            }))
                            
                            self.navigationController?.present(alert, animated: true)
                            
                        }, onConnectionError: { [weak self] (error: Error) in
                            guard let self = self else { return }
                            self.connectionTimer?.invalidate()
                            
                            let alert = UIAlertController(title: "Error", message: "Connection to glasses failed: \(error.localizedDescription)", preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                            self.present(alert, animated: true)
                        })
                }
            }, onScanError: { [weak self] (error: Error) in
                self?.stopScanning()
            }
        )
        
        scanTimer = Timer.scheduledTimer(withTimeInterval: scanDuration, repeats: false) { timer in
            self.stopScanning()
        }
    }
    
    private func stopScanning() {
        activeLook.stopScanning()
        scanTimer?.invalidate()
    }
    
    //Mark: - init
    override func viewDidLoad() {
        super.viewDidLoad()
        self.startScanning()
        goButton.layer.cornerRadius = goButton.frame.size.height/2
        checkLocationServices()
    }
    
    
    
    func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    
    func centerViewOnUserLocation() {
        if let location = locationManager.location?.coordinate {
            let region = MKCoordinateRegion.init(center: location, latitudinalMeters: regionInMeters, longitudinalMeters: regionInMeters)
            mapView.setRegion(region, animated: true)
        }
    }
    
    
    func checkLocationServices() {
        if CLLocationManager.locationServicesEnabled() {
            setupLocationManager()
            checkLocationAuthorization()
        } else {
            // Show alert letting the user know they have to turn this on.
        }
    }
    
    
    func checkLocationAuthorization() {
        switch CLLocationManager.authorizationStatus() {
        case .authorizedWhenInUse:
            startTackingUserLocation()
        case .denied:
            // Show alert instructing them how to turn on permissions
            break
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted:
            // Show an alert letting them know what's up
            break
        case .authorizedAlways:
            break
        @unknown default:
            break
        }
    }
    
    
    func startTackingUserLocation() {
        mapView.showsUserLocation = true
        centerViewOnUserLocation()
        locationManager.startUpdatingLocation()
        previousLocation = getCenterLocation(for: mapView)
    }
    
    
    func getCenterLocation(for mapView: MKMapView) -> CLLocation {
        let latitude = mapView.centerCoordinate.latitude
        let longitude = mapView.centerCoordinate.longitude
        
        return CLLocation(latitude: latitude, longitude: longitude)
    }
    
    
    func getDirections() {
        guard let location = locationManager.location?.coordinate else {
            //TODO: Inform user we don't have their current location
            return
        }
        
        let request = createDirectionsRequest(from: location)
        let directions = MKDirections(request: request)
        resetMapView(withNew: directions)
        
        directions.calculate { [unowned self] (response, error) in
            //TODO: Handle error if needed
            guard let response = response else { return } //TODO: Show response not available in an alert
            
            for route in response.routes {
                self.mapView.addOverlay(route.polyline)
                self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
            }
        }
    }
    
    
    func createDirectionsRequest(from coordinate: CLLocationCoordinate2D) -> MKDirections.Request {
        let destinationCoordinate       = getCenterLocation(for: mapView).coordinate
        let startingLocation            = MKPlacemark(coordinate: coordinate)
        let destination                 = MKPlacemark(coordinate: destinationCoordinate)
        
        let request                     = MKDirections.Request()
        request.source                  = MKMapItem(placemark: startingLocation)
        request.destination             = MKMapItem(placemark: destination)
        request.transportType           = .automobile
        request.requestsAlternateRoutes = true
        
        return request
    }
    
    
    func resetMapView(withNew directions: MKDirections) {
        mapView.removeOverlays(mapView.overlays)
        directionsArray.append(directions)
        let _ = directionsArray.map { $0.cancel() }
    }
    
    
    @IBAction func stopLens(_ sender: UIButton) {
        //startInterrupterLoop(isRunning: false)
    }
    @IBAction func updatetapped(_ sender: UIButton) {
        //startInterrupterLoop(isRunning: true)
    }
    @IBAction func goButtonTapped(_ sender: UIButton) {
        getDirections()
        generateImageFromMap()
    }
}


extension MapScreen: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        checkLocationAuthorization()
    }
}


extension MapScreen: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let center = getCenterLocation(for: mapView)
        
        guard let previousLocation = self.previousLocation else { return }
        
        guard center.distance(from: previousLocation) > 50 else { return }
        self.previousLocation = center
        
        geoCoder.cancelGeocode()
        
        geoCoder.reverseGeocodeLocation(center) { [weak self] (placemarks, error) in
            guard let self = self else { return }
            
            if let _ = error {
                //TODO: Show alert informing the user
                return
            }
            
            guard let placemark = placemarks?.first else {
                //TODO: Show alert informing the user
                return
            }
            
            let streetNumber = placemark.subThoroughfare ?? ""
            let streetName = placemark.thoroughfare ?? ""
            
            DispatchQueue.main.async {
                self.addressLabel.text = "\(streetNumber) \(streetName)"
            }
        }
    }
    
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay as! MKPolyline)
        renderer.strokeColor = .blue
        return renderer
    }
    
    // Start the interrupter loop
    /*func startInterrupterLoop(isRunning: Bool) {
        // Create a timer that will fire every 1 second
        let timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { timer in
            if isRunning == true {
                // Call the function
                self.generateImageFromMap()
            } else {
                // Stop the timer if the interrupter loop is no longer running
                timer.invalidate()
            }
        }

        // Add the timer to the run loop
        RunLoop.current.add(timer, forMode: .common)
    }*/
    
    private func generateImageFromMap() {
        let mapSnapshotterOptions = MKMapSnapshotter.Options()
        mapSnapshotterOptions.region = self.mapView.region
        mapSnapshotterOptions.size = CGSize(width: 200, height: 200)
        mapSnapshotterOptions.mapType = MKMapType.mutedStandard
        mapSnapshotterOptions.showsBuildings = false
        mapSnapshotterOptions.showsPointsOfInterest = false


        let snapShotter = MKMapSnapshotter(options: mapSnapshotterOptions)
        
        
        snapShotter.start() { snapshot, error in
            if let image = snapshot?.image{
                self.glassesConnected?.imgStream(image: image, x: 0, y: 0, imgStreamFmt: .MONO_4BPP_HEATSHRINK)
            }else{
                print("Missing snapshot")
            }
        }
    
    }
}




struct Marker : Hashable{
    let degrees: Double
    let label: String
    
    init(degrees: Double, label: String="") {
        self.degrees = degrees
        self.label = label
    }
    
    func degreeText() -> String{
        return String(format: "%.0f", self.degrees)
    }
    
    static func markers()-> [Marker]{
        return [
            Marker(degrees: 0, label: "S"),
            Marker(degrees: 30),
            Marker(degrees: 60),
            Marker(degrees: 90, label: "W"),
            Marker(degrees: 120),
            Marker(degrees: 150),
            Marker(degrees: 180, label: "N"),
            Marker(degrees: 210),
            Marker(degrees: 240),
            Marker(degrees: 270, label: "E"),
            Marker(degrees: 300),
            Marker(degrees: 330)
        ]
    }
}

struct CompassMarkerView : View{
    let marker: Marker
    let compassDegrees: Double
    
    var body: some View{
        VStack{
            Text(marker.degreeText())
                .fontWeight(.light)
                .rotationEffect(self.textAngle())
            Capsule()
                .frame(width:1,height:10)
                //.frame(width: self.capsuleWidth(),height: self.capsuleHeight())
                .padding(.bottom,50)
            Text(marker.label)
                .fontWeight(.bold)
                .rotationEffect(self.textAngle())
                .padding(.bottom,50)
        }
        .fixedSize()
        .rotationEffect(Angle(degrees: marker.degrees))
    }
    private func capsuleWidth() -> CGFloat{
        return self.marker.degrees == 0 ? 7 : 3
    }
    private func capsuleHeight() -> CGFloat {
        return self.marker.degrees == 0 ? 45 : 30
    }
    private func capsuleColor() -> Color{
        return self.marker.degrees == 0 ? .red : .gray
    }
    private func textAngle() -> Angle{
        return Angle(degrees: -self.compassDegrees - self.marker.degrees)
    }
}
