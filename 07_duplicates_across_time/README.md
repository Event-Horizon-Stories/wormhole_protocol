# Lesson 07: Duplicates Across Time

The wormhole does not just threaten order. It threatens identity.

A command can now appear once in the accepted present and again in the past. If the protocol only looks at timestamps, it may mistake one intent for two. That would be more than a bookkeeping error. It would let the same decision become multiple facts.

This lesson hardens the series around idempotency. The aggregate starts treating `command_id` as absolute truth, no matter when the command shows up.

Interactive companion: [`../livebooks/07_duplicates_across_time.livemd`](../livebooks/07_duplicates_across_time.livemd)

## What You'll Learn

- how to enforce idempotency inside an aggregate stream
- why duplicate detection must survive temporal anomalies
- how earlier replay behavior still works after adding identity checks
- how Commanded aggregates can defend against repeated intent

## The Story

Mission control sends an allocation command. Hours later, the same command ID comes back through a wormhole claiming a different effective time. The payload is not identical, but the identity is.

That leaves the protocol with a simple choice. Either command IDs mean something durable, or they do not mean anything at all.

The aggregate chooses durability. A command that has already become part of accepted history cannot become new history again just because it found another path through time.

## The Commanded Concept

This chapter teaches idempotency as a domain rule.

Commanded gives you a stream boundary. Your aggregate decides what counts as the same intent within that boundary. Here the rule is explicit: if the `command_id` is already present in accepted history, the new command is rejected even if its timestamp is different.

## What We're Building

We keep the replay reporting from lesson 6 and add:

- duplicate detection through `seen_command_ids`
- a `duplicates_across_time_story!/0` scenario

The earlier layers still stand:

- replay reports still work
- the aggregate still validates the past
- the public API remains `WormholeProtocol`

## The Code

The new guard lives in [`lib/wormhole_protocol_timeline_aggregate.ex`](./lib/wormhole_protocol_timeline_aggregate.ex).

The aggregate now checks identity before anything else:

```elixir
defp ensure_command_id_is_unique(state, command) do
  if command.command_id in state.seen_command_ids do
    {:error, {:duplicate_command, command_id: command.command_id}}
  else
    :ok
  end
end
```

Accepted commands append their IDs during `apply/2`, so the next execution step sees the full stream-level identity set.

## Trying It Out

```bash
cd 07_duplicates_across_time
mix test
iex -S mix
```

In `iex`, paste:

```elixir
WormholeProtocol.duplicates_across_time_story!()
```

You should get a map showing the second command rejected as `{:duplicate_command, ...}` while the accepted allocation list stays unchanged.

## What the Tests Prove

The tests prove two layers at once:

- replay reporting from lesson 6 still works
- a duplicate command is rejected even when it arrives with a past timestamp

That second assertion is the important one. Time anomalies no longer get to bypass identity.

## Why This Matters

Systems under temporal pressure become fragile fast if identity is negotiable.

Once the protocol accepts that commands may arrive out of time, it has to become stricter about what counts as the same command. Otherwise the event stream becomes vulnerable to double-spending intent.

## Commanded Takeaway

Idempotency is not a transport concern alone. In a Commanded system, it often belongs in the aggregate's own definition of valid history.

## What Still Hurts

The protocol can now handle duplicate intent, but paradox is waiting just beyond that.

Some commands do not merely duplicate history. They threaten to erase the event that made their own arrival possible.

## Next Lesson

In lesson 8, a reactor shutdown arriving in the past creates a genuine paradox against a later observed failure.
