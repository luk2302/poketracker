import Foundation
import MapKit


func now() -> Int {
    return Int(Date().timeIntervalSince1970 * 1000)
}

// http://stackoverflow.com/questions/26998029/calculating-bearing-between-two-cllocation-points-in-swift
func degreesToRadians(_ degrees: Double) -> Double { return degrees * .pi / 180.0 }
func radiansToDegrees(_ radians: Double) -> Double { return radians * 180.0 / .pi }
func getBearingBetweenTwoPoints1(point1 : CLLocation, point2 : CLLocation) -> Double {
    
    let lat1 = degreesToRadians(point1.coordinate.latitude)
    let lon1 = degreesToRadians(point1.coordinate.longitude)
    
    let lat2 = degreesToRadians(point2.coordinate.latitude)
    let lon2 = degreesToRadians(point2.coordinate.longitude)
    
    let dLon = lon2 - lon1
    
    let y = sin(dLon) * cos(lat2)
    let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
    let radiansBearing = atan2(y, x)
    
    return radiansToDegrees(radiansBearing)
}

extension UICollectionView {
    func forEachVisibleCell<T : UICollectionViewCell>(do function : @escaping ((T) -> Void)) {
        self.indexPathsForVisibleItems.forEach {
            if let cell = self.cellForItem(at: $0) as? T {
                function(cell)
            }
        }
    }
}
