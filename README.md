# lunarcmd
LunarCmd will launch Lunar Client from the command line.
# Usage
To start with default settings run `lunarcmd <lunar_version>`. lunar_version can be any Lunar Client version (ex: 1.8)
# Building
To build, run `make`. To install after building, run `sudo make install`. You will need to have Swift installed to build.
# SwiftyJSON
The SwiftyJSON.swift is from https://github.com/IBM-Swift/SwiftyJSON, with a few small modifications to make building work on Linux.
# Downloading
To download, use the appropriate zip file from Releases. If on Linux, run the lunarcmd shell script, NOT the executable in bin/. This will set the LD_LIBRARY_PATH variable correctly so you don't get missing library errors.
# Signing in
You will need Python 3 and the Python modules [pywebview](https://pypi.org/project/pywebview/) and [procbridge](https://pypi.org/project/procbridge/) to sign in. When it says that you need to have the launcher open, a window should appear and then disappear after a few seconds. After it disappears, click the sign in button again and you should be able to sign in. Alternatively, you can open the Lunar Client launcher when signing in.
