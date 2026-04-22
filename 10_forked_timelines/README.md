# Lesson 10: Forked Timelines

The anchored stream has spoken. The paradox-inducing command does not belong there.

But the colony still wants to understand the alternate history. It still wants to see the branch where the wormhole command landed earlier and the present rebuilt around it. The final chapter answers that pressure without sacrificing the original stream.

Instead of rewriting the accepted timeline, the protocol creates another one. The original history remains intact. A second aggregate is rebuilt from the same source facts plus the divergent event. Reality is no longer forced into one path.

Interactive companion: [`../livebooks/10_forked_timelines.livemd`](../livebooks/10_forked_timelines.livemd)

## What Changes

- how to model branching as separate streams rather than in-place mutation
- how to use the same public API against multiple timeline IDs
- how to preserve the original branch while materializing an alternate one
- how the full series resolves the tension between commands and anchored events

## The Story

Mission control tries the wormhole allocation against timeline A and gets the right answer for that stream: the command requires a fork.

So the protocol opens timeline B. It replays the accepted history into that new stream, inserts the wormhole allocation where it belongs, and lets the new present emerge on its own terms. Timeline A still says 40 units remain. Timeline B says 25. Neither answer erases the other.

It is not “anything goes.” It is not “the past can never change.” It is a system that can hold one anchored history and one explored alternative without lying about either.

## Under The Hood

Branching happens through separate aggregate streams.

Commanded already gives you stream identity. Here we use that identity directly. The protocol keeps the original timeline stream untouched and creates a second stream that replays the same prior events plus the divergent wormhole event.

That makes one event-sourced idea concrete: alternate presents can be modeled as alternate histories rather than as one mutable state trying to remember every possibility.

## Protocol Changes

The immutable-history rule remains, and the protocol adds:

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

Those events are then replayed into `timeline_b` through the same public API the rest of the repository has been using all along.

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

The final test proves the full resolution:

- the original timeline keeps its anchored present
- the alternate timeline is rebuilt as a separate stream
- earlier command ordering and replay logic still hold inside the branch

That is the repository's answer made concrete.

## Why This Matters

Branching is the cleanest answer the protocol can give because it honors both halves of the problem.

Observed history remains protected. Alternate history still becomes inspectable. The protocol stops pretending there must always be one final answer for every temporal anomaly.

## What Holds

Commands can travel through time.

Events decide what actually happened, and separate streams let you model what happened somewhere else.

## What Still Hurts

The branch is open, but a larger system would start asking harder operational questions here:

- which branch becomes canonical?
- how are branch-specific read models projected?
- how long are alternate streams retained?

Those are real problems. They belong one layer past the boundary this repository is holding.

## Where The Series Could Go Next

Natural follow-on chapters would include:

- projectors that rebuild multiple read models from competing timelines
- persistent event stores and stream retention policies
- process managers reacting differently per timeline
- event-journal integration where durable history and live branching meet
