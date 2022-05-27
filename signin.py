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
    window = webview.create_window('Sign in', 'https://login.live.com/oauth20_authorize.srf?client_id=00000000402b5328&response_type=code&scope=service::user.auth.xboxlive.com::MBI_SSL&redirect_uri=https%3A%2F%2Flogin.live.com%2Foauth20_desktop.srf')
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

if __name__ == '__main__':
    window = webview.create_window('Sign in again', 'https://login.live.com/logout.srf')
    webview.start(func=webviewsignoutwait)
    s = pb.Server('0.0.0.0', PORT, delegate)
    s.start(daemon=True)
    print("Signin Server is on {}...".format(PORT))
    webviewwaiter()
