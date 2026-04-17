import Autoconfiguration
import Foundation

extension FileManager {
    func save(_ emailAdress: String, data: (Data, Data), to url: URL = Bundle.main.executableDirectory) throws {
        guard fileExists(at: url, isDirectory: true) else {
            throw URLError(.fileDoesNotExist)
        }
        let url: URL = url.appending(path: emailAdress, directoryHint: .isDirectory)
        try? removeItem(at: url)
        try createDirectory(at: url, withIntermediateDirectories: false)
        try data.0.write(to: url.appending(component: "config.json"))
        try data.1.write(to: url.appending(component: "config.xml"))
    }

    func fileExists(at url: URL, isDirectory: Bool? = nil) -> Bool {
        var _isDirectory: ObjCBool = false
        guard fileExists(atPath: url.path(), isDirectory: &_isDirectory) else {
            return false
        }
        return isDirectory != nil ? isDirectory! == _isDirectory.boolValue : true
    }
}
