build:
	docker build -t imma/ubuntu:rsync .

up:
	docker run -ti -v home:/home/ubuntu imma/ubuntu:rsync bash

sync:
	dsync $(HOME) home imma/ubuntu:rsync
