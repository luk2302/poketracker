import UIKit
import SwiftyUserDefaults

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        if Defaults[.pokemonCount] == 0 {
            Defaults[.pokemonCount] = 251
        }
        if Defaults[.vibrationThreshold] == 0 {
            Defaults[.vibrationThreshold] = 40
        }
        if Defaults[.url] == nil {
            Defaults[.url] = "http://pokemapmuc.de"
        }
        return true
    }
}
