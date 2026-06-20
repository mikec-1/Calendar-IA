//
//  CalendarCell.swift
//  Calendar
//
//  Created by Michael Cole on 27.01.23.
//

import Foundation
import UIKit

class CalendarCell: UICollectionViewCell {
    @IBOutlet weak var dayOfMonth: UILabel! //Label showing the day of the month
    
    // Programmatically create a tiny dot indicator for events
    let eventIndicator: UIView = {
        let view = UIView()
        view.backgroundColor = .systemRed
        view.layer.cornerRadius = 3 
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true // hidden by default
        return view
    }()
    
    // Programmatically create an image view for weather symbols
    let weatherIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = .secondaryLabel
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupIndicator()
    }
    
    // Alternatively, if the cell is purely programmatic:
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupIndicator()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private func setupIndicator() {
        addSubview(eventIndicator)
        addSubview(weatherIconView)
        
        NSLayoutConstraint.activate([
            eventIndicator.widthAnchor.constraint(equalToConstant: 6),
            eventIndicator.heightAnchor.constraint(equalToConstant: 6),
            eventIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            eventIndicator.topAnchor.constraint(equalTo: dayOfMonth.bottomAnchor, constant: 2),
            
            weatherIconView.widthAnchor.constraint(equalToConstant: 12),
            weatherIconView.heightAnchor.constraint(equalToConstant: 12),
            weatherIconView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -2),
            weatherIconView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2)
        ])
    }
}
