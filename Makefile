prefix ?= /usr/local
UNAME := $(shell uname)
all:
	-mkdir bin
	swiftc -c main.swift SwiftyJSON.swift LclJSONSerialization.swift -module-name lunarcmd
	@echo "\033[32;1m50% done\033[0m"
	swiftc -emit-executable main.o SwiftyJSON.o LclJSONSerialization.o -o bin/lunarcmd
	@echo "\033[32;1m100% done\033[0m"
	rm main.o SwiftyJSON.o LclJSONSerialization.o
	-mkdir -p lib/lunarcmd
	cp signin.py lib/lunarcmd/signin.py
	@echo "\033[32;1mBuild succeeded. To install, run "'`sudo make install`'"\033[0m"
	
install:
	-mkdir "$(prefix)/bin"
	cp ./bin/* "$(prefix)/bin/"
	cp -R ./lib/* "$(prefix)/lib/"
	@echo "\033[32;1mSuccessfully installed lunarcmd\033[0m"
	