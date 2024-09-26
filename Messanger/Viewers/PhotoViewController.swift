//
//  PhotoViewController.swift
//  Messanger
//
//  Created by Ibrahim Timurkaev on 09.09.2024.
//

import UIKit
import SDWebImage

final class PhotoViewController: UIViewController {
    
    private let url: URL
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    // MARK: - Init
    
    init(url: URL) {
        self.url = url
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .black
        
        setupImageViewLayout()
        
        imageView.sd_setImage(with: url)
    }
    
    // MARK: - Private methods

    private func setupImageViewLayout() {
        view.addSubview(imageView)
        
        imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: LayoutMetrics.module).activate()
        imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -LayoutMetrics.module).activate()
        imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor).activate()
        imageView.heightAnchor.constraint(lessThanOrEqualToConstant: UIScreen.main.bounds.height / 2).activate()
    }
    
//    private func fetchImage() {
//        let urlReqest = URLRequest(url: url)
//        URLSession.shared.dataTask(with: urlReqest) { data, _, error in
//            guard let data = data, error == nil else {
//                print("Can not download message photo")
//                return
//            }
//            
//            let image = UIImage(data: data)
//            
//            DispatchQueue.main.async {
//                self.imageView.image = image
//            }
//        }.resume()
//    }
}
