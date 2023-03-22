import SwiftUI
import SwiftUIPolygonGeofence
import CoreLocation
import CoreLocationUI
import MapKit
import ActiveLookSDK

struct TestView: View{
    @ObservedObject var compassHeading = CompassHeading()

    var textView1: some View {
            Text("Hello, SwiftUI")
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .clipShape(Capsule())
        }
    var body: some View {
            ZStack {
                VStack(spacing: 100) {
                    textView
                }
            }
        }
    var textView: some View{
        ZStack{
            ForEach(Marker.markers(), id:\.self) {marker in
                CompassMarkerView(marker: marker, compassDegrees: self.compassHeading.degrees)
            }
        }
        .frame(width: 150, height: 150)
        .rotationEffect(Angle(degrees: self.compassHeading.degrees))
        .statusBar(hidden:true)    }
}

struct ContentView: View {
    @ObservedObject var compassHeading = CompassHeading()
    @StateObject public var viewModel = ContentViewModel()

    @SwiftUI.State var Glasses = MapScreen()
    @SwiftUI.State var locations = [Location]()

    @SwiftUI.State private var selectedPlace: Location?
    @SwiftUI.State var timer: Timer?
    
    @SwiftUI.State var zoomForMap: Double = 0.002
    //var zoomForMap = 0.002
    //let geoFence = SwiftUIPolygonGeofence
    //var activeLook: ActiveLookSDK
        
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
                Spacer()
                VStack{
                    Button(action: connectGlasses) {
                        Image(systemName: "eyeglasses")
                        .frame(width: 50, height:30)
                    }
                    .foregroundColor(.white)
                    .background(.black.opacity(0.5))
                    Button(action: sendDisplay) {
                        Image(systemName: "mappin.circle.fill")
                        .frame(width: 50, height:30)
                    }
                    Button(action: returnDegree){
                        Image(systemName: "location.north.circle")
                        .frame(width: 50, height:30)
                    }
                    Button(action: both){
                        Image(systemName: "person.2.circle.fill")
                        .frame(width: 50, height:30)
                    }
                    Button(action: stopTimer){
                        Image(systemName: "stop.circle")
                        .frame(width: 50, height:30)
                    }
                    Button(action: plus){
                        Image(systemName: "plus.app.fill")
                        .frame(width: 50, height:30)
                    }
                    Button(action: minus){
                        Image(systemName: "minus.square.fill")
                        .frame(width: 50, height:30)
                    }
                    Button(action: Clear){
                        Image(systemName: "clear.fill")
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
    func connectGlasses(){
        Glasses.startScanning()
    }
    func Clear(){
        Glasses.clearMap()
    }
    func disconnect(){
        //Glasses.glassesConnected?.disconnect()
    }
    func sendDisplay(){
        stopTimer()
        Glasses.clearMap()
        self.timer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { _ in
            print("rep")
            Glasses.threeTimer(zoom: zoomForMap)
        }
    }
    func returnDegree(){
        stopTimer()
        Glasses.clearMap()
        self.timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            print("repeat")
            let compassDeg = Int(-1*self.compassHeading.degrees)
            Glasses.oneTimer(deg: compassDeg)
        }
    }
    func both(){
        stopTimer()
        Glasses.clearMap()
        self.timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { _ in
            print("repBof")
            let compassDeg = Int(-1*self.compassHeading.degrees)
            Glasses.bothRuns(zoom: zoomForMap, deg: compassDeg)
        }
    }
    func stopTimer(){
        self.timer?.invalidate()
        self.timer = nil
    }
    func plus(){
        zoomForMap = zoomForMap - 0.001
    }
    func minus(){
        zoomForMap = zoomForMap + 0.001
    }
    /*
    func stopTry(){
        Glasses.stopScanning()
    }*/
}


final class ContentViewModel: NSObject, ObservableObject, CLLocationManagerDelegate{
    
    var locationManager = CLLocationManager()
    
    @Published var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude:37, longitude:-121), span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03))
    
    
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
            region = MKCoordinateRegion(center:locationManager.location!.coordinate,span:MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02))
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
    
    @SwiftUI.State var capture: UIImage?
    
    var timer: Timer?

    var viewModel = CLLocationManager()

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
    
    func startScanning() {
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
                            //try to display to glasses from here?
                            //glasses.line(x0: 102, x1: 202, y0: 128, y1: 128)
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
        //goButton.layer.cornerRadius = goButton.frame.size.height/2
    }
}


extension MapScreen: MKMapViewDelegate {
    
    func oneTimer(deg: Int){
        //self.glassesConnected?.clear()
        let compass = String(deg)
        
        let counter = compass.count
        
        if (counter==1){
            let ncompass="00"+compass
            self.glassesConnected?.txt(x: 102, y: 128, rotation: .topLR, font: 2, color: 15, string: ncompass)

        }
        else if(counter==2){
            let ncompass = "0"+compass
            self.glassesConnected?.txt(x: 102, y: 128, rotation: .topLR, font: 2, color: 15, string: ncompass)

        }
        else if(counter==3){
            self.glassesConnected?.txt(x: 102, y: 128, rotation: .topLR, font: 2, color: 15, string: compass)
        }
        else {
            print("size error")
        }
        //self.glassesConnected?.txt(x: 102, y: 128, rotation: .bottomRL, font: 2, color: 15, string: compass)
//        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { _ in
//            let compass = String(deg)
//            self.glassesConnected?.txt(x: 102, y: 128, rotation: .bottomRL, font: 2, color: 15, string: compass)
//        })
    }
    
    func clearMap(){
        self.glassesConnected?.clear()
    }
    
    func threeTimer(zoom: Double){
        generateImageFromMap(zoom: zoom)
    }
    func bothRuns(zoom: Double, deg: Int){
        generateImageFromMap(zoom: zoom)
        oneTimer(deg: deg)
    }
    
    func generateImageFromMap(zoom: Double) {
        
        var imageWithMarker: UIImage?
        
        let mapSnapshotterOptions = MKMapSnapshotter.Options()
        mapSnapshotterOptions.size = CGSize(width: 140, height: 140)
        mapSnapshotterOptions.region = MKCoordinateRegion(center:locationManager.location!.coordinate,span:MKCoordinateSpan(latitudeDelta: zoom, longitudeDelta: zoom))
        mapSnapshotterOptions.mapType = .mutedStandard
        mapSnapshotterOptions.showsBuildings = true

        //mapSnapshotterOptions.showP = false
        
        
        let snapShotter = MKMapSnapshotter(options: mapSnapshotterOptions)
        
        snapShotter.start() { [self] snapshot, error in
            if let image = snapshot?.image{
                print("took screenshot")
                
                
                let markerImage = UIImage(systemName: "dot.circle") // Replace with your marker image
                let markerPoint = snapshot?.point(for: locationManager.location!.coordinate)
                imageWithMarker = addMarkerImage(markerImage, to: image, at: markerPoint!)
                
                self.glassesConnected?.imgStream(image: imageWithMarker!, x: 0, y: 0, imgStreamFmt: .MONO_4BPP_HEATSHRINK)
                
            }else{
                print("Missing snapshot")
            }
        }
    }
    

    func addMarkerImage(_ markerImage: UIImage?, to image: UIImage, at point: CGPoint) -> UIImage? {
        guard let markerImage = markerImage else {
            print("markerImage is nil")
            return nil
        }
        guard let cgImage = image.cgImage else {
            print("Failed to get cgImage from image")
            return nil
        }

        let imageSize = CGSize(width: 140, height: 140)
        UIGraphicsBeginImageContextWithOptions(imageSize, false, 0.0)
        guard let context = UIGraphicsGetCurrentContext() else {
            print("Failed to get image context")
            return nil
        }
        // Adjust the coordinate system to match UIKit's coordinate system
        context.translateBy(x: 0, y: imageSize.height)
        context.scaleBy(x: 1, y: -1)

        context.draw(cgImage, in: CGRect(origin: .zero, size: imageSize))
        
        let markerSize = CGSize(width: 10, height: 10)
        //let markerOrigin = CGPoint(x: point.x - markerSize.width / 2, y: point.y - markerSize.height / 2)
        let markerOrigin = CGPoint(x: (140/2)-5 , y: (140/2)-5 )
        let markerRect = CGRect(origin: markerOrigin, size: markerSize)

        markerImage.draw(in: markerRect)

        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage
    }
}


struct Marker : Hashable{
    let degrees: Double
    let label: String
    
    init(degrees: Double, label: String="") {
        self.degrees = degrees
        self.label = label
    }
    
    public func getDegree() -> Double{
        return self.degrees
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
