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
        static let topMargin: CGFloat = 20.0
        static let itemHeight: CGFloat = 60.0
        static let itemSpacing: CGFloat = 10.0
    }
    
    private let searchController = UISearchController(searchResultsController: nil)
    private var searchBar: UISearchBar {
        return searchController.searchBar
    }
    
    private weak var collectionView: UICollectionView!
    
    private var ownerList = [RepoOwner]()
    private var names = Set<String>()
    private var nextRepoID: Int? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setSubViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
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
        cell.backgroundColor = UIColor.red
        cell.imageView.backgroundColor = UIColor.yellow
        cell.label.backgroundColor = UIColor.blue
        
        return cell
    }

    // MARK: - Private
    
    private func setSubViews() {
        setUpCollectionView()
        setUpSearchBar()
        setConstraints()
    }
    
    private func setUpCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: UIScreen.main.bounds.width,
                                 height: Constant.itemHeight)
        layout.minimumLineSpacing = Constant.itemSpacing
        
        let collectionView = UICollectionView(frame: CGRect.zero,
                                              collectionViewLayout: layout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        collectionView.backgroundColor = UIColor.gray
        
        view.addSubview(collectionView)
        self.collectionView = collectionView
        
        collectionView.register(RepoOwnerCell.self,
                                forCellWithReuseIdentifier: Constant.cellID)
    }
    
    private func setUpSearchBar() {
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchBar)
    }
    
    private func setConstraints() {
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
            NSLayoutConstraint.constraints(withVisualFormat: "V:|-\(Constant.topMargin)-[\(idCollectionView)]|",
                options: [],
                metrics: nil,
                views: dicViews) +
            NSLayoutConstraint.constraints(withVisualFormat: "H:|[\(idSearchBar)]|",
                options: [],
                metrics: nil,
                views: dicViews) +
            NSLayoutConstraint.constraints(withVisualFormat: "V:|-\(Constant.topMargin)-[\(idSearchBar)]",
                options: [],
                metrics: nil,
                views: dicViews)
        
        NSLayoutConstraint.activate(constraints)
        
        let inset = searchBar.bounds.height
        collectionView.contentInset.top = inset
        collectionView.scrollIndicatorInsets.top = inset
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
        
        collectionView.reloadData()
    }

}

