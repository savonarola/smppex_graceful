# SMPPEX Graceful Shutdown Example

This is an example of an advanced usage of SMPP library [SMPPEX](https://github.com/savonarola/smppex).

It is shown how one can organize ESME sessions so that an application could gracefully terminate them, i.e. to send `unbind` pdus to each session and terminate only after `unbind_resp`s received or after some timeout.

## Running the sample scenario

The sample scenario can be run with the commands:

```
mix deps.get
mix run bin/scenario.exs
```

## LICENSE

This software is licensed under [MIT License](LICENSE).
