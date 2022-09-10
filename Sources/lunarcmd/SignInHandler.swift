// Sign in handler

import TinyLogger
import Foundation
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
            if line != "" {
                if line.hasSuffix("\n") {
                    TinyLogger.log.info(msg: String(line.dropLast(1)), format: "[%t] [%f/%T]: %m")
                } else {
                    TinyLogger.log.info(msg: line, format: logFormat)
                }
                if line.contains("ModuleNotFoundError") {
                    TinyLogger.log.error(msg: "\u{001b}[31;1mError: You need Python modules `pywebview` and `procbridge` to use the Python sign in.\u{001b}[0m\n", format: logFormat)
                    return
                }
                if line.contains("not found") {
                    TinyLogger.log.error(msg: "\u{001b}[31;1mError: Python 3 is required to sign in.\u{001b}[0m\n", format: logFormat)
                    return
                }
            }
        }
    }
    do {
        try signin.run()
    } catch {
        
    }
    DispatchQueue.global(qos: .userInitiated).async {
        if signin.isRunning {
            signin.waitUntilExit()
        }
        if #available(macOS 10.15, *) {
            try? outHandle.close()
        }
    }
    TinyLogger.log.info(msg: "\u{001b}[32;1mSign in should have failed. The sign in listener has been started, so you should be able to sign in now.\u{001b}[0m", format: logFormat)
}
