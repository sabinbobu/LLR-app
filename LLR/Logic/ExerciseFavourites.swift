import Foundation

enum ExerciseFavourites {
    /// Favourites first; each half keeps its incoming order, so a list already sorted by name stays
    /// sorted by name within both halves.
    static func favouritesFirst<T>(_ items: [T], isFavourite: (T) -> Bool) -> [T] {
        items.filter(isFavourite) + items.filter { !isFavourite($0) }
    }
}
