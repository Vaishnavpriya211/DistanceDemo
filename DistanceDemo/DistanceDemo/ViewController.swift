//
//  ViewController.swift
//  DistanceDemo
//
//  Created by Shubham Bairagi on 13/06/22.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet var tableView: UITableView!
    
    var secionalDataSource = [(title: String, data: [Double])]()
    
    let inputArray: [Double] = [2.65, 3.56, 1.27, 0,54, 2.35, -3.65, -4.45, -0.53, 0.24, 7.8, 9.2]

    override func viewDidLoad() {
        super.viewDidLoad()

        self.secionalDataSource = self.processSectionalData(withInput: inputArray)
        self.tableView.reloadData()
    }
    
    
    func processSectionalData(withInput array: [Double]) -> [(String, [Double])] {
        var output = [(String, [Double])]()

        guard !array.isEmpty else {
            return output
        }
        let sortedInput = array.sorted(by: { $0 < $1 })
        
        let positiveValues = sortedInput.filter({ $0 > 0 })
        
        if !positiveValues.isEmpty {
            if let nearest = positiveValues.first {
                let firstSection = ("Nearest Store", [nearest])
                output.append(firstSection)
            }
            
            let posCount = positiveValues.count
            
            if posCount > 1 {
                let remainingValues = Array(positiveValues[1..<posCount])
                let secondSection = ("Other Store", remainingValues)
                output.append(secondSection)
            }
        }
        
        let negetiveValues = sortedInput.filter({ $0 < 0 })

        if !negetiveValues.isEmpty {
            let thirdSection = ("Unavailable Store", negetiveValues)
            output.append(thirdSection)
        }
        return output
    }
}

extension ViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return secionalDataSource.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return secionalDataSource[section].data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TablViewCell", for: indexPath) as! TablViewCell
        
        let data = secionalDataSource[indexPath.section].data[indexPath.item]
        cell.lblTitle.text = String(data)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return secionalDataSource[section].title
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 34
    }
}


