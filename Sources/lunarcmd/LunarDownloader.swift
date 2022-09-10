// Lunar Client Downloader


import Foundation
import SwiftyJSON
import ZIPFoundation
import TinyLogger
#if os(Linux)
import FoundationNetworking
#endif

func downloadVersionData(branch: String) {
    do {
        var availableVersions: [String] = []
        let availableVersionData = try dataDownload(url: URL(string: "https://api.lunarclientprod.com/launcher/metadata")!)
        let availableVersionDataJSON = JSON(data: availableVersionData)
        for i in 1...availableVersionDataJSON["versions"].count {
            availableVersions.append(availableVersionDataJSON["versions"][i - 1]["id"].string ?? "")
        }
        if noVersionPassed {
            print("Available Versions:")
            for i in 1...availableVersions.count {
                print("\(i): \(availableVersions[i - 1])")
            }
            let chosenVersion = readLine() ?? ""
            if availableVersions.indices.contains((Int(chosenVersion) ?? 0) - 1) {
                versionLaunching = availableVersions[(Int(chosenVersion) ?? 0) - 1]
            } else {
                fputs("Invalid response: \(chosenVersion)\n", stderr)
                exit(-1)
            }
        } else {
            if !availableVersions.contains(versionLaunching) {
                fputs("Error: Version \(versionLaunching) is unavailable. Available versions: \(availableVersions)\n", stderr)
                exit(-1)
            }
        }
    } catch {
        TinyLogger.log.error(msg: "Could not get available versions\n", format: logFormat)
    }
    TinyLogger.log.info(msg: "Fetching Lunar launch data...", format: logFormat)
    let kernelVersionTask = Process()
#if os(macOS)
    kernelVersionTask.executableURL = URL(fileURLWithPath: "/usr/bin/uname")
#else
    kernelVersionTask.executableURL = URL(fileURLWithPath: "/bin/uname")
#endif
    kernelVersionTask.arguments = ["-r"]
    let kernelVersionPipe = Pipe()
    kernelVersionTask.standardOutput = kernelVersionPipe
    try? kernelVersionTask.run()
    kernelVersionTask.waitUntilExit()
    let kernelVersionData = kernelVersionPipe.fileHandleForReading.readDataToEndOfFile()
    let kernelVersion = (String(data: kernelVersionData, encoding: String.Encoding.utf8) ?? "0.0.0").replacingOccurrences(of: "\n", with: "")
    var json: [String:String] = ["hwid": "0", "hwid_private": "0", "os": os, "arch": arch, "launcher_version": "2.12.7", "version": "\(versionLaunching)", "branch": branch, "classifier": "0", "module": "lunar", "os_release": kernelVersion, "launch_type": "OFFLINE"]
    if argv.contains("--no-optifine") {
        json["module"] =  "lunar-noOF"
        if argv.contains("--sodium") {
            fputs("Error: Cannot specify both --no-optifine and --sodium\n", stderr)
            exit(-1)
        }
    }
    if argv.contains("--sodium") {
        json["module"] =  "sodium"
    }
    if argv.contains("--neu") {
        json["module"] =  "neu"
    }
    if argv.contains("--launch-override") {
        var overrideIndex = 0
        for i in argv {
            if i == "--launch-override" {
                json[argv[overrideIndex + 1].components(separatedBy: "=")[0]] = argv[overrideIndex + 1].components(separatedBy: "=")[1]
            }
            overrideIndex+=1
        }
    }
#if DEBUG
    TinyLogger.log.debug(msg: "Request body: \(json)", format: logFormat)
#endif
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
    task.resume() // Sends the request for Lunar version info
    while responseData == "".data(using: .utf8) {
        usleep(500000)
    }
    let jsonresponse = JSON(data: responseData!) // Converts the response to JSON
    if jsonresponse["success"].bool != true {
        TinyLogger.log.fatal(msg: "Error: Could not get launch data\nResponse: \(jsonresponse)\n", format: logFormat)
        exit(-1)
    }
#if DEBUG
    TinyLogger.log.debug(msg: "Launch response: \(jsonresponse)", format: logFormat)
#endif
    do {
        TinyLogger.log.info(msg: "Downloading Lunar assets...", format: logFormat)
        try getLunarAssets(index: try stringDownload(url: URL(string: jsonresponse["textures"]["indexUrl"].string!)!).components(separatedBy: "\n"), base: jsonresponse["textures"]["baseUrl"].string!)
        try getLunarJavaData(artifacts: jsonresponse["launchTypeData"]["artifacts"])
        mainClass = jsonresponse["launchTypeData"]["mainClass"].string ?? "com.moonsworth.lunar.patcher.LunarMain"
        if !FileManager.default.fileExists(atPath: homeDir + "/.lunarcmd_data/offline/\(versionLaunching)/natives_\(arch)") {
            try FileManager.default.unzipItem(at: URL(fileURLWithPath: homeDir + "/.lunarcmd_data/offline/\(versionLaunching)/\(nativesFile)"), to: URL(fileURLWithPath: homeDir + "/.lunarcmd_data/offline/\(versionLaunching)/natives_\(arch)"))
        }
        try downloadJre(jreurl: jsonresponse["jre"]["download"]["url"].string!)
        try downloadLicenses(licenses: jsonresponse["licenses"])
    } catch {
        TinyLogger.log.fatal(msg: "Could not get launch data\n\(error)\n", format: logFormat)
        exit(-1)
    }
}
func downloadLicenses(licenses: JSON) throws { // Function for downloading Lunar Client licenses
    if !FileManager.default.fileExists(atPath: homeDir + "/.lunarcmd_data/licenses") {
        try FileManager.default.createDirectory(at: URL(fileURLWithPath: homeDir + "/.lunarcmd_data/licenses"), withIntermediateDirectories: true)
    }
    var threads3 = 0
    for i in 0...(licenses.count - 1) {
        Thread.detachNewThread {
            threads3+=1
            do {
                if licenses[i]["url"].string != nil {
                    if !FileManager.default.fileExists(atPath: homeDir + "/.lunarcmd_data/licenses/" + licenses[i]["file"].string!) {
                        let data = try dataDownload(url: URL(string: licenses[i]["url"].string!.replacingOccurrences(of: " ", with: "%20"))!)
                        try data.write(to: URL(fileURLWithPath: homeDir + "/.lunarcmd_data/licenses/" + licenses[i]["file"].string!))
                        TinyLogger.log.info(msg: "Downloaded license: " + licenses[i]["file"].string!, format: logFormat)
                    } else {
#if DEBUG
                        TinyLogger.log.debug(msg: "Already downloaded license: " + licenses[i]["file"].string!, format: logFormat)
#endif
                        usleep(500)
                    }
                }
            } catch {
                
            }
            threads3-=1
        }
        usleep(50)
        while threads3 >= max_threads {
            usleep(20)
        }
        usleep(50)
    }
}
func downloadJre(jreurl: String) throws { // Function for downloading Java runtime
    if !FileManager.default.fileExists(atPath: homeDir + "/.lunarcmd_data/jre_\(arch)/\(versionLaunching)") {
        try FileManager.default.createDirectory(at: URL(fileURLWithPath: homeDir + "/.lunarcmd_data/jre_\(arch)/\(versionLaunching)"), withIntermediateDirectories: true)
        TinyLogger.log.info(msg: "Started Java download", format: logFormat)
#if os(Linux)
        let data = try dataDownload(url: URL(string: jreurl)!)
        try data.write(to: URL(fileURLWithPath: "/tmp/jre.tar.gz"))
        let tarex = Process()
        tarex.executableURL = URL(fileURLWithPath: "/usr/bin/tar")
        tarex.arguments = ["-xf", "/tmp/jre.tar.gz"]
        tarex.currentDirectoryURL = URL(fileURLWithPath: homeDir + "/.lunarcmd_data/jre_\(arch)/\(versionLaunching)")
        try tarex.run() // Extracts the tar.gz archive
        tarex.waitUntilExit()
        try FileManager.default.removeItem(at: URL(fileURLWithPath: "/tmp/jre.tar.gz"))
#else
        let data = try dataDownload(url: URL(string: jreurl.replacingOccurrences(of: ".tar.gz", with: ".zip"))!)
        try data.write(to: URL(fileURLWithPath: "/tmp/jre.zip"))
        try FileManager.default.unzipItem(at: URL(fileURLWithPath: "/tmp/jre.zip"), to: URL(fileURLWithPath: homeDir + "/.lunarcmd_data/jre_\(arch)/\(versionLaunching)"))
        try FileManager.default.removeItem(at: URL(fileURLWithPath: "/tmp/jre.zip"))
#endif
        TinyLogger.log.info(msg: "Downloaded Java", format: logFormat)
    } else {
#if DEBUG
        TinyLogger.log.debug(msg: "Already downloaded Java", format: logFormat)
#endif
    }
}
func getLunarJavaData(artifacts: JSON) throws { // Function for downloading Lunar Client jars and natives
    if !FileManager.default.fileExists(atPath: homeDir + "/.lunarcmd_data/offline/\(versionLaunching)") {
        try FileManager.default.createDirectory(at: URL(fileURLWithPath: homeDir + "/.lunarcmd_data/offline/\(versionLaunching)"), withIntermediateDirectories: true)
    }
    if !FileManager.default.fileExists(atPath: homeDir + "/.lunarcmd_data/offline/\(versionLaunching)/sha1") {
        try FileManager.default.createDirectory(at: URL(fileURLWithPath: homeDir + "/.lunarcmd_data/offline/\(versionLaunching)/sha1"), withIntermediateDirectories: true)
    }
    var threads2 = 0
    var downloadsLeft2 = artifacts.count
    for i in 0...(artifacts.count - 1) {
        Thread.detachNewThread {
            threads2+=1
            do {
                if artifacts[i]["url"].string != nil {
                    if artifacts[i]["type"] == "CLASS_PATH" {
                        classPathMap[artifacts[i]["name"].string!] = false
                    }
                    if artifacts[i]["type"] == "EXTERNAL_FILE" {
                        classPathMap[artifacts[i]["name"].string!] = true
                    }
                    let prevsha1 = try? String(contentsOfFile: homeDir + "/.lunarcmd_data/offline/\(versionLaunching)/sha1/\(artifacts[i]["name"].string!).sha1")
                    if prevsha1 != artifacts[i]["sha1"].string! {
                        let data = try dataDownload(url: URL(string: artifacts[i]["url"].string!)!) // Downloads the file
                        try data.write(to: URL(fileURLWithPath: homeDir + "/.lunarcmd_data/offline/\(versionLaunching)/" + artifacts[i]["name"].string!))
                        try? artifacts[i]["sha1"].string!.data(using: .utf8)?.write(to: URL(fileURLWithPath: homeDir + "/.lunarcmd_data/offline/\(versionLaunching)/sha1/\(artifacts[i]["name"].string!).sha1"))
                        TinyLogger.log.info(msg: "Downloaded JAR: " + artifacts[i]["name"].string!, format: logFormat)
                    } else {
#if DEBUG
                        TinyLogger.log.debug(msg: "Already have up-to-date JAR: " + artifacts[i]["name"].string!, format: logFormat)
#endif
                        usleep(100)
                    }
                    if artifacts[i]["name"].string!.contains("natives") {
                        nativesFile = artifacts[i]["name"].string!
                    }
                }
            } catch {
                
            }
            threads2-=1
            downloadsLeft2-=1
        }
        usleep(50)
        while threads2 >= max_threads {
            usleep(20)
        }
        usleep(50)
    }
    while downloadsLeft2 > 0 {
        usleep(500)
    }
}
func getLunarAssets(index: [String], base: String) throws { // Function for downloading Lunar assets
    if !FileManager.default.fileExists(atPath: homeDir + "/.lunarcmd_data/textures") {
        try FileManager.default.createDirectory(at: URL(fileURLWithPath: homeDir + "/.lunarcmd_data/textures"), withIntermediateDirectories: true)
    }
    var downloadsLeft1 = index.count
    var threads1 = 0
    for i in 0...(index.count - 1) {
        Thread.detachNewThread {
            threads1+=1
            do {
                if !FileManager.default.fileExists(atPath: homeDir + "/.lunarcmd_data/textures/" + index[i].components(separatedBy: " ")[0]) {
                    if !FileManager.default.fileExists(atPath: URL(fileURLWithPath: homeDir + "/.lunarcmd_data/textures/" + index[i].components(separatedBy: " ")[0]).deletingLastPathComponent().path) {
                        try FileManager.default.createDirectory(at: URL(fileURLWithPath: homeDir + "/.lunarcmd_data/textures/" + index[i].components(separatedBy: " ")[0]).deletingLastPathComponent(), withIntermediateDirectories: true)
                    }
                    let data = try dataDownload(url: URL(string: base + index[i].components(separatedBy: " ")[1])!) // Downloads the file
                    try data.write(to: URL(fileURLWithPath: homeDir + "/.lunarcmd_data/textures/" + index[i].components(separatedBy: " ")[0]))
                    TinyLogger.log.info(msg: "Downloaded Lunar asset: " + index[i].components(separatedBy: " ")[0], format: logFormat)
                } else {
#if DEBUG
                    TinyLogger.log.debug(msg: "Already downloaded Lunar asset: " + index[i].components(separatedBy: " ")[0], format: logFormat)
#endif
                    usleep(1000)
                }
            } catch {
                TinyLogger.log.error(msg: "\(error)", format: logFormat)
            }
            downloadsLeft1-=1
            threads1-=1
        }
        usleep(50)
        while threads1 >= max_threads {
            usleep(20)
        }
        usleep(50)
    }
    while downloadsLeft1 > 30 {
        usleep(500)
    }
}
