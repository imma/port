up:
	docker run -ti -v home:/home/ubuntu imma/ubuntu:rsync bash

build:
	docker build -t imma/ubuntu:rsync .

sync:
	dsync $(HOME) home imma/ubuntu:rsync
