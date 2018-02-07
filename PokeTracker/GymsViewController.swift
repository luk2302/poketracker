
import Foundation
import MapKit
import SwiftyUserDefaults

class GymsViewController : UIViewController, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var locationButton: UIButton!
    @IBOutlet weak var refreshButton: UIButton!
    
    @IBInspectable var instinctColor: UIColor!
    @IBInspectable var valorColor: UIColor!
    @IBInspectable var mysticColor: UIColor!
    
    var myGyms = Set<String>()
    
    override func viewDidLoad() {
        centerMapOnUserButtonClicked()
        myGyms = Set(Defaults[.myGyms])
        refreshData()
    }
    
    @IBAction func centerMapOnUserButtonClicked() {
        self.mapView.setUserTrackingMode(.follow, animated: true)
    }
    
    class Rotation {
        var stop : Bool = false
        var count : Int = 0
        func shouldStop() -> Bool {
            return stop && count % 2 == 0
        }
    }
    func rotateButton(_ rotationData : Rotation = Rotation()) -> Rotation {
        UIView.animate(withDuration: 0.35, delay: 0, options: UIViewAnimationOptions.curveLinear, animations: {
            self.refreshButton.transform = self.refreshButton.transform.rotated(by: CGFloat.pi * 1)
            rotationData.count = rotationData.count + 1
        }, completion: {_ in
            if !rotationData.shouldStop() {
                let _ = self.rotateButton(rotationData)
            }
        })
        return rotationData
    }
    
    @IBAction func refreshData() {
        print("refreshing gym data")
        if let location = self.mapView.userLocation.location {
            let rotation = rotateButton()
            
            Networker.requestGyms(location: location) {
                let gyms = $0.gyms.values
                self.mapView.removeAnnotations(self.mapView.annotations)
                gyms.forEach {
                    let annotation = CustomPointAnnotation()
                    annotation.gym = $0
                    annotation.coordinate = $0.location.coordinate
                    self.mapView.addAnnotation(annotation)
                }
                rotation.stop = true
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
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        mapView.deselectAnnotation(view.annotation, animated: false)
        if let annotation = view.annotation as? CustomPointAnnotation {
            let id = annotation.gym.id
            if myGyms.contains(id!) {
                myGyms.remove(id!)
                (view as! CustomAnnotationView).favourite(false)
            } else {
                myGyms.insert(id!)
                (view as! CustomAnnotationView).favourite(true)
            }
            Defaults[.myGyms] = Array(myGyms)
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        // split annotation views, different display kinds of annotations for ongoing raid, spawning raid or regular gym
        let reuseIdentifier = "gym"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier) as? CustomAnnotationView
        let annotation = annotation as! CustomPointAnnotation
        
        if annotationView == nil {
            annotationView = CustomAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
        } else {
            annotationView!.annotation = annotation
        }
        
        annotationView?.favourite(myGyms.contains(annotation.gym.id))
        
        annotationView?.progress.strokeEnd = CGFloat(annotation.gym.progress)
        annotationView?.label.text = "\(annotation.gym.level)"
        let gym = annotation.gym!
        if gym.hasRaid {
            let raid = gym.raid!
            annotationView?.label.text = "\(raid.level!)"
            if raid.isOngoing() {
                annotationView?.team.backgroundColor = UIColor(red: 0, green: 0.4, blue: 0, alpha: 1)
                annotationView?.label.textColor = .white
                annotationView?.progress.strokeColor = UIColor.green.cgColor
                annotationView?.imageView.isHidden = false
                if raid.pokemon != nil {
                    annotationView?.imageView.image = Pokemon.sprites[raid.pokemon - 1]
                }
                annotationView?.label.isHidden = true
            } else {
                annotationView?.imageView.isHidden = true
                annotationView?.label.isHidden = false
                annotationView?.team.backgroundColor = .orange
                annotationView?.label.textColor = .black
                annotationView?.progress.strokeColor = UIColor.yellow.cgColor
            }
        } else {
            annotationView?.imageView.isHidden = true
            annotationView?.label.isHidden = false
            annotationView?.label.text = "\(annotation.gym.level)"
            switch gym.team {
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
    let imageView : UIImageView
    var progress : CAShapeLayer
    let size = 15
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        team = UIView(frame: CGRect(x: -size, y: -size, width: 2 * size, height: 2 * size))
        team.layer.cornerRadius = CGFloat(size)
        label = UILabel()
        label.textAlignment = .center
        label.frame = CGRect(x: -size, y: -size, width: size * 2, height: size * 2)
        progress = CAShapeLayer()
        let circlePath = UIBezierPath(arcCenter: CGPoint(x: size, y: size), radius: CGFloat(size), startAngle: -0.5 * CGFloat.pi, endAngle: 1.5 * CGFloat.pi, clockwise: true)
        progress.path = circlePath.cgPath
        progress.fillColor = UIColor.clear.cgColor
        progress.lineWidth = 3
        progress.strokeStart = 0
        
        imageView = UIImageView(frame: label.frame)
        
        
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        
        addSubview(team)
        addSubview(label)
        addSubview(imageView)
        team.layer.addSublayer(progress)
    }
    
    func favourite(_ fav : Bool) {
        if fav {
            label.font = UIFont.boldSystemFont(ofSize: 18)
            team.layer.shadowOpacity = 1
            team.layer.shadowRadius = 8
            team.layer.shadowColor = UIColor.black.cgColor
            team.layer.shadowOffset = CGSize.zero
        } else {
            label.font = UIFont.systemFont(ofSize: UIFont.systemFontSize)
            team.layer.shadowOpacity = 0
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
