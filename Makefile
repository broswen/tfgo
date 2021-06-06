.PHONY: zip build clean


zip: build
	zip ./bin/functions.zip ./bin/*

build: clean
	export GO111MODULE=on
	env CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o bin/printer printer/main.go

clean:
	rm -rf ./bin ./vendor