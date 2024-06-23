# Iotsim

Simple IOT-device simulator written in phoenix and elixir.

To run use `docker compose up` and access the dashboard on
`http://localhost:4000`. Enter amount of DeviceSims to create and hit enter

Each device will change state every 5 seconds.
```
- From starting -> Running
- From Running ->
    20% chance -> Error
    80% chance -> Running
- From Error -> 
    Errors < 3 -> Starting
    Errors <= 3 -> Broken
- Stays in Broken
```

A user may manually change states on each device, and clear the amount of recorded errors.
Each transition is recorded in an event-log
