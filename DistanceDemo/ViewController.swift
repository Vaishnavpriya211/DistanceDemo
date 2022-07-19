//
//  IterateBeaconFwViewController.swift
//  IterateBeaconFw
//
//  Created by Ajmerainfotech on 30/06/22.
//

import UIKit
import CoreLocation
#if canImport(FoundationNetworking)
import FoundationNetworking
import Iterate_BeaconTests
#endif

public class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, CLLocationManagerDelegate {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var imageError: UIImageView!
    @IBOutlet weak var labelError: UILabel!
    @IBOutlet weak var labelAddNewText: UILabel!
    
    var locationManager: CLLocationManager?;
    
    var registeredDeviceModels: Array<DeviceModel> = [DeviceModel]();
    var scannedBeaconModels: Array<BeaconDataModel> = [BeaconDataModel]();
    var tableViewSectionalData = [(title: String, data: [BeaconDataModel])]();
    
    let sectionHeaderTitleSize: CGFloat = 24;
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.locationManager = CLLocationManager();
        self.locationManager?.delegate = self;
        self.locationManager?.requestAlwaysAuthorization();
        
        self.tableView.delegate = self;
        self.tableView.dataSource = self;
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        
        let nib = UINib(nibName: Constants.TABLE_VIEW_NIB_NAME, bundle: Bundle(identifier: Constants.FRAMEWORK_PACKAGE_ID));
        tableView.register(nib, forCellReuseIdentifier: Constants.TABLE_VIEW_NIB_NAME)
        
        setLabelErrorText(labelText: Constants.SEARCHING_BEACON)
        
        getDevices();
    }
    
    @IBAction func btnAddclicked(_ sender: UIButton) {
        let viewController = (self.storyboard?.instantiateViewController(withIdentifier: Constants.FRAMEWORK_ADD_DEVICE_VIEW_CONTROLLER));
        DispatchQueue.main.async {
            self.present(viewController!, animated: true, completion: nil);
        }
    }
    
    private func didUpdate(clBeacons: [CLBeacon]) {
        for item in clBeacons {
            updateBeaconsValues(item);
        }
    }
    
    private func updateBeaconsValues(_ beacon: CLBeacon) {
        
        if let index = scannedBeaconModels.index(where: {$0.minorValue == Int(truncating: beacon.minor)}) {
            scannedBeaconModels[index] = updatedBeaconData(index: index, beacon: beacon)
        } else {
            if let deviceIndex = self.registeredDeviceModels.firstIndex(where: {$0.minorValue == Int(truncating: beacon.minor)}) {
                scannedBeaconModels.append(createBeaconData(index: deviceIndex, beacon: beacon))
            }
        }
        
        tableViewSectionalData = processSectionalData(withInput: scannedBeaconModels)
        tableView.reloadData()
    }
    
    private func createBeaconData(index: Int, beacon: CLBeacon) -> BeaconDataModel {
        let model = registeredDeviceModels[index];
        
        let beaconDataModel = BeaconDataModel();
        beaconDataModel.id = model.id;
        beaconDataModel.name = model.name;
        beaconDataModel.uuid = model.uuid;
        beaconDataModel.storeID = model.storeID;
        beaconDataModel.deviceDistance = Float(beacon.accuracy);
        beaconDataModel.proximityValue = getProximityValue(proximity: beacon.proximity);
        beaconDataModel.rssiValue = "\(beacon.rssi)";
        beaconDataModel.majorValue = Int(truncating: beacon.major);
        beaconDataModel.minorValue = Int(truncating: beacon.minor);
        beaconDataModel.dataDevice = String(describing: Data());
        
        return beaconDataModel;
    }
    
    private func updatedBeaconData(index: Int, beacon: CLBeacon) -> BeaconDataModel {
        let model = scannedBeaconModels[index];
        
        let beaconDataModel = BeaconDataModel();
        beaconDataModel.id = model.id;
        beaconDataModel.name = model.name;
        beaconDataModel.uuid = model.uuid;
        beaconDataModel.storeID = model.storeID;
        beaconDataModel.proximityValue = getProximityValue(proximity: beacon.proximity)
        beaconDataModel.rssiValue = "\(beacon.rssi)";
        beaconDataModel.majorValue = model.majorValue;
        beaconDataModel.minorValue = model.minorValue;
        beaconDataModel.dataDevice = String(describing: Date());
        beaconDataModel.disconnectedCount = model.disconnectedCount

        if model.deviceDistance >= 0 {
            if beacon.accuracy < 0 {
                beaconDataModel.disconnectedCount = beaconDataModel.disconnectedCount + 1
                beaconDataModel.deviceDistance = model.deviceDistance
                print("Count decreasing:  \(beaconDataModel.disconnectedCount)")
                
                if beaconDataModel.disconnectedCount >= 3 {
                    beaconDataModel.disconnectedCount = 0
                    beaconDataModel.deviceDistance = Float(beacon.accuracy);
                }
            } else {
                beaconDataModel.disconnectedCount = 0
                beaconDataModel.deviceDistance = Float(beacon.accuracy);
            }
        } else {
            beaconDataModel.deviceDistance = Float(beacon.accuracy)
        }
        
        return beaconDataModel;
    }
    
    private func getProximityValue(proximity: CLProximity) -> String {
        var proximityValue: String = ""
        switch proximity {
        case .unknown:
            proximityValue = Constants.UNKNOWN_PROXIMITY;
        case .far:
            proximityValue = Constants.FAR_PROXIMITY;
        case .near:
            proximityValue = Constants.NEAR_PROXIMITY;
        case .immediate:
            proximityValue = Constants.IMMEDIATE_PROXIMITY;
        @unknown default:
            proximityValue = Constants.UNKNOWN_PROXIMITY;
        }
        return proximityValue;
    }
    
    private func getDevices() {
        let serverApi: ServerApi = ServerApi.getSharedInstance();
        serverApi.getDevices(completion: { (data) -> Void in
            self.registeredDeviceModels = data;
            //            for item in self.registeredDeviceModels {
            //                if item.disconnectedDevices < 0 {
            //                    item.disconnectedDevices+1
            //                }
            
        })
        
        if self.registeredDeviceModels.count > 0 {
            DispatchQueue.main.async {
                self.setupBeacons();
            }
        } else {
            DispatchQueue.main.async { [self] in
                self.setLabelErrorText(labelText: Constants.NO_BEACON_AVAILABLE)
                showHideErrorUI(isHidenValue: false);
            }
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            self.setLabelErrorText(labelText: Constants.SEARCHING_BEACON)
        } else {
            setLabelErrorText(labelText: Constants.ALLOW_PERMISSION)
            showHideErrorUI(isHidenValue: false);
        }
    }
    
    private func setupBeacons() {
        for item in self.registeredDeviceModels {
            let beaconRegion = CLBeaconRegion(proximityUUID: UUID(uuidString: item.uuid)!, major: CLBeaconMajorValue(item.majorValue), minor: CLBeaconMinorValue(item.minorValue), identifier: item.name);
            beaconRegion.notifyEntryStateOnDisplay = true;
            
            locationManager?.startMonitoring(for: beaconRegion);
            locationManager?.startRangingBeacons(satisfying: beaconRegion.beaconIdentityConstraint);
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        if beacons.count > 0 {
            didUpdate(clBeacons: beacons);
            showHideErrorUI(isHidenValue: true);
        } else if scannedBeaconModels.count == 0 {
            setLabelErrorText(labelText: Constants.NO_BEACON_AVAILABLE)
            showHideErrorUI(isHidenValue: false);
        }
    }
    
    private func showHideErrorUI(isHidenValue: Bool) {
        self.imageError.isHidden = isHidenValue;
        self.labelError.isHidden = isHidenValue;
        self.labelAddNewText.isHidden = isHidenValue;
    }
    
    private func setLabelErrorText(labelText: String) {
        self.labelError.text = labelText;
    }
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return tableViewSectionalData.count;
    }
    
    public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return tableViewSectionalData[section].title;
    }
    
    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return sectionHeaderTitleSize;
    }
    
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableViewSectionalData[section].data.count;
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.TABLE_VIEW_NIB_NAME, for: indexPath) as! BeaconListTableViewCell
        
        let sectionalData = tableViewSectionalData[indexPath.section].data[indexPath.item];
        
        cell.lblUUID.text = sectionalData.uuid
        cell.lblStoreName.text = "\(sectionalData.storeID ?? 0)";
        cell.lblPumpName.text = sectionalData.name
        cell.lblMajorValue.text = "\(sectionalData.majorValue ?? 0)";
        cell.lblMinorValue.text = "\(sectionalData.minorValue ?? 0)";
        cell.lblLastUpdatedTime.text = sectionalData.dataDevice;
        cell.lblAccuracy.text = sectionalData.proximityValue
        cell.lblDistance.text = String(format: "%.2f", sectionalData.deviceDistance)
        
        cell.view.backgroundColor = getColorBySectionTitle(indexSection: indexPath.section);
        return cell;
    }
    
    private func getColorBySectionTitle(indexSection: Int) -> UIColor {
        let sectionDataTitle = tableViewSectionalData[indexSection].title
        
        if sectionDataTitle == Constants.SECTION_NEAREST_DEVICE {
            return .systemGreen
        } else if sectionDataTitle == Constants.SECTION_CONNECTED_DEVICE {
            return .systemBlue
        } else {
            return .systemRed
        }
    }
    
    private func processSectionalData(withInput beaconData : [BeaconDataModel]) -> [(String, [BeaconDataModel])] {
        var output = [(String, [BeaconDataModel])]()
        guard !beaconData.isEmpty else{
            return output
        }
        
        let sortedInput = beaconData.sorted(by: {$0.deviceDistance < $1.deviceDistance})
        
        let positiveValues = sortedInput.filter({ $0.deviceDistance >= 0 })
        
        if !positiveValues.isEmpty {
            if let nearestBeaconData = positiveValues.first {
                let firstSection = (Constants.SECTION_NEAREST_DEVICE, [nearestBeaconData])
                output.append(firstSection)
            }
            
            let posCount = positiveValues.count
            
            if posCount > 1 {
                let remainingValues = Array(positiveValues[1..<posCount])
                let secondSection = (Constants.SECTION_CONNECTED_DEVICE, remainingValues)
                output.append(secondSection)
            }
        }
        
        let negetiveValues = sortedInput.filter({ $0.deviceDistance < 0 })
        
        if !negetiveValues.isEmpty {
            let thirdSection = (Constants.SECTION_OUT_OF_RANGE, negetiveValues)
            output.append(thirdSection)
        }
        
        return output
    }
    
}
