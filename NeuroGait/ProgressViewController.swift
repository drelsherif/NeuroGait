//
//  ProgressViewController.swift
//  NeuroGait
//

import UIKit

class ProgressViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Progress Tracking"
        view.backgroundColor = .systemBackground
        
        // TODO: Implement progression tracking UI
        let label = UILabel()
        label.text = "Progress tracking coming soon..."
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}
