//
//  ViewController.swift
//  RepoOwners
//
//  Created by Joshua Park on 10/12/2017.
//  Copyright © 2017 Joshua Park. All rights reserved.
//

import UIKit
import KRClient
import EdgeJSON

class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UISearchControllerDelegate {
    
    private struct Constant {
        static let cellID = "RepoOwnerCell"
    }
    
    private let searchController = UISearchController(searchResultsController: nil)
    private weak var collectionView: UICollectionView!
    
    private var ownerList = [RepoOwner]()
    private var names = Set<String>()
    private var nextRepoID: Int? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        
        fetchList()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Search bar
    
    // MARK: - Collection view
    
    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int
    {
        return ownerList.count
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Constant.cellID,
                                                      for: indexPath) as! RepoOwnerCell
        
        return cell
    }

    // MARK: - Private
    
    private func setSubViews() {
        setUpCollectionView()
        
        view.addSubview(searchController.searchBar)
        
        let idCollectionView = "collectionView"
        let idSearchBar = "searchBar"
        
        let dicViews: [String: Any] = [
            idCollectionView: collectionView,
            idSearchBar: searchController.searchBar,
        ]
        
        let constraints =
            NSLayoutConstraint.constraints(withVisualFormat: "H:|[\(idCollectionView)]|",
                                       options: [],
                                       metrics: nil,
                                       views: dicViews) +
            NSLayoutConstraint.constraints(withVisualFormat: "V:|[\(idCollectionView)]|",
                                           options: [],
                                           metrics: nil,
                                           views: dicViews) +
            NSLayoutConstraint.constraints(withVisualFormat: "H:|[\(idSearchBar)]|",
                                           options: [],
                                           metrics: nil,
                                           views: dicViews) +
            NSLayoutConstraint.constraints(withVisualFormat: "V:|[\(idSearchBar)]",
                                           options: [],
                                           metrics: nil,
                                           views: dicViews)
        
        NSLayoutConstraint.activate(constraints)
    }
    
    private func setUpCollectionView() {
        let collectionView = UICollectionView()
        collectionView.collectionViewLayout = UICollectionViewFlowLayout()
        
        view.addSubview(collectionView)
        self.collectionView = collectionView
        
        collectionView.register(RepoOwnerCell.self,
                                forCellWithReuseIdentifier: Constant.cellID)
    }
    
    private func fetchList() {
        let urlString = "https://api.github.com/repositories"
        let parameters: [String: Any]? = {
            if let id = nextRepoID {
                return ["since": id]
            }
            return nil
        }()
        
        let req = try! Request(method: .GET,
                               urlString: urlString,
                               parameters: parameters)
            .data {
                guard let obj = try? JSONSerialization
                    .jsonObject(with: $0, options: []) else { return }
                guard let list = obj as? [[String: Any]] else { return }
                
                self.makeList(from: list)
                
            }
            .failure {
                print($0, $1)
            }

        KRClient.shared.make(httpRequest: req)
        
    }
    
    private func makeList(from rawList: [[String: Any]]) {
        for dictionary in rawList {
            let owner = dictionary.dic("owner")!
            let url = owner.str("avatar_url")!
            let name = dictionary.str("name")!
            
            let preCount = names.count
            names.insert(name)
            
            guard names.count > preCount else { print("skipping \(name)"); continue }
            
            ownerList.append(RepoOwner(avatarURL: url,
                                       name: name))
        }
        
        print(ownerList)
    }

}

