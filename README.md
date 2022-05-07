# lunarcmd
LunarCmd will launch Lunar Client from the command line.
# Usage
To start with default settings run `lunarcmd <lunar_version>`. lunar_version can be any Lunar Client version (ex: 1.8)
# Building
To build, run `make`. To install after building, run `sudo make install`.
# SwiftyJSON
The SwiftyJSON.swift is from https://github.com/IBM-Swift/SwiftyJSON, with a few small modifications to make building work on Linux.
# Downloading
To download, use the appropriate zip file from Releases. If on Linux, run the lunarcmd shell script, NOT the executable in bin/. This will set the LD_LIBRARY_PATH variable correctly so you don't get missing library errors.
# Signing in
If you can't sign in to your Microsoft account, try opening the official Lunar Client launcher and signing in again. This is because the Launcher needs to be opened to sign in. Once you sign in once, you should stay signed in.
