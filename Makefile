prefix ?= /usr/local
UNAME := $(shell uname)
all:
ifeq ($(UNAME), Darwin)
	-mkdir bin
	swiftc -target x86_64-apple-macosx10.13 -emit-executable main.swift SwiftyJSON.swift LclJSONSerialization.swift -module-name lunarcmd -o bin/lunarcmd
	-mkdir -p lib/lunarcmd
	cp signin.py lib/lunarcmd/signin.py
	@echo "\033[32;1mBuild succeeded. To install, run "'`sudo make install`'"\033[0m"
else
	-mkdir bin
	swiftc -emit-executable main.swift SwiftyJSON.swift LclJSONSerialization.swift -module-name lunarcmd -o bin/lunarcmd
	-mkdir -p lib/lunarcmd
	cp signin.py lib/lunarcmd/signin.py
	@echo "\033[32;1mBuild succeeded. To install, run "'`sudo make install`'"\033[0m"
endif
	
install:
	-mkdir "$(prefix)/bin"
	cp ./bin/* "$(prefix)/bin/"
	cp -R ./lib/* "$(prefix)/lib/"
	@echo "\033[32;1mSuccessfully installed lunarcmd\033[0m"
	