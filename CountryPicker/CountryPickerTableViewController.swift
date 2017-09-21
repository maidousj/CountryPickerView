//
//  CountryPickerTableViewController.swift
//  CountryPicker
//
//  Created by Kizito Nwose on 18/09/2017.
//  Copyright © 2017 Kizito Nwose. All rights reserved.
//

import UIKit

class CountryPickerTableViewController: UITableViewController {
    
    fileprivate var searchController: UISearchController!
    fileprivate var searchResults = [Country]()
    fileprivate var isSearchMode = false
    fileprivate var sectionsTitles = [String]()
    fileprivate var countries = [String: [Country]]()
    fileprivate var hasPreferredSection: Bool {
        return countryPickerView.preferredCountries().count > 0
    }
    
    weak var countryPickerView: CountryPickerView! {
        didSet { prepareTableItems() }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print(sectionsTitles)
        prepareNavItem()
        prepareSearchBar()
    }
   
}


// UI Setup
extension CountryPickerTableViewController {
    
    func prepareTableItems()  {
        let countriesArray = countryPickerView.countries
        
        var header = Set<String>()
        countriesArray.forEach{
            let name = $0.name
            header.insert(String(name[name.startIndex]))
        }
        
        var data = [String: [Country]]()
        
        countriesArray.forEach({
            let name = $0.name
            let index = String(name[name.startIndex])
            var dictValue = data[index] ?? [Country]()
            dictValue.append($0)
            
            data[index] = dictValue
        })
        
        // Sort the sections
        data.forEach{ key, value in
            data[key] = value.sorted(by: { (lhs, rhs) -> Bool in
                return lhs.name < rhs.name
            })
        }
        
        sectionsTitles = header.sorted()
        countries = data
        if let preferredTitle = countryPickerView.preferredCountriesSectionTitle(),
            countryPickerView.preferredCountries().count > 0 {
            sectionsTitles.insert(preferredTitle, at: sectionsTitles.startIndex)
            countries[preferredTitle] = countryPickerView.preferredCountries()
        }
        
        tableView.sectionIndexBackgroundColor = .clear
        tableView.sectionIndexTrackingBackgroundColor = .clear
    }
    
    func prepareNavItem() {
        let closeButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(close))
        navigationItem.rightBarButtonItem = closeButton
        navigationItem.title = countryPickerView.navigationTitle()
    }
    
    func prepareSearchBar() {
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.delegate = self
        searchController.dimsBackgroundDuringPresentation = false
        tableView.tableHeaderView = searchController.searchBar
    }
    
    @objc private func close() {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
}


//MARK:- UITableViewDataSource
extension CountryPickerTableViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return isSearchMode ? 1 : sectionsTitles.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isSearchMode ? searchResults.count : countries[sectionsTitles[section]]!.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")
            ?? UITableViewCell(style: .default, reuseIdentifier: "cell")
        let country = isSearchMode ? searchResults[indexPath.row] : countries[sectionsTitles[indexPath.section]]![indexPath.row]
        
        cell.imageView?.image = country.flag
        cell.textLabel?.text = country.name
        cell.accessoryType = country == countryPickerView.selectedCountry ? .checkmark : .none
        cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return isSearchMode ? nil : sectionsTitles[section]
    }
    
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        if isSearchMode {
            return nil
        } else {
            if hasPreferredSection {
                return Array<String>(sectionsTitles.dropFirst())
            }
            return sectionsTitles
        }
    }
    
    override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return sectionsTitles.index(of: title)!
    }
}


//MARK:- UITableViewDelegate
extension CountryPickerTableViewController {

    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let header = view as? UITableViewHeaderFooterView {
            header.textLabel?.font = UIFont.boldSystemFont(ofSize: 17)
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let country = isSearchMode ? searchResults[indexPath.row] : countries[sectionsTitles[indexPath.section]]![indexPath.row]
        countryPickerView.didSelectCountry(country)
        searchController.dismiss(animated: true, completion: nil)
        dismiss(animated: true, completion: nil)
    }
}


// MARK:- UISearchResultsUpdating
extension CountryPickerTableViewController: UISearchResultsUpdating {
    public func updateSearchResults(for searchController: UISearchController) {
        searchResults.removeAll()
        if let text = searchController.searchBar.text, text.characters.count > 0,
            let indexArray = countries[String(text[text.startIndex])] {
            searchResults.append(contentsOf: indexArray.filter({ $0.name.hasPrefix(text) }))
        }
        tableView.reloadData()
    }
}

// MARK:- UISearchControllerDelegate
extension CountryPickerTableViewController: UISearchControllerDelegate {
    public func didPresentSearchController(_ searchController: UISearchController) {
        isSearchMode = true
    }
    
    public func willDismissSearchController(_ searchController: UISearchController) {
        isSearchMode = false
    }
}
