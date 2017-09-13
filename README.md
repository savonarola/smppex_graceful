# SMPPEX Graceful Shutdown Example

This is an example of an advanced usage of SMPP library [SMPPEX](https://github.com/savonarola/smppex).

It is shown how one can organize ESME sessions so that an application could gracefully terminate them, i.e. to send `unbind` pdus to each session and terminate only after `unbind_resp`s received or after some timeout.

## Running the sample scenario

The sample scenario can be run with the commands:

```
mix deps.get
mix run bin/scenario.exs
```

## Scenario explanation

The scenario is quite simple. There are two apps, `:esme` and `:mc`.

`:mc` is just a minimal MC which responds to pdus and does some logging.

`:esme` is a more complicated app for starting and controlling ESME sessions.

```elixir
ESME.start(:esme1, "localhost", 2775, "sid1", "pass1")

ESME.start(:esme2, "localhost", 2775, "sid2", "pass2")

:timer.sleep(1000)

Application.stop(:esme)
```

We start two ESMEs and after some time stop `:esme` app. Both connections are correctly terminated.

```
01:22:54.595 role=mc pid=<0.231.0> Peer connected

01:22:54.607 role=mc pid=<0.234.0> Peer connected

01:22:54.645 role=esme pid=<0.233.0> system_id=sid2 Succesfully bound

01:22:54.645 role=esme pid=<0.232.0> system_id=sid1 Succesfully bound

01:22:55.625 pid=<0.226.0> Terminating(:shutdown) sessions with unbind [#PID<0.233.0>, #PID<0.232.0>]

01:22:55.630 role=esme pid=<0.232.0> system_id=sid1 Unbinding

01:22:55.630 role=esme pid=<0.233.0> system_id=sid2 Unbinding

01:22:55.631 role=esme pid=<0.232.0> system_id=sid1 Got unbind response

01:22:55.631 role=esme pid=<0.233.0> system_id=sid2 Got unbind response

01:22:55.631 role=esme pid=<0.233.0> system_id=sid2 Terminating with reason :shutdown

01:22:55.631 role=esme pid=<0.232.0> system_id=sid1 Terminating with reason :shutdown

01:22:55.631 role=mc pid=<0.234.0> system_id=sid2 Peer correctly teminated connection

01:22:55.631 role=mc pid=<0.234.0> system_id=sid2 Terminating with reason :normal

01:22:55.631 role=mc pid=<0.231.0> system_id=sid1 Peer correctly teminated connection

01:22:55.631 role=mc pid=<0.231.0> system_id=sid1 Terminating with reason :normal

01:22:55.640 pid=<0.33.0> Application esme exited: :stopped
```

The idea is the following.

The main `:esme` supervisor has two children:
* supervisor `ESME.SessionSupervisor` under which ESME sessions are started;
* worker `ESME` which has `start` method launching ESME sessions under `ESME.SessionSupervisor`.

The termination process starts from the worker. It fetches all active ESME sessions, tells them to send `unbind` and waits untill they report about receiving `unbind_resp`s

After that the termination process continues, the supervisor with all the unbound ESME sessions terminates, and so the whole app.

## LICENSE

This software is licensed under [MIT License](LICENSE).
