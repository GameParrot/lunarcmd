// LunarCmd Main Source file

import Foundation
import TinyLogger
#if os(Linux)
import FoundationNetworking
#endif
let lunarcmdVersion = "3.0"
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
var classPathMap: [String:Bool] = [:]
let logFormat = "[%t] [%f/%T]: %m"
if argv.contains("-version") {
#if DEBUG
    print("LunarCmd \(lunarcmdVersion) (Debug build)")
#else
    print("LunarCmd \(lunarcmdVersion)")
#endif
    exit(0)
}
if argv.contains("-h") || argv.contains("--help") {
    print("Overview: LunarCmd launches Lunar Client from the command line.\nusage: lunarcmd [-version] --version <version> [--gameDir <game directory>] [--server <server to auto join>] [--mem <RAM allocation>] [--width <window width>] [--height <window height>] [--branch <lunar branch>] [--jvm <jvm argument>] [--javaExec <java executable>] [--storageDir <lunar client storage directory>] [--logAddons] [--downloadOnly] [--disablePythonSignIn] [--quitOnLeave] [--no-optifine] [--max-threads] [--sodium] [--launch-override <override>] [--no-fps-booster] [--neu]\nArgument description\n-version - Print LunarCmd version and exit\n--version <version> - (Required) The Lunar Client version to launch\n--gameDir <game directory> - The directory to use for game settings and worlds\n--server <server to auto join> - A server to connect to automatically when the game launches\n--mem <RAM allocation> - How much RAM to allocate to the game\n--width <window width> - The default width of the window\n--height <window width> - The default height of the window\n--branch <lunar branch> - The branch to use for the game\n--jvm <jvm argument> - Argument to pass to the JVM\n--javaExec <java executable> - The path to the Java executable\n--storageDir <lunar client storage directory> - Directory to use for Lunar Client and mod settings\n--logAddons - Enables coloring certain log messages and prints chat messages directly\n--downloadOnly - Downloads the game and assets without starting it\n--disablePythonSignIn - Disables the use of the Python sign in script\n--quitOnLeave - Quits the game when you leave a server. --server <server to auto join> must also be passed. `production.spectrum.moonsworth.cloud.:222` must also be in your server list for this to work.\n--no-optifine - Sets the module in the launch request to lunar-noOF\n--max-threads - Sets the max number of threads for downloading (Default: 8)\n--sodium - Uses Sodium instead of OptiFine; compatible with 1.16 and newer\n--launch-override <override> - Overrides an option in the launch request, override formatted as <param>=<value>\n--no-fps-booster - Stops the game from using an FPS Booster (OptiFine or Sodium)\n--neu - Sets NEU (Not Enough Updates) as the module")
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
TinyLogger.log.info(msg: "Updating asset index...", format: logFormat)
do {
    try getAssets(version: versionLaunching) // Updates the asset index
} catch {
    TinyLogger.log.fatal(msg: "Error downloading assets\n\(error)\n", format: logFormat)
    exit(-1)
}
if argv.contains("--downloadOnly") {
    TinyLogger.log.info(msg: "--downloadOnly passed, exiting", format: logFormat)
    exit(0)
}
TinyLogger.log.info(msg: "Preparing to launch Lunar Client \(versionLaunching)", format: logFormat)
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
    var externalFiles = ""
    if argv.contains("--no-fps-booster") {
        for i in try FileManager.default.contentsOfDirectory(atPath: homeDir + "/.lunarcmd_data/offline/\(versionLaunching)") {
            if classPathMap[i] != nil {
                if !(i.lowercased().contains("sodium") || i.lowercased().contains("iris") || i.lowercased().contains("indium") || i.lowercased().contains("optifine")) {
                    if classPathMap[i] ?? false {
                        externalFiles = externalFiles + i + ","
#if DEBUG
                        TinyLogger.log.debug(msg: "Added \(i) to external files", format: logFormat)
#endif
                    } else {
                        repeatIndex+=1
#if DEBUG
                        TinyLogger.log.debug(msg: "Added \(i) to classpath", format: logFormat)
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
    } else {
        for i in try FileManager.default.contentsOfDirectory(atPath: homeDir + "/.lunarcmd_data/offline/\(versionLaunching)") {
            if classPathMap[i] != nil {
                if classPathMap[i] ?? false {
                    externalFiles = externalFiles + i + ","
#if DEBUG
                    TinyLogger.log.debug(msg: "Added \(i) to external files", format: logFormat)
#endif
                } else {
                    repeatIndex+=1
#if DEBUG
                    TinyLogger.log.debug(msg: "Added \(i) to classpath", format: logFormat)
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
    lunarCmd.arguments?.append(externalFiles)
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
    TinyLogger.log.info(msg: "Java executable: \(lunarCmd.executableURL!.path), Arguments: \(lunarCmd.arguments!)", format: logFormat)
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
            TinyLogger.log.error(msg: "Error decoding data: \(pipe.availableData)", format: logFormat)
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
                TinyLogger.log.error(msg: "Error decoding data: \(pipe1.availableData)", format: logFormat)
            }
        }
    }
    try lunarCmd.run()
} catch {
    TinyLogger.log.fatal(msg: "Error launching game\n\(error)\n", format: logFormat)
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

