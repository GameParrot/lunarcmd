prefix ?= /usr/local
UNAME := $(shell uname)
debug:
	-mkdir bin
	swift build -c debug
	$(eval X64_PATH=$(shell swift build -c debug --show-bin-path | tail -n 1))
	cp "$(X64_PATH)/lunarcmd" bin/lunarcmd
	@echo "\033[32;1mBuild succeeded. To install, run "'`sudo make install`'"\033[0m"

release:
ifeq ($(UNAME), Darwin)
	-mkdir bin
	swift build --arch x86_64 -c release
	@echo "\033[32;1mBuilt for x86_64\033[0m"
	swift build --arch arm64 -c release
	@echo "\033[32;1mBuilt for arm64\033[0m"
	$(eval X64_PATH=$(shell swift build --arch x86_64 -c release --show-bin-path | tail -n 1))
	$(eval ARM64_PATH=$(shell swift build --arch arm64 -c release --show-bin-path | tail -n 1))
	lipo -create "$(X64_PATH)/lunarcmd" "$(ARM64_PATH)/lunarcmd" -output bin/lunarcmd
	@echo "\033[32;1mBuild succeeded. To install, run "'`sudo make install`'"\033[0m"
else
	-mkdir bin
	swift build -c release --static-swift-stdlib
	$(eval X64_PATH=$(shell swift build -c release --show-bin-path | tail -n 1))
	cp "$(X64_PATH)/lunarcmd" bin/lunarcmd
	@echo "\033[32;1mBuild succeeded. To install, run "'`sudo make install`'"\033[0m"
endif

package:
ifeq ($(UNAME), Darwin)
	-mkdir lunarcmd_mac
	swift build --arch x86_64 -c release
	@echo "\033[32;1mBuilt for x86_64\033[0m"
	swift build --arch arm64 -c release
	@echo "\033[32;1mBuilt for arm64\033[0m"
	$(eval X64_PATH=$(shell swift build --arch x86_64 -c release --show-bin-path | tail -n 1))
	$(eval ARM64_PATH=$(shell swift build --arch arm64 -c release --show-bin-path | tail -n 1))
	lipo -create "$(X64_PATH)/lunarcmd" "$(ARM64_PATH)/lunarcmd" -output lunarcmd_mac/lunarcmd
	zip lunarcmd_mac.zip -r lunarcmd_mac
	rm -r lunarcmd_mac
	@echo "\033[32;1mBuild succeeded. LunarCmd is in lunarcmd_mac.zip\033[0m"
else
	-mkdir lunarcmd_linux
	swift build -c release --static-swift-stdlib
	$(eval X64_PATH=$(shell swift build -c release --show-bin-path | tail -n 1))
	cp "$(X64_PATH)/lunarcmd" lunarcmd_linux/lunarcmd
	zip lunarcmd_linux.zip -r lunarcmd_linux
	rm -r lunarcmd_linux
	@echo "\033[32;1mBuild succeeded. LunarCmd is in lunarcmd_linux.zip\033[0m"
endif

	
install:
	-mkdir "$(prefix)/bin"
	cp ./bin/* "$(prefix)/bin/"
	@echo "\033[32;1mSuccessfully installed lunarcmd\033[0m"
	