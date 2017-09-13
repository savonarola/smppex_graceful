ESME.start(:esme1, "localhost", 2775, "sid1", "pass1")

ESME.start(:esme2, "localhost", 2775, "sid2", "pass2")

:timer.sleep(1000)

Application.stop(:esme)
