# lunarcmd
LunarCmd will launch Lunar Client from the command line.
# Usage
To start with default settings run `lunarcmd --version <lunar_version>`. lunar_version can be any Lunar Client version (ex: 1.8.9). To use the version chooser, run lunarcmd with no arguments. You will be asked to choose a version to launch.
# Building
To build, run `make`. To install after building, run `sudo make install`. You will need to have Swift installed to build.
# Downloading
To download, use the appropriate zip file from Releases. If on Linux, you will need to install Swift to /usr/local. To install Swift, first download Swift from https://www.swift.org/download/ and choose the right file for your distro. If your distro is not in the list, try the one for ubuntu 20.04. Once downloaded, run sudo bash ./swiftinstall.sh in the same directory as the downloaded file (no NOT rename the downloaded file). The script will then install Swift to /usr/local so you can use LunarCmd.

# Signing in
You will need Python 3 and the Python modules [pywebview](https://pypi.org/project/pywebview/) and [procbridge](https://pypi.org/project/procbridge/) to sign in. When it says that you need to have the launcher open, a window should appear and then disappear after a few seconds. After it disappears, click the sign in button again and you should be able to sign in. Alternatively, you can open the Lunar Client launcher when signing in.
