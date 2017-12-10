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

class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate,
                      UISearchControllerDelegate, UISearchResultsUpdating
{
    static func initWithNavigationController() -> UINavigationController {
        let vc = ViewController()
        let navController = UINavigationController(rootViewController: vc)
        
        return navController
    }
    
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
    private var searchText: String {
        return searchBar.text ?? ""
    }
    
    private weak var collectionView: UICollectionView!
    
    private var ownerList = [RepoOwner]()
    private var filteredList = [RepoOwner]()
    
    private var imageCache = [String: UIImage]()
    
    private var names = Set<String>()
    private var nextRepoID: Int? = nil
    private var fetchingID: Int? = nil
    
    private weak var timer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setSubviews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        fetchList()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        imageCache.removeAll()
    }
    
    // MARK: - Search bar
    
    func presentSearchController(_ searchController: UISearchController) {
        let views = ["searchBar": searchBar]
        let constraints =
            NSLayoutConstraint.constraints(withVisualFormat: "H:|[searchBar]|",
                                           options: [],
                                           metrics: nil,
                                           views: views) +
            NSLayoutConstraint.constraints(withVisualFormat: "V:|[searchBar]",
                                               options: [],
                                               metrics: nil,
                                               views: views)
        
        NSLayoutConstraint.activate(constraints)
    }
    
    func didDismissSearchController(_ searchController: UISearchController) {
        let views = ["searchBar": searchBar]
        let constraints =
            NSLayoutConstraint.constraints(withVisualFormat: "H:|[searchBar]|",
                                           options: [],
                                           metrics: nil,
                                           views: views) +
            NSLayoutConstraint.constraints(withVisualFormat: "V:|[searchBar]",
                                           options: [],
                                           metrics: nil,
                                           views: views)
        
        NSLayoutConstraint.activate(constraints)
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        if let timer = timer { timer.invalidate() }
        timer = Timer.scheduledTimer(withTimeInterval: 0.5,
                                     repeats: false,
                                     block: filterSearch(_:))
    }
    
    // MARK: - Collection view
    
    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int
    {
        let showLoadingCell = searchText.isEmpty
        let count = showLoadingCell ? filteredList.count + 1 : filteredList.count
        
        return max(count, 1)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Constant.cellID,
                                                      for: indexPath) as! RepoOwnerCell
        
        if indexPath.item != filteredList.count {
            let owner = filteredList[indexPath.item]
            
            if let image = imageCache[owner.avatarURL] {
                print("using cache")
                cell.set(image: image)
            } else {
                requestImage(forCell: cell,
                             name: owner.name,
                             url: owner.avatarURL)
            }
            
            cell.set(name: owner.name)
        } else {
            if filteredList.count == 0 {
                cell.set(name: "Empty")
            } else {
                cell.toggleIndicator(true)
            }
        }
        
        return cell
    }
    
    // MARK: - Scroll view
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView,
                                   withVelocity velocity: CGPoint,
                                   targetContentOffset: UnsafeMutablePointer<CGPoint>)
    {
        guard filteredList.count == ownerList.count else { return }
        
        let maxY = scrollView.contentSize.height -
                   scrollView.frame.height
        guard targetContentOffset.pointee.y >= maxY else { return }
        
        fetchList()
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        searchController.dismiss(animated: true, completion: nil)
    }

    // MARK: - Private
    
    private func setSubviews() {
        setUpCollectionView()
        setUpSearchController()
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
        
        collectionView.backgroundColor = UIColor.lightGray
        
        view.addSubview(collectionView)
        self.collectionView = collectionView
        
        collectionView.register(RepoOwnerCell.self,
                                forCellWithReuseIdentifier: Constant.cellID)
    }
    
    private func setUpSearchController() {
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.searchBarStyle = .minimal
        
        searchController.delegate = self
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchResultsUpdater = self
        
        definesPresentationContext = true
        navigationItem.titleView = searchBar
    }
    
    private func setConstraints() {
        let idCollectionView = "collectionView"
        let idSearchBar = "searchBar"
        
        let metrics: [String: Any] = [
            "top": Constant.topMargin,
            "sbHeight": searchBar.bounds.height,
        ]
        let views: [String: Any] = [
            idCollectionView: collectionView,
            idSearchBar: searchController.searchBar,
            ]
        
        let constraints =
            NSLayoutConstraint.constraints(withVisualFormat: "H:|[\(idCollectionView)]|",
                options: [],
                metrics: metrics,
                views: views) +
            NSLayoutConstraint.constraints(withVisualFormat: "V:|[\(idCollectionView)]|",
                options: [],
                metrics: metrics,
                views: views)
        
        NSLayoutConstraint.activate(constraints)
    }
    
    private func fetchList() {
        if let fetchingID = fetchingID {
            guard nextRepoID != fetchingID else {
                print("Duplicate call")
                return
            }
        }
        fetchingID = nextRepoID
        
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
        var indexPaths = [IndexPath]()
        
        for dictionary in rawList {
            let owner = dictionary.dic("owner")!
            let url = owner.str("avatar_url")!
            let name = dictionary.str("name")!
            
            let preCount = names.count
            names.insert(name)
            
            guard names.count > preCount else { print("skipping \(name)"); continue }
            
            indexPaths.append(IndexPath(item: ownerList.count,
                                        section: 0))
            ownerList.append(RepoOwner(avatarURL: url,
                                       name: name))
        }
        
        if rawList.count > 0 {
            nextRepoID = rawList.last!.int("id")
        }
        
        if searchText.isEmpty {
            filteredList = ownerList
            collectionView.insertItems(at: indexPaths)
        } else {
            print("displaying searched results")
        }
    }
    
    private func filterSearch(_ timer: Timer?) {
        if !searchText.isEmpty {
            filteredList = ownerList.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
            }
        } else {
            filteredList = ownerList
        }
        
        collectionView.reloadData()
    }
    
    private func requestImage(forCell cell: RepoOwnerCell,
                              name: String,
                              url: String)
    {
        do {
            let req = try Request(method: .GET,
                                  urlString: url,
                                  parameters: nil)
                .data {
                    guard cell.name == name else {
                        print("cell assigned to a different user")
                        return
                    }
                    guard let image = UIImage(data: $0) else {
                        print("failed to convert to image")
                        return
                    }
                    
                    self.imageCache[url] = image
                    cell.set(image: image)
                }
                .failure {
                    print($0, $1)
                }
            
            KRClient.shared.make(httpRequest: req)
        } catch {
            print(error)
        }
    }

}

