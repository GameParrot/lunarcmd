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
signal(SIGILL) { s in
    print("Please report this crash at https://github.com/GameParrot/lunarcmd/issues and include the following information:")
    print(Thread.callStackSymbols.joined(separator: "\n"))
    print("Exit code:", s)
    exit(s)
}
signal(SIGABRT) { s in
    print("Please report this crash at https://github.com/GameParrot/lunarcmd/issues and include the following information:")
    print(Thread.callStackSymbols.joined(separator: "\n"))
    print("Exit code:", s)
    exit(s)
}
signal(SIGSEGV) { s in
    print("Please report this crash at https://github.com/GameParrot/lunarcmd/issues and include the following information:")
    print(Thread.callStackSymbols.joined(separator: "\n"))
    print("Exit code:", s)
    exit(s)
}
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
fputs("Unsupported CPU arch\n", stderr)
exit(-1)
#endif
setbuf(stdout, nil)
setbuf(stderr, nil)
let argv = CommandLine.arguments // Sets a variable to the arguments
let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
var gameDir = FileManager.default.currentDirectoryPath + "/lunarcmd"
let dlqueue1 = DispatchQueue(label: "com.gameparrot.DownloadThread1")
let dlqueue2 = DispatchQueue(label: "com.gameparrot.DownloadThread2")
let dlqueue3 = DispatchQueue(label: "com.gameparrot.DownloadThread3")
let dlqueue4 = DispatchQueue(label: "com.gameparrot.DownloadThread4")
let dlqueue5 = DispatchQueue(label: "com.gameparrot.DownloadThread5")
let dlqueue6 = DispatchQueue(label: "com.gameparrot.DownloadThread6")
let dlqueue7 = DispatchQueue(label: "com.gameparrot.DownloadThread7")
let dlqueue8 = DispatchQueue(label: "com.gameparrot.DownloadThread8")
func unzip(zip: String, to: String) { // Function for unzipping
    let taskunzip = Process()
    taskunzip.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
    taskunzip.arguments = [zip, "-d", to]
    do {
        try taskunzip.run()
        taskunzip.waitUntilExit()
    } catch {
        
    }
}
func downloadLicenses(licenses: JSON) throws { // Function for downloading Lunar Client licenses
    if !FileManager.default.fileExists(atPath: homeDir + "/.lunarcmd_data/licenses") {
        try FileManager.default.createDirectory(at: URL(fileURLWithPath: homeDir + "/.lunarcmd_data/licenses"), withIntermediateDirectories: true)
    }
    for i in 0...licenses.count {
        if licenses[i]["url"].string != nil {
            if !FileManager.default.fileExists(atPath: homeDir + "/.lunarcmd_data/licenses/" + licenses[i]["file"].string!) {
                let data = try Data(contentsOf: URL(string: licenses[i]["url"].string!)!)
                try data.write(to: URL(fileURLWithPath: homeDir + "/.lunarcmd_data/licenses/" + licenses[i]["file"].string!))
                print("Downloaded license:", licenses[i]["file"].string!)
            }
        }
    }
}
func downloadJre(jreurl: String) throws { // Function for downloading Java runtime
    if !FileManager.default.fileExists(atPath: homeDir + "/.lunarcmd_data/jre/\(argv[1])") {
        try FileManager.default.createDirectory(at: URL(fileURLWithPath: homeDir + "/.lunarcmd_data/jre/\(argv[1])"), withIntermediateDirectories: true)
        let data = try Data(contentsOf: URL(string: jreurl)!)
        try data.write(to: URL(fileURLWithPath: "/tmp/jre.tar.gz"))
        let tarex = Process()
        tarex.executableURL = URL(fileURLWithPath: "/usr/bin/tar")
        tarex.arguments = ["-xf", "/tmp/jre.tar.gz"]
        tarex.currentDirectoryURL = URL(fileURLWithPath: homeDir + "/.lunarcmd_data/jre/\(argv[1])")
        try tarex.run() // Extracts the tar.gz archive
        tarex.waitUntilExit()
        try FileManager.default.removeItem(at: URL(fileURLWithPath: "/tmp/jre.tar.gz"))
        print("Downloaded Java")
    }
}
func downloadVersionData(branch: String) {
    let json: [String:String] = ["hwid": "0", "hwid_private": "0", "os": os, "arch": arch, "launcher_version": "2.10.1", "version": "\(argv[1])", "branch": branch, "launch_type": "0", "classifier": "0"]
    
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
        fputs("Error: Could not get launch data\nResponse: \(jsonresponse)\n", stderr)
        exit(-1)
    }
    do {
        try getLunarAssets(index: try String(contentsOf: URL(string: jsonresponse["textures"]["indexUrl"].string!)!).components(separatedBy: "\n"), base: jsonresponse["textures"]["baseUrl"].string!)
        try getLunarJavaData(artifacts: jsonresponse["launchTypeData"]["artifacts"])
        if !FileManager.default.fileExists(atPath: homeDir + "/.lunarcmd_data/offline/\(argv[1])/natives") {
            unzip(zip: homeDir + "/.lunarcmd_data/offline/\(argv[1])/natives-\(osstring)-\(arch).zip", to: homeDir + "/.lunarcmd_data/offline/\(argv[1])/natives")
        }
        try downloadJre(jreurl: jsonresponse["jre"]["download"]["url"].string!)
        try downloadLicenses(licenses: jsonresponse["licenses"])
    } catch {
        fputs("Could not get launch data\n\(error)\n", stderr)
        exit(-1)
    }
}
if argv.count > 1 {
    if argv.contains("-h") || argv.contains("--help") {
        print("Overview: LunarCmd launches Lunar Client from the command line.\nusage: lunarcmd <version> [--gameDir <game directory>] [--server <server to auto join>] [--mem <RAM allocation>] [--width <window width>] [--height <window height>] [--branch <lunar branch>] [--jvm <jvm argument>] [--javaExec <java executable>] [--storageDir <lunar client storage directory>] [--logAddons] [--downloadOnly] [--disablePythonSignIn] [--quitOnLeave]\nArgument description:\n<version> - (Required) The Lunar Client version to launch\n--gameDir <game directory> - The directory to use for game settings and worlds\n--server <server to auto join> - A server to connect to automatically when the game launches\n--mem <RAM allocation> - How much RAM to allocate to the game\n--width <window width> - The default width of the window\n--height <window width> - The default height of the window\n--branch <lunar branch> - The branch to use for the game\n--jvm <jvm argument> - Argument to pass to the JVM\n--javaExec <java executable> - The path to the Java executable\n--storageDir <lunar client storage directory> - Directory to use for Lunar Client and mod settings\n--logAddons - Enables coloring certain log messages and prints chat messages directly\n--downloadOnly - Downloads the game and assets without starting it\n--disablePythonSignIn - Disables the use of the Python sign in script\n--quitOnLeave - Quits the game when you leave a server. --server <server to auto join> must also be passed. `production.spectrum.moonsworth.cloud.:222` must also be in your server list for this to work.")
        exit(0)
    }
    // Argument checks below
    if argv.contains("--server") {
        if !argv.indices.contains(argv.firstIndex(of: "--server")! + 1) {
            fputs("Error: --server requires a server to be specified\n", stderr)
            exit(-1)
        }
    }
    if argv.contains("--quitOnLeave") {
        if !argv.contains("--server") {
            fputs("Error: --server mussed be passed with --quitOnLeave.\n", stderr)
            exit(-1)
        }
    }
    if argv.contains("--jvm") {
        var checkIndex = 0
        for i in argv {
            if i == "--jvm" {
                if !argv.indices.contains(checkIndex + 1) {
                    fputs("Error: --jvm requires an option to be specified\n", stderr)
                    exit(-1)
                }
            }
            checkIndex+=1
        }
    }
    if argv.contains("--gameDir") {
        if !argv.indices.contains(argv.firstIndex(of: "--gameDir")! + 1) {
            fputs("Error: --gameDir requires a game directory to be specified\n", stderr)
            exit(-1)
        }
    }
    if argv.contains("--javaExec") {
        if !argv.indices.contains(argv.firstIndex(of: "--javaExec")! + 1) {
            fputs("Error: --javaExec requires a java executable to be specified\n", stderr)
            exit(-1)
        }
    }
    if argv.contains("--storageDir") {
        if !argv.indices.contains(argv.firstIndex(of: "--storageDir")! + 1) {
            fputs("Error: --storageDir requires a storage directory to be specified\n", stderr)
            exit(-1)
        }
    }
    if argv.contains("--mem") {
        if !argv.indices.contains(argv.firstIndex(of: "--mem")! + 1) {
            fputs("Error: --mem requires an amount of memory to be specified\n", stderr)
            exit(-1)
        }
    }
    if argv.contains("--width") {
        if !argv.indices.contains(argv.firstIndex(of: "--width")! + 1) {
            fputs("Error: --width requires the window width to be specified\n", stderr)
            exit(-1)
        }
    }
    if argv.contains("--height") {
        if !argv.indices.contains(argv.firstIndex(of: "--height")! + 1) {
            fputs("Error: --height requires the window height to be specified\n", stderr)
            exit(-1)
        }
    }
    if argv.contains("--branch") {
        if !argv.indices.contains(argv.firstIndex(of: "--branch")! + 1) {
            fputs("Error: --branch requires the branch to be specified\n", stderr)
            exit(-1)
        }
    }
    var branch = "master"
    if argv.contains("--branch") {
        branch = argv[argv.firstIndex(of: "--branch")! + 1]
    }
    print("Downloading Lunar assets...")
    downloadVersionData(branch:  branch)
    if argv.contains("--gameDir") {
        gameDir = URL(fileURLWithPath: argv[argv.firstIndex(of: "--gameDir")! + 1]).path // Sets the game directory to the --gameDir argument value if specified
    }
    var javaExec = "default"
    if argv.contains("--javaExec") {
        javaExec = argv[argv.firstIndex(of: "--javaExec")! + 1]
    }
    var storageDir = ""
    if argv.contains("--storageDir") {
        storageDir = argv[argv.firstIndex(of: "--storageDir")! + 1]
    }
    var logAddons = false
    if argv.contains("--logAddons") {
        logAddons = true
    }
    print("Updating asset index...")
    do {
        try getAssets(version: argv[1]) // Updates the asset index
    } catch {
        fputs("Error downloading assets\n\(error)\n", stderr)
        exit(-1)
    }
    if argv.contains("--downloadOnly") {
        print("--downloadOnly passed, exiting")
        exit(0)
    }
    print("Preparing to launch Lunar Client \(argv[1])")
    let lunarCmd = Process()
    do {
        let jreVersionPath = homeDir + "/.lunarcmd_data/jre/\(argv[1])" // Sets the path to the Java folder
        if javaExec == "default" {
            try lunarCmd.executableURL = URL(fileURLWithPath: jreVersionPath + "/" + FileManager.default.contentsOfDirectory(atPath: jreVersionPath)[0] + "/bin/java")
        } else {
            lunarCmd.executableURL = URL(fileURLWithPath: javaExec)
        }
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
        for i in try FileManager.default.contentsOfDirectory(atPath: homeDir + "/.lunarcmd_data/offline/\(argv[1])") {
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
        if storageDir != "" {
            lunarCmd.arguments?.append("-Duser.home=" + storageDir)
        }
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
        if argv.contains("--jvm") {
            var jvmArgIndex = 0
            for i in argv { // Adds JVM args passed with --jvm
                if i == "--jvm" {
                    lunarCmd.arguments?.append(argv[jvmArgIndex + 1])
                }
                jvmArgIndex+=1
            }
        }
        lunarCmd.arguments?.append("com.moonsworth.lunar.patcher.LunarMain")
        lunarCmd.arguments?.append("--version") // Sets game args
        lunarCmd.arguments?.append(argv[1])
        lunarCmd.arguments?.append("--accessToken")
        lunarCmd.arguments?.append("0")
        lunarCmd.arguments?.append("--assetIndex")
        lunarCmd.arguments?.append(argv[1])
        lunarCmd.arguments?.append("--texturesDir")
        lunarCmd.arguments?.append(homeDir + "/.lunarcmd_data/textures")
        lunarCmd.arguments?.append("--gameDir")
        lunarCmd.arguments?.append(gameDir)
        if argv.contains("--server") {
            lunarCmd.arguments?.append("--server=" + argv[argv.firstIndex(of: "--server")! + 1])
        }
        if argv.contains("--width") {
            lunarCmd.arguments?.append("--width=" + argv[argv.firstIndex(of: "--width")! + 1])
        }
        if argv.contains("--height") {
            lunarCmd.arguments?.append("--height=" + argv[argv.firstIndex(of: "--height")! + 1])
        }
        if os == "darwin" {
            lunarCmd.arguments?.append("-NSRequiresAquaSystemAppearance")
            lunarCmd.arguments?.append("False")
        }
        lunarCmd.currentDirectoryURL = URL(fileURLWithPath: homeDir + "/.lunarcmd_data/offline/\(argv[1])/")
        print("Java executable: \(lunarCmd.executableURL!.path)\nArguments: \(lunarCmd.arguments!)")
        let pipe = Pipe()
        lunarCmd.standardOutput = pipe
        let outHandle = pipe.fileHandleForReading
        
        outHandle.readabilityHandler = { pipe in
            if let line = String(data: pipe.availableData, encoding: String.Encoding.utf8) {
                if line.contains("Can't ping production.spectrum.moonsworth.cloud.:222") && argv.contains("--quitOnLeave") {
                    lunarCmd.interrupt()
                }
                if line.contains("Auth] No launcher open") && !line.contains("CHAT") && !argv.contains("--disablePythonSignIn") {
                    startSignIn()
                }
                if logAddons {
                    let linee = line.components(separatedBy: " thread/INFO]: [CHAT] ")
                    let line = linee[linee.count - 1]
                    let print1 = "\u{001B}[0;0m" + line.replacingOccurrences(of: "§r", with: "\u{001B}[0;0m").replacingOccurrences(of: "§l", with: "\u{001B}[1m").replacingOccurrences(of: "§0", with: "\u{001B}[38;5;232m").replacingOccurrences(of: "§1", with: "\u{001B}[38;5;19m")
                    let print2 = print1.replacingOccurrences(of: "§2", with: "\u{001B}[38;5;34m").replacingOccurrences(of: "§3", with: "\u{001B}[38;5;30m").replacingOccurrences(of: "§4", with: "\u{001B}[38;5;88m").replacingOccurrences(of: "§5", with: "\u{001B}[38;5;92m").replacingOccurrences(of: "§6", with: "\u{001B}[38;5;214m")
                    let print3 = print2.replacingOccurrences(of: "§7", with: "\u{001B}[38;5;250m").replacingOccurrences(of: "§8", with: "\u{001B}[38;5;243m").replacingOccurrences(of: "§9", with: "\u{001B}[38;5;27m").replacingOccurrences(of: "§a", with: "\u{001B}[38;5;46m").replacingOccurrences(of: "§b", with: "\u{001B}[38;5;51m")
                    let print4 = print3.replacingOccurrences(of: "§c", with: "\u{001B}[38;5;203m").replacingOccurrences(of: "§d", with: "\u{001B}[38;5;201m").replacingOccurrences(of: "§e", with: "\u{001B}[38;5;226m").replacingOccurrences(of: "§f", with: "\u{001B}[38;5;231m")
                    let printfinal = print4.replacingOccurrences(of: "/WARN]:", with: "\u{001B}[0;33m/WARN]:").replacingOccurrences(of: "/FATAL]:", with: "\u{001B}[0;31m/FATAL]:").replacingOccurrences(of: "/ERROR]:", with: "\u{001B}[0;31m/ERROR]:")
                    if (line.contains("/ERROR]:") || line.contains("/WARN]:") || line.contains("/FATAL]:")) && !line.contains("CHAT") {
                        fputs(printfinal, stderr)
                    } else {
                        print(printfinal, terminator:"")
                    }
                } else {
                    print(line, terminator:"")
                }
            } else {
                print("Error decoding data: \(pipe.availableData)")
            }
        }
        if logAddons {
            let pipe1 = Pipe()
            lunarCmd.standardError = pipe1
            let outHandle1 = pipe1.fileHandleForReading
            outHandle1.readabilityHandler = { pipe1 in
                if let line = String(data: pipe1.availableData, encoding: String.Encoding.utf8) {
                    print("\u{001B}[0;0m\u{001B}[0;31m" + line, terminator:"")
                } else {
                    print("Error decoding data: \(pipe1.availableData)")
                }
            }
        }
        try lunarCmd.run()
    } catch {
        fputs("Error launching game\n\(error)\n", stderr)
        exit(-1)
    }
    signal(SIGINT, SIG_IGN)
    
    let sigintSource = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
    sigintSource.setEventHandler {
        lunarCmd.interrupt()
    }
    sigintSource.resume()
    lunarCmd.waitUntilExit()
    if logAddons {
        print("\u{001B}[0;0m", terminator: "")
    }
} else {
    fputs("Error: not enough options\nusage: lunarcmd <version> [--gameDir <game directory>] [--server <server to auto join>] [--mem <RAM allocation>] [--width <window width>] [--height <window height>] [--branch <lunar branch>] [--jvm <jvm argument>] [--javaExec <java executable>] [--storageDir <lunar client storage directory>] [--logAddons] [--downloadOnly] [--disablePythonSignIn] [--quitOnLeave]\nPass --help for more information\n", stderr)
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
func getLunarJavaData(artifacts: JSON) throws { // Function for downloading Lunar Client jars and natives
    if !FileManager.default.fileExists(atPath: homeDir + "/.lunarcmd_data/offline/\(argv[1])") {
        try FileManager.default.createDirectory(at: URL(fileURLWithPath: homeDir + "/.lunarcmd_data/offline/\(argv[1])"), withIntermediateDirectories: true)
    }
    var dlJava1Done = false
    var dlJava2Done = false
    var dlJava3Done = false
    var dlJava4Done = false
    let dlJava1List = artifacts.count / 4
    let dlJava2List = artifacts.count / 2
    let dlJava3List = (artifacts.count / 2) + (artifacts.count / 4)
    let dlJava4List = artifacts.count
    dlqueue1.async {
        do {
            for i in 0...dlJava1List {
                if artifacts[i]["url"].string != nil {
                    let data = try Data(contentsOf: URL(string: artifacts[i]["url"].string!)!) // Downloads the file
                    try data.write(to: URL(fileURLWithPath: homeDir + "/.lunarcmd_data/offline/\(argv[1])/" + artifacts[i]["name"].string!))
                    print("Downloaded JAR:", artifacts[i]["name"].string!)
                }
            }
        } catch {
            fputs("Could not get launch data\n\(error)\n", stderr)
            exit(-1)
        }
        dlJava1Done = true
    }
    
    dlqueue2.async {
        do {
            for i in (dlJava1List + 1)...dlJava2List {
                if artifacts[i]["url"].string != nil {
                    let data = try Data(contentsOf: URL(string: artifacts[i]["url"].string!)!) // Downloads the file
                    try data.write(to: URL(fileURLWithPath: homeDir + "/.lunarcmd_data/offline/\(argv[1])/" + artifacts[i]["name"].string!))
                    print("Downloaded JAR:", artifacts[i]["name"].string!)
                }
            }
        } catch {
            fputs("Could not get launch data\n\(error)\n", stderr)
            exit(-1)
        }
        dlJava2Done = true
    }
    dlqueue3.async {
        do {
            for i in (dlJava2List + 1)...dlJava3List {
                if artifacts[i]["url"].string != nil {
                    let data = try Data(contentsOf: URL(string: artifacts[i]["url"].string!)!) // Downloads the file
                    try data.write(to: URL(fileURLWithPath: homeDir + "/.lunarcmd_data/offline/\(argv[1])/" + artifacts[i]["name"].string!))
                    print("Downloaded JAR:", artifacts[i]["name"].string!)
                }
            }
        } catch {
            fputs("Could not get launch data\n\(error)\n", stderr)
            exit(-1)
        }
        dlJava3Done = true
    }
    
    dlqueue2.async {
        do {
            for i in (dlJava3List + 1)...dlJava4List {
                if artifacts[i]["url"].string != nil {
                    let data = try Data(contentsOf: URL(string: artifacts[i]["url"].string!)!) // Downloads the file
                    try data.write(to: URL(fileURLWithPath: homeDir + "/.lunarcmd_data/offline/\(argv[1])/" + artifacts[i]["name"].string!))
                    print("Downloaded JAR:", artifacts[i]["name"].string!)
                }
            }
        } catch {
            fputs("Could not get launch data\n\(error)\n", stderr)
            exit(-1)
        }
        dlJava4Done = true
    }
    while !dlJava1Done || !dlJava2Done || !dlJava3Done || !dlJava4Done {
        usleep(500000)
    }
}
func startSignIn() {
    let signin = Process()
    signin.executableURL = URL(fileURLWithPath: "/bin/sh")
    signin.arguments = ["-c", "python3 \"$(dirname '\(ProcessInfo.processInfo.arguments.first!)')/../lib/lunarcmd/signin.py\""]
    let pipe = Pipe()
    signin.standardOutput = pipe
    signin.standardError = pipe
    let outHandle = pipe.fileHandleForReading
    outHandle.readabilityHandler = { pipe in
        if let line = String(data: pipe.availableData, encoding: String.Encoding.utf8) {
            if line.contains("No such file or directory") {
                fputs("\u{001b}[31;1mError: Could not find the Python sign in script.\u{001b}[0m\n", stderr)
                return
            }
            if line.contains("ModuleNotFoundError") {
                fputs("\u{001b}[31;1mError: You need Python modules `pywebview` and `procbridge` to use the Python sign in.\u{001b}[0m\n", stderr)
                return
            }
            if line.contains("not found") {
                fputs("\u{001b}[31;1mError: Python 3 is required to sign in.\u{001b}[0m\n", stderr)
                return
            }
        }
    }
    do {
        try signin.run()
    } catch {
        
    }
    print("\u{001b}[32;1mSign in should have failed. The sign in listener has been started, so you should be able to sign in now.\u{001b}[0m")
}
func getAssets(version: String) throws {
    let versions = try prase(string: String(contentsOf: URL(string: "https://launchermeta.mojang.com/mc/game/version_manifest.json")!), key: "id")
    let jsons = try prase(string: String(contentsOf: URL(string: "https://launchermeta.mojang.com/mc/game/version_manifest.json")!), key: "url")
    let jsonData = try String(contentsOf: URL(string: jsons[versions.firstIndex(of: version)!])!)
    let assetIndex = prase(string: jsonData, key: "url")[0]
    if !FileManager.default.fileExists(atPath: gameDir + "/assets/indexes/") {
        try FileManager.default.createDirectory(at: URL(fileURLWithPath: gameDir + "/assets/indexes"), withIntermediateDirectories: true)
    }
    if !FileManager.default.fileExists(atPath: gameDir + "/assets/indexes/" + version + ".json") {
        try Data(contentsOf: URL(string: assetIndex)!).write(to: URL(fileURLWithPath: gameDir + "/assets/indexes/" + version + ".json")) // Downloads the asset and saves it
    }
    let hashes = try prase(string: String(contentsOf: URL(string: assetIndex)!), key: "hash")
    let hashcount = hashes.count - 1
    var dlMcAssets1Done = false
    var dlMcAssets2Done = false
    var dlMcAssets3Done = false
    var dlMcAssets4Done = false
    var dlMcAssets5Done = false
    var dlMcAssets6Done = false
    var dlMcAssets7Done = false
    var dlMcAssets8Done = false
    let dlMcAssets1List = (hashcount / 8) - 1
    let dlMcAssets2List = (hashcount / 4) - 1
    let dlMcAssets3List = ((hashcount / 4) + (hashcount / 8) - 1)
    let dlMcAssets4List = (hashcount / 2) - 1
    let dlMcAssets5List = ((hashcount / 2) + (hashcount / 8) - 1)
    let dlMcAssets6List = ((hashcount / 2) + (hashcount / 4)) - 1
    let dlMcAssets7List = ((hashcount / 2) + (hashcount / 4) + (hashcount / 8)) - 1
    let dlMcAssets8List = hashcount - 1
    dlqueue1.async {
        for i in 0...dlMcAssets1List {
            do {
                try downloadMcAsset(i: i, hashes: hashes)
            } catch {
                do {
                    try downloadMcAsset(i: i, hashes: hashes)
                } catch {
                    fputs("Failed to download asset \(hashes[i])\n\(error)\n", stderr)
                }
            }
        }
        dlMcAssets1Done = true
    }
    dlqueue2.async {
        for i in (dlMcAssets1List + 1)...dlMcAssets2List {
            do {
                try downloadMcAsset(i: i, hashes: hashes)
            } catch {
                do {
                    try downloadMcAsset(i: i, hashes: hashes)
                } catch {
                    fputs("Failed to download asset \(hashes[i])\n\(error)\n", stderr)
                }
            }
        }
        dlMcAssets2Done = true
    }
    dlqueue3.async {
        for i in (dlMcAssets2List + 1)...dlMcAssets3List {
            do {
                try downloadMcAsset(i: i, hashes: hashes)
            } catch {
                do {
                    try downloadMcAsset(i: i, hashes: hashes)
                } catch {
                    fputs("Failed to download asset \(hashes[i])\n\(error)\n", stderr)
                }
            }
        }
        dlMcAssets3Done = true
    }
    dlqueue4.async {
        for i in (dlMcAssets3List + 1)...dlMcAssets4List {
            do {
                try downloadMcAsset(i: i, hashes: hashes)
            } catch {
                do {
                    try downloadMcAsset(i: i, hashes: hashes)
                } catch {
                    fputs("Failed to download asset \(hashes[i])\n\(error)\n", stderr)
                }
            }
        }
        dlMcAssets4Done = true
    }
    dlqueue5.async {
        for i in (dlMcAssets4List + 1)...dlMcAssets5List {
            do {
                try downloadMcAsset(i: i, hashes: hashes)
            } catch {
                do {
                    try downloadMcAsset(i: i, hashes: hashes)
                } catch {
                    fputs("Failed to download asset \(hashes[i])\n\(error)\n", stderr)
                }
            }
        }
        dlMcAssets5Done = true
    }
    dlqueue6.async {
        for i in (dlMcAssets5List + 1)...dlMcAssets6List {
            do {
                try downloadMcAsset(i: i, hashes: hashes)
            } catch {
                do {
                    try downloadMcAsset(i: i, hashes: hashes)
                } catch {
                    fputs("Failed to download asset \(hashes[i])\n\(error)\n", stderr)
                }
            }
        }
        dlMcAssets6Done = true
    }
    dlqueue7.async {
        for i in (dlMcAssets6List + 1)...dlMcAssets7List {
            do {
                try downloadMcAsset(i: i, hashes: hashes)
            } catch {
                do {
                    try downloadMcAsset(i: i, hashes: hashes)
                } catch {
                    fputs("Failed to download asset \(hashes[i])\n\(error)\n", stderr)
                }
            }
        }
        dlMcAssets7Done = true
    }
    dlqueue8.async {
        for i in (dlMcAssets7List + 1)...dlMcAssets8List {
            do {
                try downloadMcAsset(i: i, hashes: hashes)
            } catch {
                do {
                    try downloadMcAsset(i: i, hashes: hashes)
                } catch {
                    fputs("Failed to download asset \(hashes[i])\n\(error)\n", stderr)
                }
            }
        }
        dlMcAssets8Done = true
    }
    while !dlMcAssets1Done || !dlMcAssets2Done || !dlMcAssets3Done || !dlMcAssets4Done || !dlMcAssets5Done || !dlMcAssets6Done || !dlMcAssets7Done || !dlMcAssets8Done {
        usleep(500000)
    }
}
func getLunarAssets(index: [String], base: String) throws { // Function for downloading Lunar assets
    if !FileManager.default.fileExists(atPath: homeDir + "/.lunarcmd_data/textures") {
        try FileManager.default.createDirectory(at: URL(fileURLWithPath: homeDir + "/.lunarcmd_data/textures"), withIntermediateDirectories: true)
    }
    var dlLAssets1Done = false
    var dlLAssets2Done = false
    var dlLAssets3Done = false
    var dlLAssets4Done = false
    var dlLAssets5Done = false
    var dlLAssets6Done = false
    var dlLAssets7Done = false
    var dlLAssets8Done = false
    let dlLAssets1List = (index.count / 8) - 1
    let dlLAssets2List = (index.count / 4) - 1
    let dlLAssets3List = ((index.count / 4) + (index.count / 8) - 1)
    let dlLAssets4List = (index.count / 2) - 1
    let dlLAssets5List = ((index.count / 2) + (index.count / 8) - 1)
    let dlLAssets6List = ((index.count / 2) + (index.count / 4)) - 1
    let dlLAssets7List = ((index.count / 2) + (index.count / 4) + (index.count / 8)) - 1
    let dlLAssets8List = index.count - 1
    dlqueue1.async {
        for i in 0...dlLAssets1List {
            do {
                try downloadLunarAsset(i: i, index: index, base: base)
            } catch {
                do {
                    try downloadLunarAsset(i: i, index: index, base: base)
                } catch {
                    fputs("Failed to download asset \(index[i].components(separatedBy: " ")[0])\n\(error)\n", stderr)
                }
            }
        }
        dlLAssets1Done = true
    }
    dlqueue2.async {
        for i in (dlLAssets1List + 1)...dlLAssets2List {
            do {
                try downloadLunarAsset(i: i, index: index, base: base)
            } catch {
                do {
                    try downloadLunarAsset(i: i, index: index, base: base)
                } catch {
                    fputs("Failed to download asset \(index[i].components(separatedBy: " ")[0])\n\(error)\n", stderr)
                }
            }
        }
        
        dlLAssets2Done = true
    }
    dlqueue3.async {
        for i in (dlLAssets2List + 1)...dlLAssets3List {
            do {
                try downloadLunarAsset(i: i, index: index, base: base)
            } catch {
                do {
                    try downloadLunarAsset(i: i, index: index, base: base)
                } catch {
                    fputs("Failed to download asset \(index[i].components(separatedBy: " ")[0])\n\(error)\n", stderr)
                }
            }
        }
        dlLAssets3Done = true
    }
    dlqueue4.async {
        for i in (dlLAssets3List + 1)...dlLAssets4List {
            do {
                try downloadLunarAsset(i: i, index: index, base: base)
            } catch {
                do {
                    try downloadLunarAsset(i: i, index: index, base: base)
                } catch {
                    fputs("Failed to download asset \(index[i].components(separatedBy: " ")[0])\n\(error)\n", stderr)
                }
            }
        }
        dlLAssets4Done = true
    }
    dlqueue5.async {
        for i in (dlLAssets4List + 1)...dlLAssets5List {
            do {
                try downloadLunarAsset(i: i, index: index, base: base)
            } catch {
                do {
                    try downloadLunarAsset(i: i, index: index, base: base)
                } catch {
                    fputs("Failed to download asset \(index[i].components(separatedBy: " ")[0])\n\(error)\n", stderr)
                }
            }
        }
        dlLAssets5Done = true
    }
    dlqueue6.async {
        for i in (dlLAssets5List + 1)...dlLAssets6List {
            do {
                try downloadLunarAsset(i: i, index: index, base: base)
            } catch {
                do {
                    try downloadLunarAsset(i: i, index: index, base: base)
                } catch {
                    fputs("Failed to download asset \(index[i].components(separatedBy: " ")[0])\n\(error)\n", stderr)
                }
            }
        }
        dlLAssets6Done = true
    }
    dlqueue7.async {
        for i in (dlLAssets6List + 1)...dlLAssets7List {
            do {
                try downloadLunarAsset(i: i, index: index, base: base)
            } catch {
                do {
                    try downloadLunarAsset(i: i, index: index, base: base)
                } catch {
                    fputs("Failed to download asset \(index[i].components(separatedBy: " ")[0])\n\(error)\n", stderr)
                }
            }
        }
        dlLAssets7Done = true
    }
    dlqueue8.async {
        for i in (dlLAssets7List + 1)...dlLAssets8List {
            do {
                try downloadLunarAsset(i: i, index: index, base: base)
            } catch {
                do {
                    try downloadLunarAsset(i: i, index: index, base: base)
                } catch {
                    fputs("Failed to download asset \(index[i].components(separatedBy: " ")[0])\n\(error)\n", stderr)
                }
            }
        }
        dlLAssets8Done = true
    }
    while !dlLAssets1Done || !dlLAssets2Done || !dlLAssets3Done || !dlLAssets4Done || !dlLAssets5Done || !dlLAssets6Done || !dlLAssets7Done || !dlLAssets8Done {
        usleep(500000)
    }
}
func downloadMcAsset(i: Int, hashes: [String]) throws {
    let first2hash = String(hashes[i].prefix(2))
    if !FileManager.default.fileExists(atPath: gameDir + "/assets/objects/" + first2hash + "/" + hashes[i]) {
        try FileManager.default.createDirectory(at: URL(fileURLWithPath: gameDir + "/assets/objects/" + first2hash), withIntermediateDirectories: true)
        try Data(contentsOf: URL(string: "https://resources.download.minecraft.net/" + first2hash + "/" + hashes[i])!).write(to: URL(fileURLWithPath: gameDir + "/assets/objects/" + first2hash + "/" + hashes[i]))
        print("Downloaded asset:", hashes[i])
    }
}
func downloadLunarAsset(i: Int, index: [String], base: String) throws {
    if !FileManager.default.fileExists(atPath: homeDir + "/.lunarcmd_data/textures/" + index[i].components(separatedBy: " ")[0]) {
        if !FileManager.default.fileExists(atPath: URL(fileURLWithPath: homeDir + "/.lunarcmd_data/textures/" + index[i].components(separatedBy: " ")[0]).deletingLastPathComponent().path) {
            try FileManager.default.createDirectory(at: URL(fileURLWithPath: homeDir + "/.lunarcmd_data/textures/" + index[i].components(separatedBy: " ")[0]).deletingLastPathComponent(), withIntermediateDirectories: true)
        }
        let data = try Data(contentsOf: URL(string: base + index[i].components(separatedBy: " ")[1])!) // Downloads the file
        try data.write(to: URL(fileURLWithPath: homeDir + "/.lunarcmd_data/textures/" + index[i].components(separatedBy: " ")[0]))
        print("Downloaded Lunar asset:", index[i].components(separatedBy: " ")[0])
    }
}
