
import Foundation
import MapKit

class GymsViewController : UIViewController, MKMapViewDelegate {
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var locationButton: UIButton!
    @IBInspectable var instinctColor: UIColor!
    @IBInspectable var valorColor: UIColor!
    @IBInspectable var mysticColor: UIColor!
    
    override func viewDidLoad() {
        centerMapOnUserButtonClicked()
        refreshData()
    }
    
    @IBAction func centerMapOnUserButtonClicked() {
        self.mapView.setUserTrackingMode(.follow, animated: true)
    }

    @IBAction func refreshData() {
        if let location = self.mapView.userLocation.location {
            Networker.requestGyms(location: location) {
                let gyms = $0.gyms.values
                self.mapView.removeAnnotations(self.mapView.annotations)
                gyms.forEach {
                    let annotation = CustomPointAnnotation()
                    annotation.gym = $0
                    annotation.coordinate = $0.location.coordinate
                    self.mapView.addAnnotation(annotation)
                }
            }
        } else {
            self.perform(#selector(GymsViewController.refreshData), with: nil, afterDelay: 1.0)
        }
    }
    
    func mapView(_ mapView: MKMapView, didChange mode: MKUserTrackingMode, animated: Bool) {
        UIView.animate(withDuration: 0.33) {
            self.locationButton.alpha = (mode == .follow ? 0 : 1.0)
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        let reuseIdentifier = "gym"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier) as? CustomAnnotationView
        let annotation = annotation as! CustomPointAnnotation
        
        if annotationView == nil {
            annotationView = CustomAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
        } else {
            annotationView!.annotation = annotation
        }
        
        annotationView?.progress.strokeEnd = CGFloat(annotation.gym.progress)
        annotationView?.label.text = "\(annotation.gym.level)"
        switch annotation.gym.team {
            case 0:
                annotationView?.team.backgroundColor = .lightGray
                annotationView?.label.textColor = .black
            case 1:
                annotationView?.team.backgroundColor = mysticColor
                annotationView?.label.textColor = .white
                annotationView?.progress.strokeColor = UIColor.black.cgColor
            case 2:
                annotationView?.team.backgroundColor = valorColor
                annotationView?.label.textColor = .white
                annotationView?.progress.strokeColor = UIColor.black.cgColor
            case 3:
                annotationView?.team.backgroundColor = instinctColor
                annotationView?.label.textColor = .black
                annotationView?.progress.strokeColor = UIColor.black.cgColor
            default: break
        }
        
        return annotationView
    }
}

class CustomPointAnnotation: MKPointAnnotation {
    var gym : Gym!
}

class CustomAnnotationView : MKAnnotationView {
    let label : UILabel
    let team : UIView
    var progress : CAShapeLayer
    let size = 15
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        team = UIView(frame: CGRect(x: -size, y: -size, width: 2 * size, height: 2 * size))
        team.layer.cornerRadius = CGFloat(size)
        label = UILabel()
        label.textAlignment = .center
        label.frame = CGRect(x: -size, y: -size, width: size * 2, height: size * 2)
        progress = CAShapeLayer()
        let circlePath = UIBezierPath(arcCenter: CGPoint(x: size, y: size), radius: CGFloat(size), startAngle: CGFloat(-0.5 * M_PI), endAngle: CGFloat(1.5 * M_PI), clockwise: true)
        progress.path = circlePath.cgPath
        progress.fillColor = UIColor.clear.cgColor
        progress.lineWidth = 3
        progress.strokeStart = 0
        
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        
        addSubview(team)
        addSubview(label)
        team.layer.addSublayer(progress)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
