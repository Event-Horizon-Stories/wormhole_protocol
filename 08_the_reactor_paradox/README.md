# Lesson 08: The Reactor Paradox

The protocol has been under strain before. This time the strain is existential.

A reactor failure at 10:00 is what opened the wormhole in the first place. Then a shutdown command appears with an effective time of 09:50. If the shutdown belongs in accepted history, the failure that caused the wormhole may no longer make sense. The command begins to lean against the event that made the command possible.

The protocol does not solve the paradox yet. It exposes it clearly. The shutdown can still be accepted under rewrite mode, but the replay report now shows the contradiction in full view.

Interactive companion: [`../livebooks/08_the_reactor_paradox.livemd`](../livebooks/08_the_reactor_paradox.livemd)

## What Changes

- how to extend the same aggregate with a second domain surface
- how replay can reveal paradox instead of just arithmetic conflict
- how a later observed event can become invalidated by a past command
- why replay reports are useful beyond simple totals and counters

## The Story

The reactor is registered at 09:40. The failure is observed at 10:00. That failure is not incidental. It is the reason the wormhole exists.

Then the shutdown command arrives and claims that the reactor should have gone dark at 09:50. If that were accepted, the failure would not disappear from the recorded stream, but it would lose its footing. It would become an event resting on a reactor that should already have been offline.

That is the paradox: the event still exists, but the history beneath it no longer holds.

## Under The Hood

Replay starts revealing invalidated observations, not just changed projections.

The aggregate now manages both oxygen sectors and reactors. The replay engine can preview a past shutdown and report whether that shutdown would invalidate a later observed failure. The stream can accept the new event, but the report makes clear that reality has split into something unstable.

## Protocol Changes

The earlier behavior remains, and the protocol adds:

- reactor registration and failure events
- reactor shutdown commands
- `ReplayEngine.paradox_report/2`

The cumulative app now handles two kinds of history:

- oxygen allocation history
- reactor operation history

## The Code

The new files live under `lib/`:

- [`lib/commands/register_reactor.ex`](./lib/commands/register_reactor.ex)
- [`lib/commands/record_reactor_failure.ex`](./lib/commands/record_reactor_failure.ex)
- [`lib/commands/shutdown_reactor.ex`](./lib/commands/shutdown_reactor.ex)
- [`lib/projectors/replay_engine.ex`](./lib/projectors/replay_engine.ex)

The paradox report looks for failures that become impossible once shutdowns are replayed earlier:

```elixir
invalidated_failures =
  replayed_reactor.failures
  |> Enum.filter(fn failure ->
    Enum.any?(replayed_reactor.shutdowns, fn shutdown ->
      shutdown.effective_at < failure.failed_at
    end)
  end)
```

The story helper uses that report before dispatching the shutdown command, so the contradiction is explicit.

## Trying It Out

```bash
cd 08_the_reactor_paradox
mix test
iex -S mix
```

In `iex`, paste:

```elixir
WormholeProtocol.reactor_paradox_story!()
```

You should see the shutdown accepted, along with a report that the `"wormhole_origin"` failure has been invalidated by the replayed past.

## What the Tests Prove

The tests keep earlier layers alive and then add the new paradox case:

- replay reporting still works
- duplicate commands are still rejected
- a past reactor shutdown can invalidate a later observed failure

That last test is the hinge of the chapter. The system is still functioning, but it is now visibly unstable.

## Why This Matters

This is where event sourcing stops feeling like a storage strategy and starts feeling like a theory of reality.

The paradox is not a UI problem or an API problem. It is a question about which history the system is willing to let stand once an event already on record depends on a different past.

## What Holds

Replay can expose contradictions in recorded history even when the stream still accepts the new event.

## What Still Hurts

Seeing the paradox is not the same thing as preventing it.

The protocol can now explain why the shutdown is dangerous, but it still allows the command into history under rewrite mode.

## Next Shift

Next, observed events become immutable anchors and paradox-inducing commands are rejected instead of merely reported.
