import Foundation
import CoreLocation
import UIKit

/// `-screenshot <name>` opens one screen with fixed state for App Store screenshots (scripts/capture-screenshots.sh).
/// Names: home, tenderloins, loosemeat, pizza, heritage, honors, oldest, detail, map, saved, about.
enum ScreenshotMode {
    /// Debug builds only: an App Store build ignores the launch argument, so no one can reach seeded screens or fake locations.
    static var name: String? {
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        guard let i = args.firstIndex(of: "-screenshot"), i + 1 < args.count else { return nil }
        return args[i + 1]
        #else
        return nil
        #endif
    }
    static var isActive: Bool { name != nil }

    @MainActor
    static func apply(to model: AppModel) {
        guard let name, model.isLoaded else { return }
        model.filters = Filters()
        // downtown Des Moines (the East Village), so "nearest" lists have distances without a permission prompt
        model.screenshotLocation = CLLocation(latitude: 41.5880, longitude: -93.6130)
        // by name and town, ignoring case, so a rebuild with a slightly different casing still finds the place; the hand-checked one first
        let pick = { (n: String, town: String?) -> Place? in
            let hits = model.places.filter { $0.name.caseInsensitiveCompare(n) == .orderedSame && (town == nil || $0.city == town) }
            return hits.first(where: \.handChecked) ?? hits.first
        }
        for p in [pick("Hometown Heroes", "Grinnell"), pick("Harris Pizza", "Bettendorf"), pick("Breitbach's Country Dining", "Sherrill")]
            .compactMap({ $0 }) where !model.isSaved(p) {
            model.toggleSaved(p)
        }
        let open = { (g: Guide) in model.tab = .guides; model.selectedGuide = g; model.guidesPath = [.guide(g)] }
        switch name {
        case "tenderloins":
            // Grinnell, between Des Moines and the Cedar Rapids-Iowa City corridor
            model.screenshotLocation = CLLocation(latitude: 41.7436, longitude: -92.7224)
            open(.tenderloins)
        case "loosemeat":
            // Marshalltown
            model.screenshotLocation = CLLocation(latitude: 42.0494, longitude: -92.9080)
            open(.loosemeat)
        case "pizza":
            // the Quad Cities (Davenport)
            model.screenshotLocation = CLLocation(latitude: 41.5236, longitude: -90.5776)
            open(.pizza)
        case "heritage":
            // the Amana Colonies
            model.screenshotLocation = CLLocation(latitude: 41.7992, longitude: -91.8727)
            open(.heritage)
        case "honors": open(.honors)
        case "oldest": open(.oldest)
        case "detail":
            // Hometown Heroes: the 2025 tenderloin winner, with its note
            model.screenshotLocation = CLLocation(latitude: 41.7436, longitude: -92.7224)
            open(.tenderloins)
            if let p = pick("Hometown Heroes", "Grinnell") ?? model.places.first {
                model.selectedPlace = p; model.guidesPath.append(.place(p))
            }
        case "map": model.tab = .map
        case "saved": model.tab = .saved
        case "about": model.tab = .about
        default: model.tab = .guides; model.selectedGuide = nil
        }
        // iPad shows the place column next to every list, so give each shot a place instead of "Pick a place": a different
        // honored or hand-checked one per shot.
        guard UIDevice.current.userInterfaceIdiom == .pad, model.selectedPlace == nil else { return }
        let place: Place? = switch name {
        case "home": pick("Breitbach's Country Dining", "Sherrill")
        case "tenderloins": pick("Wasted Grain", "Carroll")
        case "loosemeat": pick("Taylor's Maid-Rite", "Marshalltown")
        case "pizza": pick("Harris Pizza", "Bettendorf")
        case "heritage": pick("Ronneburg Restaurant", "Amana")
        case "map": pick("Fong's Pizza", "Des Moines")
        case "honors": pick("Archie's Waeside", "Le Mars")
        case "oldest": pick("Breitbach's Country Dining", "Sherrill")
        case "saved": pick("Hometown Heroes", "Grinnell")
        case "about": nil
        default: pick("Hometown Heroes", "Grinnell")
        }
        model.selectedPlace = place
    }
}
