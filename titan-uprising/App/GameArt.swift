import UIKit

@MainActor
enum GameArt {
  private static var images: [String: UIImage] = [:]

  static func image(_ name: String) -> UIImage {
    if let image = images[name] { return image }
    guard let url = Bundle.main.url(forResource: name, withExtension: "png"),
      let image = UIImage(contentsOfFile: url.path)
    else { preconditionFailure("Missing or invalid bundled art: \(name)") }
    images[name] = image
    return image
  }
}
