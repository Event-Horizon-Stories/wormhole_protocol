# Lesson 02: The First Wormhole Anomaly

The protocol is still young when the first impossible request arrives.

Mission control receives an oxygen allocation at 10:05, but the command carries an effective time of 09:55. Nothing about the payload is malformed. The problem is deeper than syntax. The request belongs to a past the aggregate has already moved beyond.

This is the first real fracture in the series. The same `WormholeProtocol` app from lesson 1 is still here. The same timeline, sector, and allocation flow still work. What changes is that the aggregate now has to notice when arrival order and event-time order diverge.

Interactive companion: [`../livebooks/02_first_wormhole_anomaly.livemd`](../livebooks/02_first_wormhole_anomaly.livemd)

## What You'll Learn

- how to detect a past-arriving command inside an aggregate
- why current state alone is not enough once time order matters
- how aggregate validation can reject a command before any new event is recorded
- what stayed the same from the linear baseline

## The Story

The oxygen ledger has already moved on. `hab-3` allocated oxygen at 10:00 and again at 10:05. Operators are looking at the present reading when a wormhole-delivered command appears and insists it should have taken effect at 09:55.

The colony cannot casually accept that claim. If the command belongs in the past, then the present may already be wrong. If the command does not belong, then the system must say so explicitly.

So the protocol does the only honest thing it can do in this chapter: it refuses the command and names the boundary it crossed.

## The Commanded Concept

This lesson teaches a Commanded truth that becomes more important later: aggregates validate commands against the history they currently accept as real.

Right now the aggregate does not rewrite the timeline. It simply guards it. If a command arrives earlier than the latest accepted effective time for a sector, the aggregate rejects it rather than pretending linear time still holds.

## What We're Building

We keep the lesson 1 app and add one new rule:

- sectors now track `latest_effective_at`
- oxygen commands are rejected when they try to arrive earlier than that accepted point

Everything else stays true:

- commands still route through the same `WormholeProtocol.Router`
- the same aggregate still owns timeline consistency
- the same replay engine still rebuilds state from facts

## The Code

The new logic lives in [`lib/aggregates/timeline_aggregate.ex`](./lib/aggregates/timeline_aggregate.ex) and [`lib/projectors/replay_engine.ex`](./lib/projectors/replay_engine.ex).

The aggregate now checks whether a command belongs to an already-settled past:

```elixir
defp ensure_command_is_not_in_the_past(sector, command) do
  if command.effective_at < sector.latest_effective_at do
    {:error, {:command_arrived_in_the_past, latest_accepted_time: sector.latest_effective_at}}
  else
    :ok
  end
end
```

The replay engine tracks the last accepted effective time while rebuilding:

```elixir
%{
  sector
  | allocations: sector.allocations ++ [allocation],
    available_oxygen: sector.available_oxygen - event.amount,
    latest_effective_at: event.effective_at
}
```

## Trying It Out

```bash
cd 02_first_wormhole_anomaly
mix test
iex -S mix
```

In `iex`, paste:

```elixir
WormholeProtocol.anomaly_story!()
```

You should see the anomaly rejected with `{:command_arrived_in_the_past, ...}` and the accepted allocations left unchanged.

## What the Tests Prove

[`test/wormhole_protocol_test.exs`](./test/wormhole_protocol_test.exs) still proves the lesson 1 linear behavior, and it now adds a regression test for the wormhole anomaly.

That matters because this chapter is not a new demo. It is the same app with a sharper rule about time.

## Why This Matters

The first anomaly forces the reader to separate two ideas that often stay blurred in ordinary systems:

- when the command arrived
- when the command claims it should take effect

Commanded does not solve that question for you. Your aggregate does.

## Commanded Takeaway

An aggregate is not just a state machine. It is the boundary that decides whether a command belongs inside the accepted history.

## What Still Hurts

Rejecting the past is safe, but it is also blunt.

The system can now recognize a temporal anomaly, but it still cannot answer the harder question: what would happen if the colony chose to insert that command into history anyway?

## Next Lesson

In lesson 3, the protocol stops guessing and previews the conflict by replaying the timeline with a hypothetical past event inserted into it.
