//
//  RepoOwnerCell.swift
//  RepoOwners
//
//  Created by Joshua Park on 10/12/2017.
//  Copyright © 2017 Joshua Park. All rights reserved.
//

import UIKit
import KRClient

class RepoOwnerCell: UICollectionViewCell {
    
    private struct Constant {
        static let edge: CGFloat = 10.0
        static let imageViewSize: CGFloat = 40.0
    }
    
    @IBOutlet private var imageView: UIImageView!
    @IBOutlet private var label: UILabel!
    
    private var urlString: String?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        urlString = nil
        imageView.image = nil
        label.text = nil
    }
    
    func set(urlString: String, name: String) {
        self.urlString = urlString
        label.text = name
        
        do {
            let req = try Request(method: .GET,
                              urlString: urlString,
                              parameters: nil)
                .data {
                    guard self.urlString == $1.url!.absoluteString else {
                        print("rejected: \(urlString) \(name)")
                        return
                    }
                    self.imageView.image = UIImage(data: $0)
                }
                .failure {
                    print($0, $1)
                }
            
            KRClient.shared.make(httpRequest: req)
        } catch {
            print(error)
        }
    }
    
    private func setUp() {
        backgroundColor = UIColor.white
        
        imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(imageView)
        addSubview(label)
        
        let views: [String: Any] = [
            "imageView": imageView,
            "label": label,
        ]
        
        let metrics: [String: Any] = [
            "edge": Constant.edge,
            "size": Constant.imageViewSize,
        ]
        
        let constraints = [
            NSLayoutConstraint(item: imageView,
                               attribute: .width,
                               relatedBy: .equal,
                               toItem: nil,
                               attribute: .notAnAttribute,
                               multiplier: 1.0,
                               constant: Constant.imageViewSize),
            NSLayoutConstraint(item: imageView,
                               attribute: .height,
                               relatedBy: .equal,
                               toItem: nil,
                               attribute: .notAnAttribute,
                               multiplier: 1.0,
                               constant: Constant.imageViewSize),
            NSLayoutConstraint(item: imageView,
                               attribute: .centerY,
                               relatedBy: .equal,
                               toItem: self,
                               attribute: .centerY,
                               multiplier: 1.0,
                               constant: 0.0),
            NSLayoutConstraint(item: label,
                               attribute: .centerY,
                               relatedBy: .equal,
                               toItem: self,
                               attribute: .centerY,
                               multiplier: 1.0,
                               constant: 0.0)
        ] +
            NSLayoutConstraint.constraints(withVisualFormat: "H:|-(edge)-[imageView]-(edge)-[label]-(>=edge)-|",
                                           options: [],
                                           metrics: metrics,
                                           views: views)
        NSLayoutConstraint.activate(constraints)
    }
    
}
