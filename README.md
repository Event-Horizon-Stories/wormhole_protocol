# wormhole_protocol

`wormhole_protocol` teaches Commanded by following a colony that learns the hard way that intent is cheap and history is not.

At first the system behaves like any clean event-sourced service. Commands arrive in order. Events record what happened. State moves forward without argument. Then the wormholes open. A command meant for 10:05 appears at 09:55 instead, and the whole protocol has to decide whether the past can be rejected, rewritten, replayed, anchored, or forked into another branch of reality.

The result is a cumulative Elixir tutorial series where the same `WormholeProtocol` application grows chapter by chapter. Every lesson is a standalone Mix project. Every lesson keeps the same shared namespace and OTP app. What changes is the pressure on the timeline and the Commanded rule needed to survive it.

## Interactive Companions

Livebook companions for the full series live in [`livebooks/`](./livebooks/README.md).

- [`livebooks/01_linear_time.livemd`](./livebooks/01_linear_time.livemd)
- [`livebooks/02_first_wormhole_anomaly.livemd`](./livebooks/02_first_wormhole_anomaly.livemd)
- [`livebooks/03_temporal_conflict.livemd`](./livebooks/03_temporal_conflict.livemd)
- [`livebooks/04_rules_of_reality.livemd`](./livebooks/04_rules_of_reality.livemd)
- [`livebooks/05_historical_validation.livemd`](./livebooks/05_historical_validation.livemd)
- [`livebooks/06_rebuilding_time.livemd`](./livebooks/06_rebuilding_time.livemd)
- [`livebooks/07_duplicates_across_time.livemd`](./livebooks/07_duplicates_across_time.livemd)
- [`livebooks/08_the_reactor_paradox.livemd`](./livebooks/08_the_reactor_paradox.livemd)
- [`livebooks/09_observed_history_is_immutable.livemd`](./livebooks/09_observed_history_is_immutable.livemd)
- [`livebooks/10_forked_timelines.livemd`](./livebooks/10_forked_timelines.livemd)

## The Journey

Each lesson is its own standalone Mix project, but the protocol keeps the same identity from beginning to end:

1. [`01_linear_time`](./01_linear_time/README.md)  
   Commanded starts in calm water: commands become events and state moves forward.
2. [`02_first_wormhole_anomaly`](./02_first_wormhole_anomaly/README.md)  
   The first late-arriving command reveals that time order and arrival order are not the same thing.
3. [`03_temporal_conflict`](./03_temporal_conflict/README.md)  
   Replay becomes visible as the system previews what a past insertion would do to the present.
4. [`04_rules_of_reality`](./04_rules_of_reality/README.md)  
   The aggregate begins deciding whether the past must be rejected or whether history may be rewritten.
5. [`05_historical_validation`](./05_historical_validation/README.md)  
   Validation shifts from current state to replayed historical state.
6. [`06_rebuilding_time`](./06_rebuilding_time/README.md)  
   The replay engine becomes explicit and the reader can inspect how the present is rebuilt.
7. [`07_duplicates_across_time`](./07_duplicates_across_time/README.md)  
   Idempotency becomes temporal, not just operational.
8. [`08_the_reactor_paradox`](./08_the_reactor_paradox/README.md)  
   A reactor shutdown arriving in the past threatens the very failure that caused the wormhole.
9. [`09_observed_history_is_immutable`](./09_observed_history_is_immutable/README.md)  
   Observed events become the anchor that commands are not allowed to erase.
10. [`10_forked_timelines`](./10_forked_timelines/README.md)  
    The protocol keeps the original stream and materializes a second timeline instead of forcing one answer.

## Final Inquiry Shape

By the end of the series, the full question is no longer “how do I dispatch a command?”

It becomes:

```text
If a command can arrive from the past,
which event stream is allowed to accept it,
which observations are allowed to resist it,
and what present state follows from the chosen history?
```

That is the Commanded lesson underneath the story. Aggregates define the consistency boundary. Events anchor what became true. State is only the current reading of that recorded history.

## Beyond the Series

The ten chapters cover the core Commanded ideas this story needs:

- commands versus events
- aggregate validation
- replay as a first-class mechanism
- idempotency across time
- immutable observations
- branch creation through separate streams

There are natural extensions beyond this arc:

- persistent event stores instead of the in-memory adapter used here
- projectors and read models that rebuild from the same timeline decisions
- process managers that react when one timeline needs to spawn work in another
- snapshotting and retention strategies once streams grow large
- a dedicated event journal repo feeding the protocol rather than the protocol owning all replay inputs itself

Those belong one layer past this series. Here the point is to make the core mental shift stick: commands are requests, events are history, and history is what every present must answer to.

## Tooling

The repo is pinned with `.tool-versions` for an asdf-managed Erlang and Elixir toolchain:

```text
erlang 27.3
elixir 1.18.1-otp-27
```

Each lesson is a standalone Mix project. Enter the lesson directory you want, fetch dependencies if needed, then run its tests or shell:

```bash
cd 01_linear_time
mix deps.get
mix test
iex -S mix
```

The Livebooks depend on the chapter directories through local path dependencies, so they stay tied to the real lesson code rather than drifting into notebook-only examples.

## Start Here

Begin with [`01_linear_time`](./01_linear_time/README.md).

That lesson teaches the clean Commanded baseline before the anomalies begin:

```elixir
:ok = WormholeProtocol.open_timeline("colony-a")
:ok = WormholeProtocol.register_sector("colony-a", "hab-3", 100, "09:50")
:ok = WormholeProtocol.allocate_oxygen("colony-a", "hab-3", 40, "10:00")
```

Once that flow feels natural, the rest of the series can start bending time around it.
