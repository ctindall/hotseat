test: servertest clienttest

servertest:
	cd server && make test

clienttest:
	cd client && make test

