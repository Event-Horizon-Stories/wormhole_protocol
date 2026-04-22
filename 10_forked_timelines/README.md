# Lesson 10: Forked Timelines

The anchored stream has spoken. The paradox-inducing command does not belong there.

But the colony still wants to understand the alternate history. It still wants to see the branch where the wormhole command landed earlier and the present rebuilt around it. The final chapter answers that pressure without sacrificing the original stream.

Instead of rewriting the accepted timeline, the protocol creates another one. The original history remains intact. A second aggregate is rebuilt from the same source facts plus the divergent event. Reality is no longer forced into one path.

Interactive companion: [`../livebooks/10_forked_timelines.livemd`](../livebooks/10_forked_timelines.livemd)

## What You'll Learn

- how to model branching as separate streams rather than in-place mutation
- how to use the same public API against multiple timeline IDs
- how to preserve the original branch while materializing an alternate one
- how the full series resolves the tension between commands and anchored events

## The Story

Mission control tries the wormhole allocation against timeline A and gets the right answer for that stream: the command requires a fork.

So the protocol opens timeline B. It replays the accepted history into that new stream, inserts the wormhole allocation where it belongs, and lets the new present emerge on its own terms. Timeline A still says 40 units remain. Timeline B says 25. Neither answer erases the other.

This is the ending the series has been earning from the start. Not “anything goes.” Not “the past can never change.” A system that can hold one anchored history and one explored alternative without lying about either.

## The Commanded Concept

This lesson teaches branching through separate aggregate streams.

Commanded already gives you stream identity. Here we use that identity directly. The protocol keeps the original timeline stream untouched and creates a second stream that replays the same prior events plus the divergent wormhole event.

That lets the reader see a powerful event-sourced idea in concrete form: alternate presents can be modeled as alternate histories rather than as one mutable state trying to remember every possibility.

## What We're Building

We keep the immutable-history rule from lesson 9 and add:

- `forked_timelines_story!/0`
- a private `fork_timeline!/3` helper that replays source events into a new timeline ID

Everything earlier still matters:

- observed history still anchors the original stream
- replay is still the mechanism underneath reconstruction
- the same `WormholeProtocol` public API drives both branches

## The Code

The branching logic lives in [`lib/wormhole_protocol.ex`](./lib/wormhole_protocol.ex).

The original stream refuses the wormhole command:

```elixir
attempted =
  allocate_oxygen(timeline_a, "hab-3", 15, "09:55", command_id: "wormhole-1")
```

Then the branch is materialized by replaying the source events into a new stream:

```elixir
facts =
  source_timeline_id
  |> timeline_state!()
  |> Map.fetch!(:facts)

events =
  facts
  |> Enum.map(& &1.event)
  |> Kernel.++([branch_event])
  |> Enum.sort_by(&event_order_key/1)
```

Those events are then replayed into `timeline_b` through the same public API the earlier lessons already taught.

## Trying It Out

```bash
cd 10_forked_timelines
mix test
iex -S mix
```

In `iex`, paste:

```elixir
WormholeProtocol.forked_timelines_story!()
```

You should see timeline A reject the wormhole allocation with `:requires_timeline_fork`, while timeline B materializes a different allocation order and a different remaining oxygen total.

## What the Tests Prove

The final chapter test proves the full resolution:

- the original timeline keeps its anchored present
- the alternate timeline is rebuilt as a separate stream
- earlier command ordering and replay logic still hold inside the branch

That is the cumulative promise of the whole repo made concrete.

## Why This Matters

Branching is the cleanest answer the series has offered because it honors both halves of the problem.

Observed history remains protected. Alternate history still becomes inspectable. The protocol stops pretending there must always be one final answer for every temporal anomaly.

## Commanded Takeaway

Commands can travel through time.

Events decide what actually happened, and separate streams let you model what happened somewhere else.

## What Still Hurts

This series ends where a larger system would begin asking new operational questions:

- which branch becomes canonical?
- how are branch-specific read models projected?
- how long are alternate streams retained?

Those are real problems. They simply belong one layer past the core Commanded lesson this repo was built to teach.

## Where The Series Could Go Next

Natural follow-on chapters would include:

- projectors that rebuild multiple read models from competing timelines
- persistent event stores and stream retention policies
- process managers reacting differently per timeline
- event-journal integration where durable history and live branching meet
