//
//  Connections.swift
//  SwifuiTest
//
//  Created by maahika gupta on 1/10/23.
//

import Foundation
import ActiveLookSDK
import SwiftUI

struct Connections: View{
    
    @SwiftUI.State private var viewModel = GlassesTableViewController()
    
    var body: some View {//FIX THIS SHIT
        NavigationView{
            VStack{
                Text("Scanning...")
                Button("Scan", action: viewModel.runScan)
            }//.navigationBarTitle("")
               // .navigationBarHidden(true)
        }
    }
}

class GlassesTableViewController: UITableViewController {
    
    
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
    
    activeLook.startScanning(
        onGlassesDiscovered: { [weak self] (discoveredGlasses: DiscoveredGlasses) in
            print("discovered glasses: \(discoveredGlasses.name)")
            self?.addDiscoveredGlasses(discoveredGlasses)

        }, onScanError: { (error: Error) in
            print("error while scanning: \(error.localizedDescription)")
        }
    )
    
    private var discoveredGlassesArray: [DiscoveredGlasses] = []
    private var connecting: Bool = false
    
    override func viewDidDisappear(_ animated: Bool) {
            activeLook.stopScanning()
            super.viewDidDisappear(animated)
    }
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return discoveredGlassesArray.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GlassesTableViewCell", for: indexPath) as UITableViewCell
        cell.textLabel?.text = discoveredGlassesArray[indexPath.row].name
        return cell
    }
        
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if connecting { return }
        connecting = true

        let selectedGlasses = discoveredGlassesArray[indexPath.row]

        selectedGlasses.connect(
            onGlassesConnected: { [weak self] (glasses: Glasses) in
                guard let self = self else { return }
                
                self.connecting = false
                self.connectionTimer?.invalidate()
                if (glasses.isFirmwareAtLeast(version: "4.0")) {
//                    (glasses.compareFirmwareAtLeast(version: "4.0").rawValue > 0) {
//                        let alert = UIAlertController(title: "Update application", message: "The glasses firmware is newer. Check the store for an application update.", preferredStyle: .alert)
//                        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
//                        self.present(alert, animated: true)
//                         } else {
                    
                    // TO UPLOAD CONFIG, ADD YOUR CONFIG.TXT FILE TO THE PROJECT,
                    // THEN UNCOMMENT THE FOLLOWING BLOCK /*...*/
                    // AND FINALLY REPLACE THE RESSOURCE NAME WITH YOUR CONFIG'S NAME
/*                         if let filePath = Bundle.main.path(forResource: "ConfigDemo-4.0.txt", ofType: "txt") {
                             do {
                                 let cfg = try String(contentsOfFile: filePath)
                                 glasses.loadConfiguration(cfg: cfg.components(separatedBy: "\n"))
                             } catch {}
*/
                    
//                         }
//                    }
                    //let viewController = CommandsMenuTableViewController(glasses)
                    //self.navigationController?.pushViewController(viewController, animated: true)
                } else {
                    let alert = UIAlertController(title: "Update glasses firmware", message: "The glasses firmware is not up to date.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                    self.present(alert, animated: true)
                }
            }, onGlassesDisconnected: { [weak self] in
                guard let self = self else { return }
                
                let alert = UIAlertController(title: "Glasses disconnected", message: "Connection to glasses lost", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
                    self.navigationController?.popToRootViewController(animated: true)
                }))
                
                self.navigationController?.present(alert, animated: true)
                
            }, onConnectionError: { [weak self] (error: Error) in
                guard let self = self else { return }
                
                self.connecting = false
                self.connectionTimer?.invalidate()
                
                let alert = UIAlertController(title: "Error", message: "Connection to glasses failed: \(error.localizedDescription)", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true)
            })

        connectionTimer = Timer.scheduledTimer(withTimeInterval: connectionTimeoutDuration, repeats: false, block: { [weak self] (timer) in
            guard let self = self else { return }

            print("connection to glasses timed out")
            self.connecting = false

            let alert = UIAlertController(title: "Error", message: "The connection to the glasses timed out", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true)
            
            self.tableView.deselectRow(at: indexPath, animated: true)
        })
    }
    
    
    // MARK: - Data
    
    private func addDiscoveredGlasses(_ glasses: DiscoveredGlasses) {
        discoveredGlassesArray.append(glasses)
        // TODO: // Use -performBatchUpdates:completion: instead of these methods, which will be deprecated in a future release. (introduced iOS 11)
        tableView.beginUpdates()
        tableView.insertRows(at: [IndexPath(row: self.discoveredGlassesArray.count - 1, section: 0)], with: .automatic)
        tableView.endUpdates()
    }
    

    // MARK: - Scan
    
    private func startScanning() {
        //scanNavigationItem.title = "Stop"

        self.discoveredGlassesArray = []
        self.tableView.reloadData()
        
        activeLook.startScanning(
            onGlassesDiscovered: { [weak self] (discoveredGlasses: DiscoveredGlasses) in
                self?.addDiscoveredGlasses(discoveredGlasses)

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
        //scanNavigationItem.title = "Scan"
        scanTimer?.invalidate()
    }
    func runScan(){
        activeLook.isScanning() ? stopScanning() : startScanning()
    }
    
    
}
