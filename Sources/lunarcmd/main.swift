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
import SwiftyJSON
extension String: Error {}
import ZIPFoundation
func dataDownload(url: URL) throws -> Data {
    var finished = false
    var download = Data.init()
    var errorr: Error?  = nil
    let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
        if error != nil {
            errorr = error
            finished = true
        }
        guard let data = data else { return }
        download = data
        finished = true
    }
    task.resume()
    
    while finished == false {
        usleep(50)
    }
    if errorr != nil {
        throw errorr!
    }
    return download
}
func stringDownload(url: URL) throws -> String {
    var finished = false
    var download: String? = ""
    var errorr: Error?  = nil
    let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
        if error != nil {
            errorr = error
            finished = true
        }
        
        guard let data = data else { return }
        download = String(data: data, encoding: .utf8)
        if download == nil {
            errorr = "Response is not a valid string"
            finished = true
        }
        finished = true
    }
    task.resume()
    
    while finished == false {
        usleep(50)
    }
    if errorr != nil {
        throw errorr!
    }
    return download!
}
#if DEBUG

#else
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
#endif
#if arch(arm64)
let arch = "arm64"
#endif
setbuf(stdout, nil)
setbuf(stderr, nil)
var max_threads = 8
var nativesFile = "natives-\(osstring)-\(arch).zip"
let argv = CommandLine.arguments // Sets a variable to the arguments
let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
var gameDir = FileManager.default.currentDirectoryPath + "/lunarcmd"
var mainClass = "com.moonsworth.lunar.patcher.LunarMain"
var versionLaunching = ""
var noVersionPassed = false
func downloadLicenses(licenses: JSON) throws { // Function for downloading Lunar Client licenses
    if !FileManager.default.fileExists(atPath: homeDir + "/.lunarcmd_data/licenses") {
        try FileManager.default.createDirectory(at: URL(fileURLWithPath: homeDir + "/.lunarcmd_data/licenses"), withIntermediateDirectories: true)
    }
    var threads3 = 0
    for i in 0...(licenses.count - 1) {
        let dlqueue3 = DispatchQueue(label: "dllis")
        dlqueue3.async {
            threads3+=1
            do {
                if licenses[i]["url"].string != nil {
                    if !FileManager.default.fileExists(atPath: homeDir + "/.lunarcmd_data/licenses/" + licenses[i]["file"].string!) {
                        let data = try dataDownload(url: URL(string: licenses[i]["url"].string!.replacingOccurrences(of: " ", with: "%20"))!)
                        try data.write(to: URL(fileURLWithPath: homeDir + "/.lunarcmd_data/licenses/" + licenses[i]["file"].string!))
                        print("Downloaded license:", licenses[i]["file"].string!)
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
        print("Started Java download")
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
        print("Downloaded Java")
    }
}
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
        fputs("Could not get available versions\n", stderr)
    }
    print("Downloading Lunar assets...")
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
    print("Request body: \(json)")
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
        fputs("Error: Could not get launch data\nResponse: \(jsonresponse)\n", stderr)
        exit(-1)
    }
#if DEBUG
    print("Launch response: \(jsonresponse)")
#endif
    do {
        try getLunarAssets(index: try stringDownload(url: URL(string: jsonresponse["textures"]["indexUrl"].string!)!).components(separatedBy: "\n"), base: jsonresponse["textures"]["baseUrl"].string!)
        try getLunarJavaData(artifacts: jsonresponse["launchTypeData"]["artifacts"])
        mainClass = jsonresponse["launchTypeData"]["mainClass"].string ?? "com.moonsworth.lunar.patcher.LunarMain"
        if !FileManager.default.fileExists(atPath: homeDir + "/.lunarcmd_data/offline/\(versionLaunching)/natives_\(arch)") {
            try FileManager.default.unzipItem(at: URL(fileURLWithPath: homeDir + "/.lunarcmd_data/offline/\(versionLaunching)/\(nativesFile)"), to: URL(fileURLWithPath: homeDir + "/.lunarcmd_data/offline/\(versionLaunching)/natives_\(arch)"))
        }
        try downloadJre(jreurl: jsonresponse["jre"]["download"]["url"].string!)
        try downloadLicenses(licenses: jsonresponse["licenses"])
    } catch {
        fputs("Could not get launch data\n\(error)\n", stderr)
        exit(-1)
    }
}
if argv.contains("-h") || argv.contains("--help") {
    print("Overview: LunarCmd launches Lunar Client from the command line.\nusage: lunarcmd --version <version> [--gameDir <game directory>] [--server <server to auto join>] [--mem <RAM allocation>] [--width <window width>] [--height <window height>] [--branch <lunar branch>] [--jvm <jvm argument>] [--javaExec <java executable>] [--storageDir <lunar client storage directory>] [--logAddons] [--downloadOnly] [--disablePythonSignIn] [--quitOnLeave] [--no-optifine] [--max-threads] [--sodium] [--launch-override <override>]\nArgument description:\n--version <version> - (Required) The Lunar Client version to launch\n--gameDir <game directory> - The directory to use for game settings and worlds\n--server <server to auto join> - A server to connect to automatically when the game launches\n--mem <RAM allocation> - How much RAM to allocate to the game\n--width <window width> - The default width of the window\n--height <window width> - The default height of the window\n--branch <lunar branch> - The branch to use for the game\n--jvm <jvm argument> - Argument to pass to the JVM\n--javaExec <java executable> - The path to the Java executable\n--storageDir <lunar client storage directory> - Directory to use for Lunar Client and mod settings\n--logAddons - Enables coloring certain log messages and prints chat messages directly\n--downloadOnly - Downloads the game and assets without starting it\n--disablePythonSignIn - Disables the use of the Python sign in script\n--quitOnLeave - Quits the game when you leave a server. --server <server to auto join> must also be passed. `production.spectrum.moonsworth.cloud.:222` must also be in your server list for this to work.\n--no-optifine - Sets the module in the launch request to lunar-noOF\n--max-threads - Sets the max number of threads for downloading (Default: 8)\n--sodium - Uses Sodium instead of OptiFine; compatible with 1.16 and newer\n--launch-override <override> - Overrides an option in the launch request, override formatted as <param>=<value>")
    exit(0)
}
// Argument checks below
if argv.contains("--server") {
    if !argv.indices.contains(argv.firstIndex(of: "--server")! + 1) {
        fputs("Error: --server requires a server to be specified\n", stderr)
        exit(-1)
    }
}
if argv.contains("--max-threads") {
    if !argv.indices.contains(argv.firstIndex(of: "--max-threads")! + 1) {
        fputs("Error: --max-threads requires a number to be specified\n", stderr)
        exit(-1)
    } else {
        max_threads = Int(argv[argv.firstIndex(of: "--max-threads")! + 1]) ?? 8
        if max_threads < 1 {
            fputs("Error: --max-threads should be above 0\n", stderr)
            exit(-1)
        }
        if max_threads > 127 {
            fputs("Error: --max-threads should be below 128\n", stderr)
            exit(-1)
        }
    }
}
if argv.contains("--version") {
    if !argv.indices.contains(argv.firstIndex(of: "--version")! + 1) {
        fputs("Error: --version requires a version to be specified\n", stderr)
        exit(-1)
    } else {
        versionLaunching = argv[argv.firstIndex(of: "--version")! + 1]
    }
} else {
    noVersionPassed = true
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
if argv.contains("--launch-override") {
    var checkIndex1 = 0
    for i in argv {
        if i == "--launch-override" {
            if !argv.indices.contains(checkIndex1 + 1) {
                fputs("Error: --launch-override requires an option to be specified\n", stderr)
                exit(-1)
            } else {
            	if !argv[checkIndex1 + 1].contains("=") {
            	    fputs("Error: Incorrect formatting of launch override, should be formatted as <param>=<value>\n", stderr)
            	    exit(-1)
            	}
            }
        }
        checkIndex1+=1
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
    try getAssets(version: versionLaunching) // Updates the asset index
} catch {
    fputs("Error downloading assets\n\(error)\n", stderr)
    exit(-1)
}
if argv.contains("--downloadOnly") {
    print("--downloadOnly passed, exiting")
    exit(0)
}
print("Preparing to launch Lunar Client \(versionLaunching)")
let lunarCmd = Process()
do {
    let jreVersionPath = homeDir + "/.lunarcmd_data/jre_\(arch)/\(versionLaunching)" // Sets the path to the Java folder
    if javaExec == "default" {
        try lunarCmd.executableURL = URL(fileURLWithPath: jreVersionPath + "/" + FileManager.default.contentsOfDirectory(atPath: jreVersionPath)[0] + "/bin/java")
    } else {
        lunarCmd.executableURL = URL(fileURLWithPath: javaExec)
    }
    lunarCmd.arguments = []
    if os == "darwin" {
        if Int(versionLaunching.components(separatedBy: ".")[1])! > 12 {
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
    lunarCmd.arguments?.append("-Djna.boot.library.path=natives_\(arch)")
    lunarCmd.arguments?.append("--add-opens")
    lunarCmd.arguments?.append("java.base/java.io=ALL-UNNAMED")
    lunarCmd.arguments?.append("-cp")
    var classpath = ""
    var optifine = ""
    if argv.contains("--sodium") {
        for i in try FileManager.default.contentsOfDirectory(atPath: homeDir + "/.lunarcmd_data/offline/\(versionLaunching)") {
            if i.contains(".jar") && !i.lowercased().contains("optifine") {
                repeatIndex+=1
#if DEBUG
                print("Added \(i) to classpath")
#endif
                if repeatIndex != 1 {
                    classpath = classpath + ":" + i
                } else {
                    classpath = classpath + i
                }
            }
        }
    } else {
        for i in try FileManager.default.contentsOfDirectory(atPath: homeDir + "/.lunarcmd_data/offline/\(versionLaunching)") {
            if (i.contains(".jar") || i.lowercased().contains("optifine")) && !(i.lowercased().contains("sodium") || i.lowercased().contains("iris") || i.lowercased().contains("indium")) {
                repeatIndex+=1
                if i.contains("OptiFine_v1") {
                    optifine = i
                } else {
#if DEBUG
                    print("Added \(i) to classpath")
#endif
                    if repeatIndex != 1 {
                        classpath = classpath + ":" + i
                    } else {
                        classpath = classpath + i
                    }
                }
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
    lunarCmd.arguments?.append("-Djava.library.path=natives_\(arch)") // Sets more JVM args
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
    lunarCmd.arguments?.append(mainClass)
    lunarCmd.arguments?.append("--version") // Sets game args
    lunarCmd.arguments?.append(versionLaunching)
    lunarCmd.arguments?.append("--accessToken")
    lunarCmd.arguments?.append("0")
    lunarCmd.arguments?.append("--assetIndex")
    lunarCmd.arguments?.append(versionLaunching)
    lunarCmd.arguments?.append("--texturesDir")
    lunarCmd.arguments?.append(homeDir + "/.lunarcmd_data/textures")
    lunarCmd.arguments?.append("--gameDir")
    lunarCmd.arguments?.append(gameDir)
    lunarCmd.arguments?.append("--workingDirectory")
    lunarCmd.arguments?.append(".")
    lunarCmd.arguments?.append("--classpathDir")
    lunarCmd.arguments?.append(".")
    lunarCmd.arguments?.append("--ichorClassPath")
    lunarCmd.arguments?.append(classpath.replacingOccurrences(of: ":", with: ","))
    lunarCmd.arguments?.append("--ichorExternalFiles")
    lunarCmd.arguments?.append(optifine)
    if argv.contains("--server") {
        lunarCmd.arguments?.append("--server")
        lunarCmd.arguments?.append(argv[argv.firstIndex(of: "--server")! + 1])
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
    lunarCmd.currentDirectoryURL = URL(fileURLWithPath: homeDir + "/.lunarcmd_data/offline/\(versionLaunching)/")
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
func prase(string: String, key: String) -> [String] {
    var keys = [""]
    for i in string.components(separatedBy: "\"" + key + "\": \"") {
        keys.append(i.components(separatedBy: "\"")[0])
    }
    keys.remove(at: 0)
    keys.remove(at: 0)
#if DEBUG
    print("Found \(keys) in json")
#endif
    return keys
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
        let dlqueue2 = DispatchQueue(label: "dljar")
        dlqueue2.async {
            threads2+=1
            do {
                if artifacts[i]["url"].string != nil {
                    let prevsha1 = try? String(contentsOfFile: homeDir + "/.lunarcmd_data/offline/\(versionLaunching)/sha1/\(artifacts[i]["name"].string!).sha1")
                    if prevsha1 != artifacts[i]["sha1"].string! {
                        let data = try dataDownload(url: URL(string: artifacts[i]["url"].string!)!) // Downloads the file
                        try data.write(to: URL(fileURLWithPath: homeDir + "/.lunarcmd_data/offline/\(versionLaunching)/" + artifacts[i]["name"].string!))
                        try? artifacts[i]["sha1"].string!.data(using: .utf8)?.write(to: URL(fileURLWithPath: homeDir + "/.lunarcmd_data/offline/\(versionLaunching)/sha1/\(artifacts[i]["name"].string!).sha1"))
                        print("Downloaded JAR:", artifacts[i]["name"].string!)
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
    while downloadsLeft2 > 1 {
        usleep(500)
    }
}
func startSignIn() {
    let signInScript = """
import time
import sys
import procbridge as pb
import webview
import threading
PORT = 28189
url = ""
hasranyet = False
def webviewwaiter():
    while not hasranyet:
        time.sleep(0.5)
    webviewcreate()
def webviewwait():
        print(window.get_current_url())
        while not "?code=" in window.get_current_url():
            time.sleep(0.1)
        global url
        url = window.get_current_url()
def webviewcreate():
    global window
    window = webview.create_window("Sign in", "https://login.live.com/oauth20_authorize.srf?client_id=00000000402b5328&response_type=code&scope=service::user.auth.xboxlive.com::MBI_SSL&redirect_uri=https%3A%2F%2Flogin.live.com%2Foauth20_desktop.srf")
    webview.start(func=webviewwait)
def exitweb():
    window.destroy()
    exit(0)
def delegate(method, payload):
    global hasranyet
    hasranyet = True
    while url == "":
        time.sleep(0.1)
    thisdict = {
      "status": "MATCHED_TARGET_URL",
      "url": url
    }
    print(payload)
    threading.Timer(2, exitweb).start()
    return thisdict
def webviewsignoutwait():
        print(window.get_current_url())
        while not "msn.com" in window.get_current_url():
            time.sleep(0.1)
        window.hide()
        window.destroy()

if __name__ == "__main__":
    window = webview.create_window("Sign in again", "https://login.live.com/logout.srf")
    webview.start(func=webviewsignoutwait)
    s = pb.Server("0.0.0.0", PORT, delegate)
    s.start(daemon=True)
    print("Signin Server is on {}...".format(PORT))
    webviewwaiter()
"""
    let signin = Process()
    signin.executableURL = URL(fileURLWithPath: "/bin/sh")
    signin.arguments = ["-c", "echo '\(signInScript)' | python3"]
    let pipe = Pipe()
    signin.standardOutput = pipe
    signin.standardError = pipe
    let outHandle = pipe.fileHandleForReading
    outHandle.readabilityHandler = { pipe in
        if let line = String(data: pipe.availableData, encoding: String.Encoding.utf8) {
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
                    print("Downloaded asset:", hashes[i])
                }
            } catch {
                print(error)
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
func getLunarAssets(index: [String], base: String) throws { // Function for downloading Lunar assets
    if !FileManager.default.fileExists(atPath: homeDir + "/.lunarcmd_data/textures") {
        try FileManager.default.createDirectory(at: URL(fileURLWithPath: homeDir + "/.lunarcmd_data/textures"), withIntermediateDirectories: true)
    }
    var downloadsLeft1 = index.count
    var threads1 = 0
    for i in 0...(index.count - 1) {
        let dlqueue = DispatchQueue(label: "dl")
        dlqueue.async {
            threads1+=1
            do {
                if !FileManager.default.fileExists(atPath: homeDir + "/.lunarcmd_data/textures/" + index[i].components(separatedBy: " ")[0]) {
                    if !FileManager.default.fileExists(atPath: URL(fileURLWithPath: homeDir + "/.lunarcmd_data/textures/" + index[i].components(separatedBy: " ")[0]).deletingLastPathComponent().path) {
                        try FileManager.default.createDirectory(at: URL(fileURLWithPath: homeDir + "/.lunarcmd_data/textures/" + index[i].components(separatedBy: " ")[0]).deletingLastPathComponent(), withIntermediateDirectories: true)
                    }
                    let data = try dataDownload(url: URL(string: base + index[i].components(separatedBy: " ")[1])!) // Downloads the file
                    try data.write(to: URL(fileURLWithPath: homeDir + "/.lunarcmd_data/textures/" + index[i].components(separatedBy: " ")[0]))
                    print("Downloaded Lunar asset:", index[i].components(separatedBy: " ")[0])
                }
            } catch {
                print(error)
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
    while downloadsLeft1 > 25 {
        usleep(500)
    }
}
