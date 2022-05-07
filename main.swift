//
//  main.swift
//  lunarcmd
//
//  Created by GameParrot on 1/2/22.
//
import Foundation
#if os(Linux)
import FoundationNetworking
#endif
#if os(Linux)
let os = "linux"
let osstring = "linux"
#else
let os = "darwin"
let osstring = "macos"
#endif
#if arch(x86_64)
let arch = "x64"
#else
print("Unsupported CPU arch")
exit(-1)
#endif
let argv = CommandLine.arguments // Sets a variable to the arguments
var gameDir = FileManager.default.currentDirectoryPath + "/lunarcmd"
func unzip(zip: String, to: String) {
    let taskunzip = Process()
    taskunzip.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
    taskunzip.arguments = [zip, "-d", to]
    do {
        try taskunzip.run()
        taskunzip.waitUntilExit()
    } catch {
        
    }
}
func downloadLicenses(licenses: JSON) throws {
    if !FileManager.default.fileExists(atPath: FileManager.default.homeDirectoryForCurrentUser.path + "/.lunarcmd_data/licenses") {
        try FileManager.default.createDirectory(at: URL(fileURLWithPath: FileManager.default.homeDirectoryForCurrentUser.path + "/.lunarcmd_data/licenses"), withIntermediateDirectories: true)
    }
    for i in 0...licenses.count {
        if licenses[i]["url"].string != nil {
            if !FileManager.default.fileExists(atPath: FileManager.default.homeDirectoryForCurrentUser.path + "/.lunarcmd_data/licenses/" + licenses[i]["file"].string!) {
                let data = try Data(contentsOf: URL(string: licenses[i]["url"].string!)!)
                try data.write(to: URL(fileURLWithPath: FileManager.default.homeDirectoryForCurrentUser.path + "/.lunarcmd_data/licenses/" + licenses[i]["file"].string!))
            }
        }
    }
}
func downloadJre(jreurl: String) throws {
    if !FileManager.default.fileExists(atPath: FileManager.default.homeDirectoryForCurrentUser.path + "/.lunarcmd_data/jre/\(argv[1])") {
        try FileManager.default.createDirectory(at: URL(fileURLWithPath: FileManager.default.homeDirectoryForCurrentUser.path + "/.lunarcmd_data/jre/\(argv[1])"), withIntermediateDirectories: true)
        let data = try Data(contentsOf: URL(string: jreurl)!)
        try data.write(to: URL(fileURLWithPath: "/tmp/jre.tar.gz"))
        let tarex = Process()
        tarex.executableURL = URL(fileURLWithPath: "/usr/bin/tar")
        tarex.arguments = ["-xf", "/tmp/jre.tar.gz"]
        tarex.currentDirectoryURL = URL(fileURLWithPath: FileManager.default.homeDirectoryForCurrentUser.path + "/.lunarcmd_data/jre/\(argv[1])")
        try tarex.run()
        tarex.waitUntilExit()
        try FileManager.default.removeItem(at: URL(fileURLWithPath: "/tmp/jre.tar.gz"))
    }
}
func getLunarJavaData(artifacts: JSON) throws {
    if !FileManager.default.fileExists(atPath: FileManager.default.homeDirectoryForCurrentUser.path + "/.lunarcmd_data/offline/\(argv[1])") {
        try FileManager.default.createDirectory(at: URL(fileURLWithPath: FileManager.default.homeDirectoryForCurrentUser.path + "/.lunarcmd_data/offline/\(argv[1])"), withIntermediateDirectories: true)
    }
    for i in 0...artifacts.count {
        if artifacts[i]["url"].string != nil {
            if !FileManager.default.fileExists(atPath: FileManager.default.homeDirectoryForCurrentUser.path + "/.lunarcmd_data/offline/\(argv[1])/" + artifacts[i]["name"].string!) {
                let data = try Data(contentsOf: URL(string: artifacts[i]["url"].string!)!)
                try data.write(to: URL(fileURLWithPath: FileManager.default.homeDirectoryForCurrentUser.path + "/.lunarcmd_data/offline/\(argv[1])/" + artifacts[i]["name"].string!))
            }
        }
    }
}
func getLunarAssets(index: [String], base: String) throws {
    if !FileManager.default.fileExists(atPath: FileManager.default.homeDirectoryForCurrentUser.path + "/.lunarcmd_data/textures") {
        try FileManager.default.createDirectory(at: URL(fileURLWithPath: FileManager.default.homeDirectoryForCurrentUser.path + "/.lunarcmd_data/textures"), withIntermediateDirectories: true)
    }
    for i in index {
        if !FileManager.default.fileExists(atPath: FileManager.default.homeDirectoryForCurrentUser.path + "/.lunarcmd_data/textures/" + i.components(separatedBy: " ")[0]) {
            if !FileManager.default.fileExists(atPath: URL(fileURLWithPath: FileManager.default.homeDirectoryForCurrentUser.path + "/.lunarcmd_data/textures/" + i.components(separatedBy: " ")[0]).deletingLastPathComponent().path) {
                try FileManager.default.createDirectory(at: URL(fileURLWithPath: FileManager.default.homeDirectoryForCurrentUser.path + "/.lunarcmd_data/textures/" + i.components(separatedBy: " ")[0]).deletingLastPathComponent(), withIntermediateDirectories: true)
            }
            let data = try Data(contentsOf: URL(string: base + i.components(separatedBy: " ")[1])!)
            try data.write(to: URL(fileURLWithPath: FileManager.default.homeDirectoryForCurrentUser.path + "/.lunarcmd_data/textures/" + i.components(separatedBy: " ")[0]))
            print("Downloaded Lunar asset:", i.components(separatedBy: " ")[0])
        }
    }
}
func downloadVersionData() {
    let json: [String:String] = ["hwid": "0", "hwid_private": "0", "os": os, "arch": arch, "launcher_version": "2.10.1", "version": "\(argv[1])", "branch": "master", "launch_type": "0", "classifier": "0"]
    
    let jsonData = try? JSONSerialization.data(withJSONObject: json)
    
    // create post request
    let url = URL(string: "https://api.lunarclientprod.com/launcher/launch")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    
    // insert json data to the request
    request.httpBody = jsonData
    var responseData = "".data(using: .utf8)

    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        guard let data = data, error == nil else {
            print(error?.localizedDescription ?? "No data")
            return
        }
        responseData = data
    }
    task.resume()
    while responseData == "".data(using: .utf8) {
        usleep(500000)
    }
    let jsonresponse = JSON(data: responseData!)
    do {
        try getLunarAssets(index: try String(contentsOf: URL(string: jsonresponse["textures"]["indexUrl"].string!)!).components(separatedBy: "\n"), base: jsonresponse["textures"]["baseUrl"].string!)
        try getLunarJavaData(artifacts: jsonresponse["launchTypeData"]["artifacts"])
        if !FileManager.default.fileExists(atPath: FileManager.default.homeDirectoryForCurrentUser.path + "/.lunarcmd_data/offline/\(argv[1])/natives") {
            unzip(zip: FileManager.default.homeDirectoryForCurrentUser.path + "/.lunarcmd_data/offline/\(argv[1])/natives-\(osstring)-\(arch).zip", to: FileManager.default.homeDirectoryForCurrentUser.path + "/.lunarcmd_data/offline/\(argv[1])/natives")
        }
        try downloadJre(jreurl: jsonresponse["jre"]["download"]["url"].string!)
        try downloadLicenses(licenses: jsonresponse["licenses"])
    } catch {
        print(error)
    }
}
if argv.count > 1 {
    if argv.contains("-h") || argv.contains("--help") {
        print("usage: lunarcmd <version> [--gameDir <game directory>] [--server <server to auto join>] [--mem <RAM allocation>]")
        exit(0)
    }
    print("Downloading Lunar assets...")
    downloadVersionData()
    if !FileManager.default.fileExists(atPath: FileManager.default.homeDirectoryForCurrentUser.path + "/.lunarcmd_data/jre/\(argv[1])") {
        fputs("Error: version is invalid or it has never been launched before in Lunar Client\n", stderr)
        exit(-1)
    }
    if argv.contains("--gameDir") {
        gameDir = URL(fileURLWithPath: argv[argv.firstIndex(of: "--gameDir")! + 1]).path // Sets the game directory to the --gameDir argument value if specified
    }
    print("Updating asset index...")
    getAssets(version: argv[1]) // Updates the asset index
    print("Preparing to launch Lunar Client \(argv[1])")
    let lunarCmd = Process()
    let jreVersionPath = FileManager.default.homeDirectoryForCurrentUser.path + "/.lunarcmd_data/jre/\(argv[1])" // Sets the path to the Java folder
    try! lunarCmd.executableURL = URL(fileURLWithPath: jreVersionPath + "/" + FileManager.default.contentsOfDirectory(atPath: jreVersionPath)[0] + "/bin/java")
    lunarCmd.arguments = []
    if os == "darwin" {
    if Int(argv[1].components(separatedBy: ".")[1])! > 12 {
        lunarCmd.arguments?.append("-XstartOnFirstThread")
    } else {
        lunarCmd.arguments?.append("-Xdock:name=Lunar Client") // Sets the dock name for versions older than 1.13 on Mac
        lunarCmd.arguments?.append("-Xdock:icon=/Applications/Lunar Client.app/Contents/Resources/Lunar Client.icns")
    }
    }
    var repeatIndex = 0
    // The 8 lines below this comment set the JVM arguments
    lunarCmd.arguments?.append("--add-modules")
    lunarCmd.arguments?.append("jdk.naming.dns")
    lunarCmd.arguments?.append("--add-exports")
    lunarCmd.arguments?.append("jdk.naming.dns/com.sun.jndi.dns=java.naming")
    lunarCmd.arguments?.append("-Djna.boot.library.path=natives")
    lunarCmd.arguments?.append("--add-opens")
    lunarCmd.arguments?.append("java.base/java.io=ALL-UNNAMED")
    lunarCmd.arguments?.append("-cp")
    var classpath = ""
    for i in try! FileManager.default.contentsOfDirectory(atPath: FileManager.default.homeDirectoryForCurrentUser.path + "/.lunarcmd_data/offline/\(argv[1])") {
        if i.contains(".jar") || i.contains("optifine") {
            repeatIndex+=1
            if repeatIndex != 1 {
                classpath = classpath + ":" + i
            } else {
                classpath = classpath + i
            }
        }
    }
    lunarCmd.arguments?.append(classpath) // Adds the classpath
    if argv.contains("--mem") {
        lunarCmd.arguments?.append("-Xms" + argv[argv.firstIndex(of: "--mem")! + 1])
        lunarCmd.arguments?.append("-Xmx" + argv[argv.firstIndex(of: "--mem")! + 1])
    }
    lunarCmd.arguments?.append("-Djava.library.path=natives") // Sets more JVM args
    lunarCmd.arguments?.append("-XX:+DisableAttachMechanism")
    if os == "darwin" {
    lunarCmd.arguments?.append("-Dapple.awt.application.appearance=system")
    }
    lunarCmd.arguments?.append("-Dlog4j2.formatMsgNoLookups=true")
    lunarCmd.arguments?.append("com.moonsworth.lunar.patcher.LunarMain")
    lunarCmd.arguments?.append("--version") // Sets game args
    lunarCmd.arguments?.append(argv[1])
    lunarCmd.arguments?.append("--accessToken")
    lunarCmd.arguments?.append("0")
    lunarCmd.arguments?.append("--assetIndex")
    lunarCmd.arguments?.append(argv[1])
    lunarCmd.arguments?.append("--texturesDir")
    lunarCmd.arguments?.append(FileManager.default.homeDirectoryForCurrentUser.path + "/.lunarcmd_data/textures")
    lunarCmd.arguments?.append("--gameDir")
    lunarCmd.arguments?.append(gameDir)
    if argv.contains("--server") {
        lunarCmd.arguments?.append("--server=" + argv[argv.firstIndex(of: "--server")! + 1])
    }
    if os == "darwin" {
    lunarCmd.arguments?.append("-NSRequiresAquaSystemAppearance")
    lunarCmd.arguments?.append("False")
    }
    lunarCmd.currentDirectoryURL = URL(fileURLWithPath: FileManager.default.homeDirectoryForCurrentUser.path + "/.lunarcmd_data/offline/\(argv[1])/")
    do {
        try lunarCmd.run()
    } catch {
        
    }
    signal(SIGINT, SIG_IGN)

    let sigintSource = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
    sigintSource.setEventHandler {
        lunarCmd.interrupt()
    }
    sigintSource.resume()
    lunarCmd.waitUntilExit()
    
} else {
    fputs("Error: not enough options\nusage: lunarcmd <version> [--gameDir <game directory>] [--server <server to auto join>] [--mem <RAM allocation>]\n", stderr)
    exit(-1)
}
func prase(string: String, key: String) -> [String] {
    var keys = [""]
    for i in string.components(separatedBy: "\"" + key + "\": \"") {
        keys.append(i.components(separatedBy: "\"")[0])
    }
    keys.remove(at: 0)
    keys.remove(at: 0)
    return keys
}
func getAssets(version: String) {
    let versions = try! prase(string: String(contentsOf: URL(string: "https://launchermeta.mojang.com/mc/game/version_manifest.json")!), key: "id")
   let jsons = try! prase(string: String(contentsOf: URL(string: "https://launchermeta.mojang.com/mc/game/version_manifest.json")!), key: "url")
    let jsonData = try! String(contentsOf: URL(string: jsons[versions.firstIndex(of: version)!])!)
   let assetIndex = prase(string: jsonData, key: "url")[0]
    if !FileManager.default.fileExists(atPath: gameDir + "/assets/indexes/") {
        try! FileManager.default.createDirectory(at: URL(fileURLWithPath: gameDir + "/assets/indexes"), withIntermediateDirectories: true)
    }
    if !FileManager.default.fileExists(atPath: gameDir + "/assets/indexes/" + version + ".json") {
        try! Data(contentsOf: URL(string: assetIndex)!).write(to: URL(fileURLWithPath: gameDir + "/assets/indexes/" + version + ".json")) // Downloads the asset and saves it
    }
   let hashes = try! prase(string: String(contentsOf: URL(string: assetIndex)!), key: "hash")
   for i in 0...hashes.count - 1 {
       let first2hash = String(hashes[i].prefix(2))
       if !FileManager.default.fileExists(atPath: gameDir + "/assets/objects/" + first2hash + "/" + hashes[i]) {
           try! FileManager.default.createDirectory(at: URL(fileURLWithPath: gameDir + "/assets/objects/" + first2hash), withIntermediateDirectories: true)
           try! Data(contentsOf: URL(string: "https://resources.download.minecraft.net/" + first2hash + "/" + hashes[i])!).write(to: URL(fileURLWithPath: gameDir + "/assets/objects/" + first2hash + "/" + hashes[i]))
           print("Downloaded asset:", hashes[i])
       }
   }
}
