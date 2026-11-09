import CoreLocation
import Observation
import UIKit

/// "Near me" sorting. Asks for when-in-use permission only when a list is sorted by distance or "My location" is tapped; the location never leaves the device.
@MainActor
@Observable
final class LocationService: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private(set) var location: CLLocation?
    private(set) var status: CLAuthorizationStatus = .notDetermined
    /// no fix within 12 seconds, or Core Location reported an error
    private(set) var failed = false
    private var timeout: Task<Void, Never>?
    /// when the current request started: a fix from before it is a cached one (from launch, or before a drive) and doesn't count
    private var askedAt = Date.distantPast

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        status = manager.authorizationStatus
    }

    var isDenied: Bool { status == .denied || status == .restricted }

    /// Every place is in Iowa, so a reader elsewhere (an App Reviewer in California, say) gets told rather than an empty map.
    /// A coarse outline of the state (Idaho's lesson: a bounding box would count Omaha, Moline and East Dubuque),
    /// drawn a little outside the line so the river and bay shores count as inside.
    var isOutsideIowa: Bool {
        guard let c = location?.coordinate else { return false }
        return !IowaOutline.contains(c)
    }

    /// Once location is off for the app, iOS won't ask again; the app's page in Settings is the only way back.
    static func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
    }

    func request() {
        switch manager.authorizationStatus {
        case .notDetermined: manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways: locate()
        default: break
        }
    }

    private func locate() {
        failed = false
        let asked = Date()
        askedAt = asked
        manager.requestLocation()
        timeout?.cancel()
        timeout = Task { [weak self] in
            try? await Task.sleep(for: .seconds(12))
            guard let self, !Task.isCancelled else { return }
            if (self.location?.timestamp ?? .distantPast) < asked { self.failed = true }
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ m: CLLocationManager) {
        let s = m.authorizationStatus
        Task { @MainActor in
            self.status = s
            if s == .authorizedWhenInUse || s == .authorizedAlways { self.locate() }
        }
    }

    nonisolated func locationManager(_ m: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let l = locations.last else { return }
        Task { @MainActor in
            // "My location" needs a fresh fix on every tap: a cached one from before the request would put you back where you were
            guard l.timestamp >= self.askedAt.addingTimeInterval(-2) else { return }
            self.location = l; self.failed = false; self.timeout?.cancel()
        }
    }

    nonisolated func locationManager(_ m: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in if self.location == nil { self.failed = true } }
    }
}

extension CLLocation {
    /// "0.4 mi", "12 mi", "1,012 mi" (an App Reviewer in California is a thousand miles out)
    func milesText(to other: CLLocation) -> String {
        let mi = distance(from: other) / 1609.344
        return (mi < 10 ? mi.formatted(.number.precision(.fractionLength(1))) : Int(mi.rounded()).formatted()) + " mi"
    }
}

/// A coarse Iowa outline (longitude, latitude), about 600 m outside the Overture land outline but never over a neighbour's land (buffer
/// 0.006°, the neighbours cut back out, simplify 0.008°). Council Bluffs, Davenport, Bettendorf, Sioux City, Dubuque, Burlington, Keokuk,
/// Lansing and Clinton are inside; Omaha, Rock Island, Moline, South Sioux City, North Sioux City, East Dubuque, Albert Lea, Fulton
/// and Nauvoo are not.
enum IowaOutline {
    static let rings: [[(Double, Double)]] = [
        [(-96.623, 42.725), (-96.639, 42.737), (-96.619, 42.754), (-96.636, 42.769), (-96.594, 42.793), (-96.581, 42.837),
         (-96.564, 42.828), (-96.55, 42.837), (-96.556, 42.849), (-96.541, 42.858), (-96.55, 42.869), (-96.54, 42.889),
         (-96.524, 42.892), (-96.542, 42.904), (-96.541, 42.924), (-96.517, 42.932), (-96.499, 42.957), (-96.52, 42.979),
         (-96.491, 43.01), (-96.512, 43.027), (-96.51, 43.04), (-96.521, 43.039), (-96.46, 43.064), (-96.454, 43.086),
         (-96.462, 43.091), (-96.436, 43.12), (-96.468, 43.152), (-96.476, 43.222), (-96.559, 43.223), (-96.571, 43.239),
         (-96.549, 43.246), (-96.552, 43.259), (-96.585, 43.269), (-96.579, 43.293), (-96.588, 43.296), (-96.552, 43.292),
         (-96.523, 43.31), (-96.535, 43.336), (-96.521, 43.385), (-96.573, 43.419), (-96.57, 43.429), (-96.594, 43.434),
         (-96.603, 43.451), (-96.581, 43.481), (-96.599, 43.5), (-91.218, 43.5), (-91.234, 43.455), (-91.201, 43.413),
         (-91.199, 43.39), (-91.215, 43.368), (-91.207, 43.352), (-91.108, 43.313), (-91.058, 43.255), (-91.179, 43.125),
         (-91.175, 43.039), (-91.147, 42.963), (-91.147, 42.91), (-91.101, 42.883), (-91.093, 42.843), (-91.078, 42.835),
         (-91.065, 42.751), (-90.949, 42.685), (-90.707, 42.634), (-90.642, 42.538), (-90.637, 42.513), (-90.654, 42.478),
         (-90.568, 42.44), (-90.555, 42.416), (-90.477, 42.383), (-90.444, 42.355), (-90.416, 42.323), (-90.431, 42.278),
         (-90.394, 42.228), (-90.216, 42.156), (-90.202, 42.131), (-90.163, 42.116), (-90.165, 42.042), (-90.141, 42.003),
         (-90.165, 41.949), (-90.15, 41.915), (-90.182, 41.843), (-90.182, 41.807), (-90.279, 41.768), (-90.311, 41.742),
         (-90.314, 41.698), (-90.335, 41.68), (-90.344, 41.647), (-90.343, 41.592), (-90.406, 41.57), (-90.462, 41.524),
         (-90.556, 41.525), (-90.599, 41.509), (-90.656, 41.463), (-90.736, 41.45), (-90.847, 41.456), (-90.93, 41.422),
         (-90.98, 41.435), (-91.046, 41.414), (-91.075, 41.306), (-91.114, 41.241), (-91.042, 41.166), (-90.995, 41.16),
         (-90.947, 41.096), (-90.953, 40.954), (-90.966, 40.922), (-91.01, 40.901), (-91.093, 40.821), (-91.092, 40.78),
         (-91.111, 40.746), (-91.124, 40.67), (-91.187, 40.638), (-91.253, 40.638), (-91.34, 40.614), (-91.406, 40.555),
         (-91.405, 40.539), (-91.382, 40.528), (-91.364, 40.494), (-91.382, 40.446), (-91.373, 40.399), (-91.392, 40.385),
         (-91.485, 40.383), (-91.482, 40.406), (-91.525, 40.413), (-91.519, 40.433), (-91.533, 40.438), (-91.525, 40.458),
         (-91.574, 40.466), (-91.591, 40.493), (-91.62, 40.509), (-91.62, 40.542), (-91.688, 40.557), (-91.686, 40.581),
         (-91.729, 40.614), (-92.687, 40.59), (-94.295, 40.572), (-95.764, 40.586), (-95.748, 40.603), (-95.776, 40.647),
         (-95.842, 40.678), (-95.852, 40.703), (-95.888, 40.732), (-95.879, 40.753), (-95.835, 40.779), (-95.848, 40.861),
         (-95.809, 40.891), (-95.839, 40.933), (-95.829, 40.978), (-95.867, 41.002), (-95.859, 41.036), (-95.882, 41.06),
         (-95.862, 41.088), (-95.881, 41.16), (-95.841, 41.176), (-95.862, 41.188), (-95.916, 41.186), (-95.927, 41.197),
         (-95.91, 41.235), (-95.928, 41.298), (-95.905, 41.299), (-95.914, 41.279), (-95.904, 41.274), (-95.871, 41.297),
         (-95.883, 41.317), (-95.926, 41.322), (-95.957, 41.346), (-95.928, 41.37), (-95.937, 41.393), (-95.922, 41.456),
         (-96.011, 41.477), (-96.019, 41.489), (-95.992, 41.514), (-96.005, 41.544), (-96.028, 41.541), (-96.041, 41.508),
         (-96.094, 41.539), (-96.081, 41.577), (-96.117, 41.61), (-96.095, 41.647), (-96.121, 41.688), (-96.073, 41.705),
         (-96.106, 41.738), (-96.08, 41.758), (-96.064, 41.793), (-96.107, 41.821), (-96.11, 41.849), (-96.142, 41.869),
         (-96.161, 41.902), (-96.136, 41.921), (-96.144, 41.942), (-96.129, 41.972), (-96.185, 41.978), (-96.183, 42.0),
         (-96.194, 42.009), (-96.226, 41.995), (-96.242, 42.001), (-96.221, 42.03), (-96.275, 42.052), (-96.268, 42.114),
         (-96.31, 42.133), (-96.349, 42.172), (-96.359, 42.21), (-96.323, 42.23), (-96.328, 42.255), (-96.365, 42.286),
         (-96.375, 42.319), (-96.417, 42.352), (-96.408, 42.376), (-96.415, 42.406), (-96.38, 42.445), (-96.385, 42.475),
         (-96.402, 42.487), (-96.476, 42.491), (-96.476, 42.509), (-96.493, 42.516), (-96.479, 42.525), (-96.477, 42.556),
         (-96.498, 42.559), (-96.485, 42.575), (-96.509, 42.613), (-96.531, 42.614), (-96.515, 42.63), (-96.598, 42.699),
         (-96.63, 42.705), (-96.623, 42.725)]]

    static func contains(_ c: CLLocationCoordinate2D) -> Bool { rings.contains { contains(c, ring: $0) } }

    /// Ray casting: a point is inside when a ray east of it crosses the outline an odd number of times.
    static func contains(_ c: CLLocationCoordinate2D, ring: [(Double, Double)]) -> Bool {
        var inside = false
        var j = ring.count - 1
        for i in 0..<ring.count {
            let (xi, yi) = ring[i], (xj, yj) = ring[j]
            if (yi > c.latitude) != (yj > c.latitude) && c.longitude < (xj - xi) * (c.latitude - yi) / (yj - yi) + xi { inside.toggle() }
            j = i
        }
        return inside
    }
}
