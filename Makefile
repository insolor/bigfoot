.PHONY: clean build package

clean:
	rm bigfoot.exe || true
	rm bigfoot.zip || true

bigfoot.exe: bigfoot.asm
	fasm bigfoot.asm

build: bigfoot.exe

bigfoot.zip: bigfoot.exe
	rm bigfoot.zip || true
	zip -r bigfoot.zip bigfoot.exe

package: bigfoot.zip
