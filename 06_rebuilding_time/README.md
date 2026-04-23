# Lesson 06: Rebuilding Time

The protocol has been replaying history for several chapters already. Until now, most of that work happened behind the curtain.

Now the mechanism has to come into view. Operators do not just want a yes-or-no answer about a wormhole command anymore. They want to see what the rewind changed, which commands shifted position, and what the rebuilt present looks like on the other side.

The replay engine stops hiding behind the decision and starts showing its work.

Interactive companion: [`../livebooks/06_rebuilding_time.livemd`](../livebooks/06_rebuilding_time.livemd)

## What Changes

- how to turn replay into an explicit report instead of a hidden internal step
- how to compare the current present with the replayed present
- how to inspect reordered commands after a historical insertion
- why replay is a first-class part of the Commanded mental model

## The Story

The operators in mission control are no longer satisfied with a bare rejection or acceptance. When the protocol says a command would rebuild the present, they want to know what changed.

Did the available oxygen drop? Which command moved forward in history? Which part of the present stayed stable, and which part only looked stable because the old ordering had hidden the real dependency?

So the replay engine begins reporting what it sees. The protocol is still event-sourced. It is simply becoming legible.

## Under The Hood

Replay becomes an observable mechanism.

In Commanded, replay is usually implicit in aggregate state reconstruction. Here we make it explicit by returning a report that compares the current event ordering with the one produced after a hypothetical event is inserted into history.

That lets the reader inspect the consequences of replay directly instead of treating it like invisible framework magic.

## Protocol Changes

The protocol keeps the historical validation work and adds:

- `ReplayEngine.rebuild_report/2`
- a richer `rebuilding_time_story!/0`

Earlier layers still hold:

- past commands can be previewed
- impossible past allocations are still rejected
- the aggregate's policy still lives in the event stream

## The Code

The new code lives in [`lib/projectors/replay_engine.ex`](./lib/projectors/replay_engine.ex).

The report compares the present before and after replay:

```elixir
%{
  sector_id: sector_id,
  inserted_at: Map.fetch!(event, :effective_at),
  current_available_oxygen: current_sector.available_oxygen,
  replayed_available_oxygen: replayed_sector.available_oxygen,
  current_allocations: current_sector.allocations,
  replayed_allocations: replayed_sector.allocations,
  shifted_commands: shifted_commands(current_sector.allocations, replayed_sector.allocations)
}
```

The story helper in [`lib/wormhole_protocol.ex`](./lib/wormhole_protocol.ex) returns that report directly, so the change is easy to inspect in tests, `iex`, and Livebook.

## Trying It Out

```bash
cd 06_rebuilding_time
mix test
iex -S mix
```

In `iex`, paste:

```elixir
WormholeProtocol.rebuilding_time_story!()
```

You should see the current present with `40` oxygen remaining, the replayed present with `25`, and a shifted command list that starts with `"wormhole-1"`.

## What the Tests Prove

The test proves that replay can now be inspected as data:

- the current and replayed oxygen totals differ
- the inserted command changes the ordering of later facts

Replay is no longer an abstract promise. It is a concrete report the reader can inspect.

## Why This Matters

When systems become temporal, observability matters as much as correctness.

It is one thing for the protocol to say that history shifted. It is another thing to show exactly how the shift changed the present. Here, that second view is finally on the table.

## What Holds

Replay is not only how state is rebuilt. It can also be exposed as a deliberate comparison tool when the domain needs to inspect alternate histories.

## What Still Hurts

The replay engine can now show what changed, but identity is still fragile.

If the same command appears twice, once in the present and once through a wormhole, the protocol still needs a way to decide whether those are two commands or one command seen twice.

## Next Shift

In [`07_duplicates_across_time`](../07_duplicates_across_time/README.md), command identity becomes absolute and duplicate intent is rejected even when it crosses time.
