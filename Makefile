.PHONY: devsetup

default: devsetup

devsetup:
	which npm || brew install npm
	npm install
