# Lesson 03: Temporal Conflict

The colony has seen the anomaly. Now it wants to know what the anomaly would cost.

A wormhole command asking for oxygen at 09:55 may be easy to reject. It is much harder to look directly at the alternate history and admit what it would do to the present. In this chapter, the protocol does exactly that. It builds a preview of the rewritten timeline without yet accepting it.

That is the first moment the tutorial starts to feel like event sourcing under pressure. State stops looking like a stable object and starts looking like a reading taken from a particular ordering of facts.

Interactive companion: [`../livebooks/03_temporal_conflict.livemd`](../livebooks/03_temporal_conflict.livemd)

## What You'll Learn

- how to preview a hypothetical event without committing it to the stream
- how replay reveals the cost of rewriting history
- why present state is only one projection of accepted event order
- how the chapter still keeps the lesson 2 rejection rule intact

## The Story

At 10:00 the sector had enough oxygen. At 10:05 the operators believed there were 10 units left. Then the wormhole command arrived and claimed 15 units should have been allocated at 09:55.

If that claim were accepted, the rest of the known day would have to be replayed after it. The later allocations would not disappear. They would land on top of a different past. The new present would no longer say 10. It would say negative 5.

This is the temporal conflict. Not bad data. Not a timeout. A history that leads to a different now.

## The Commanded Concept

This lesson is about replay as a reasoning tool.

Commanded aggregates rebuild state from events anyway. Here we expose that idea directly. Instead of recording a new event, the replay engine previews what the state would become if one extra event were inserted into the historical sequence.

That preview is not yet a commitment. It is a way to inspect the consequence of a changed past before deciding what to do about it.

## What We're Building

We keep the same command flow from lesson 2 and add:

- `ReplayEngine.preview/2`
- a `temporal_conflict_story!/0` helper that compares the current present with a replayed one

Nothing has been rewritten yet. The aggregate still rejects past commands. The difference is that the protocol can now explain the damage they would cause.

## The Code

The new mechanism lives in [`lib/wormhole_protocol_replay_engine.ex`](./lib/wormhole_protocol_replay_engine.ex) and is exercised from [`lib/wormhole_protocol.ex`](./lib/wormhole_protocol.ex).

The preview helper is intentionally small:

```elixir
def preview(facts, event) do
  rebuild(facts ++ [%{recorded_order: length(facts) + 1, event: event}])
end
```

The story helper uses that preview to compare two presents:

```elixir
%{
  current_available_oxygen: state.sectors["hab-3"].available_oxygen,
  projected_available_oxygen: preview["hab-3"].available_oxygen,
  projected_allocations: preview["hab-3"].allocations,
  would_go_negative?: preview["hab-3"].available_oxygen < 0
}
```

## Trying It Out

```bash
cd 03_temporal_conflict
mix test
iex -S mix
```

In `iex`, paste:

```elixir
WormholeProtocol.temporal_conflict_story!()
```

You should see a map where the current timeline has `10` oxygen left, but the replayed timeline drops to `-5`.

## What the Tests Prove

The chapter test keeps the earlier linear and anomaly behavior, then adds a new assertion that the replay preview changes the allocation order and the resulting present.

That is important because replay is not theoretical here. The test shows the exact branch point and the exact cost.

## Why This Matters

Many event-sourced systems say that state is derived from history. This chapter makes you feel it.

The moment the replayed present differs from the current one, the abstraction stops being decorative. History becomes the thing that really matters.

## Commanded Takeaway

Replay is not just a recovery mechanism. It is the reason a changed history produces a changed present.

## What Still Hurts

The protocol can now preview alternate reality, but it still has no rule for choosing one.

Should a past command always be rejected? Can it ever be accepted? If it is accepted, who gets to decide that reality should bend?

## Next Lesson

In lesson 4, the aggregate stops behaving like a passive guard and declares its policy for reality itself.
