prefix ?= /usr/local
UNAME := $(shell uname)
all:
	-mkdir bin
	swiftc -emit-executable main.swift SwiftyJSON.swift LclJSONSerialization.swift -module-name lunarcmd -o bin/lunarcmd
	-mkdir -p lib/lunarcmd
	cp signin.py lib/lunarcmd/signin.py
	@echo "\033[32;1mBuild succeeded. To install, run "'`sudo make install`'"\033[0m"
	
install:
	-mkdir "$(prefix)/bin"
	cp ./bin/* "$(prefix)/bin/"
	cp -R ./lib/* "$(prefix)/lib/"
	@echo "\033[32;1mSuccessfully installed lunarcmd\033[0m"
	