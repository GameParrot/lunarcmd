// Minecraft Asset Downloader

import Foundation
import TinyLogger
func prase(string: String, key: String) -> [String] {
    var keys = [""]
    for i in string.components(separatedBy: "\"" + key + "\": \"") {
        keys.append(i.components(separatedBy: "\"")[0])
    }
    keys.remove(at: 0)
    keys.remove(at: 0)
#if DEBUG
    TinyLogger.log.debug(msg: "Found \(keys) in json", format: logFormat)
#endif
    return keys
}
func getAssets(version: String) throws {
    let versions = try prase(string: stringDownload(url: URL(string: "https://launchermeta.mojang.com/mc/game/version_manifest.json")!), key: "id")
    let jsons = try prase(string: stringDownload(url: URL(string: "https://launchermeta.mojang.com/mc/game/version_manifest.json")!), key: "url")
    let jsonData = try stringDownload(url: URL(string: jsons[versions.firstIndex(of: version)!])!)
    let assetIndex = prase(string: jsonData, key: "url")[0]
    if !FileManager.default.fileExists(atPath: gameDir + "/assets/indexes/") {
        try FileManager.default.createDirectory(at: URL(fileURLWithPath: gameDir + "/assets/indexes"), withIntermediateDirectories: true)
    }
    if !FileManager.default.fileExists(atPath: gameDir + "/assets/indexes/" + version + ".json") {
        try dataDownload(url: URL(string: assetIndex)!).write(to: URL(fileURLWithPath: gameDir + "/assets/indexes/" + version + ".json")) // Downloads the asset and saves it
    }
    let hashes = try prase(string: stringDownload(url: URL(string: assetIndex)!), key: "hash")
    var threads = 0
    var downloadsLeft = hashes.count
    for i in 0...(hashes.count - 1) {
        let dlqueue1 = DispatchQueue(label: "dlmc")
        dlqueue1.async {
            threads+=1
            do {
                let first2hash = String(hashes[i].prefix(2))
                if !FileManager.default.fileExists(atPath: gameDir + "/assets/objects/" + first2hash + "/" + hashes[i]) {
                    try FileManager.default.createDirectory(at: URL(fileURLWithPath: gameDir + "/assets/objects/" + first2hash), withIntermediateDirectories: true)
                    try dataDownload(url: URL(string: "https://resources.download.minecraft.net/" + first2hash + "/" + hashes[i])!).write(to: URL(fileURLWithPath: gameDir + "/assets/objects/" + first2hash + "/" + hashes[i]))
                    TinyLogger.log.info(msg: "Downloaded asset: " + hashes[i], format: logFormat)
                } else {
#if DEBUG
                    TinyLogger.log.debug(msg: "Already downloaded asset: " + hashes[i], format: logFormat)
#endif
                    usleep(1000)
                }
            } catch {
                TinyLogger.log.error(msg: "\(error)" + hashes[i], format: logFormat)
            }
            threads-=1
            downloadsLeft-=1
        }
        usleep(50)
        while threads >= max_threads {
            usleep(20)
        }
        usleep(50)
    }
    while downloadsLeft > 30 {
        usleep(500)
    }
}
