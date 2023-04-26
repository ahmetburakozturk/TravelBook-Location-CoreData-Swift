//
//  ViewController.swift
//  TravelBookProject
//
//  Created by ahmetburakozturk on 23.04.2023.
//

import UIKit
import CoreData

class ViewController: UIViewController, UITableViewDelegate,UITableViewDataSource {

    @IBOutlet weak var myTableView: UITableView!
    
    var nameArray = [String]()
    var choosenItemName = ""
    var choosenItemId = UUID()
    var idArray = [UUID]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        myTableView.delegate = self
        myTableView.dataSource = self
        
        getData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(getData), name: NSNotification.Name("newDataAdded"), object: nil)
    }

    @objc func getData(){
        nameArray.removeAll()
        idArray.removeAll()
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Location")
        fetchRequest.returnsObjectsAsFaults = false
        do{
            let results = try context.fetch(fetchRequest)
            if results.count > 0{
                for result in results as! [NSManagedObject]{
                    if let name = result.value(forKey: "title") as? String{
                        self.nameArray.append(name)
                    }
                    if let id = result.value(forKey: "id") as? UUID{
                        self.idArray.append(id)
                    }
                }
                myTableView.reloadData()
            }
        }catch{
            print("fetch error!")
        }
        
    }
    

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return nameArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        var content = cell.defaultContentConfiguration()
        content.text = nameArray[indexPath.row]
        cell.contentConfiguration = content
        return cell
    }
    
    @IBAction func addButtonClicked(_ sender: Any) {
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        choosenItemName = nameArray[indexPath.row]
        choosenItemId = idArray[indexPath.row]
        performSegue(withIdentifier: "toMapViewController", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toMapViewController"{
            let destinationVC = segue.destination as! MapViewController
            destinationVC.selectedText = choosenItemName
            destinationVC.selectedId = choosenItemId
        }
    }
}

