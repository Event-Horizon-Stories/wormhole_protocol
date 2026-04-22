# Lesson 05: Historical Validation

Rewriting the past is no longer the whole problem. The system now has to ask whether the past it is being asked to accept was ever physically possible.

That question changes the texture of validation. Current state is not enough anymore. If a wormhole command claims it should have happened earlier, the aggregate must inspect the history as it would have unfolded from that earlier point, not merely the state the system happens to be holding now.

This chapter is where Commanded starts feeling less like a neat architecture and more like a discipline. The aggregate does not merely decide whether it likes a command. It decides whether the command can survive replay.

Interactive companion: [`../livebooks/05_historical_validation.livemd`](../livebooks/05_historical_validation.livemd)

## What You'll Learn

- how to validate a past command against replayed history
- why current state can be misleading when the effective time moves backward
- how to reject causality violations before they enter the stream
- what stayed true from the earlier policy and replay chapters

## The Story

Mission control has already agreed that some wormhole commands may rewrite the timeline. That concession buys flexibility, but it also opens a dangerous door.

A late command can now claim a place in the past where there may not have been enough oxygen to satisfy it. If the aggregate only looks at the present, it can make the wrong call. The only honest check is to replay the timeline with the candidate event inserted and ask whether the resulting history remains physically coherent.

The colony is no longer arguing about whether time can bend. It is arguing about whether the bent version can hold.

## The Commanded Concept

This lesson teaches historical validation.

In Commanded, aggregate validation does not have to stop at current state. Because state is derived from event history, the aggregate can preview a candidate event inside that history and validate against the replayed result.

That is the shift: current state is a snapshot, but replayed history is the real boundary when time-traveling commands arrive.

## What We're Building

We keep the rewrite policy from lesson 4 and add one stricter rule:

- past oxygen allocations are previewed against the event history
- if replay would drive oxygen negative, the command is rejected as a causality violation

Everything earlier still works:

- in-order allocations still succeed
- replay previews are still available
- the aggregate still records its reality policy explicitly

## The Code

The new validation lives in [`lib/aggregates/timeline_aggregate.ex`](./lib/aggregates/timeline_aggregate.ex).

For rewrite mode, the aggregate now previews the event before accepting it:

```elixir
projected_sector =
  state.facts
  |> ReplayEngine.preview(%OxygenAllocated{
    timeline_id: command.timeline_id,
    sector_id: command.sector_id,
    amount: command.amount,
    effective_at: command.effective_at,
    command_id: command.command_id
  })
  |> Map.fetch!(command.sector_id)
```

If replay would make the timeline impossible, the command is rejected:

```elixir
if projected_sector.available_oxygen < 0 do
  {:error,
   {:causality_violation,
    attempted_at: command.effective_at,
    projected_available_oxygen: projected_sector.available_oxygen}}
else
  :ok
end
```

## Trying It Out

```bash
cd 05_historical_validation
mix test
iex -S mix
```

In `iex`, paste:

```elixir
WormholeProtocol.historical_validation_story!()
```

You should get a map showing the wormhole allocation rejected with `:causality_violation` while the accepted present remains unchanged.

## What the Tests Prove

The chapter test proves that rewrite mode alone is no longer enough. A past command that would make the replayed timeline impossible is rejected before any new event is recorded.

That keeps the earlier lessons intact while making the aggregate's time-travel rule more defensible.

## Why This Matters

Event-sourced systems are often described as “history first.” This chapter shows what that really means in a validation path.

When time order becomes unstable, the current present stops being a sufficient judge. Replay becomes the way the aggregate asks whether the proposed history can stand.

## Commanded Takeaway

In Commanded, a time-sensitive command may need to be validated against replayed history, not just the current aggregate snapshot.

## What Still Hurts

The aggregate can now reject impossible past commands, but replay is still mostly hidden inside the validation path.

The colony can trust that the protocol is replaying history. It still cannot inspect the exact before-and-after shape of that replay in a clean report.

## Next Lesson

In lesson 6, the replay engine steps into the light and shows exactly how a changed past rebuilds the present.
