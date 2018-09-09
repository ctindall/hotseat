test: servertest

servertest:
	prove -Iserver/lib server/t
