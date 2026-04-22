# Lesson 09: Observed History Is Immutable

The colony can no longer afford polite ambiguity.

Once the protocol has seen a reactor paradox in full, it has to decide what outranks what. The answer becomes explicit. Observed events become the anchor. Commands may still arrive from the past, but they are rejected if replay would erase the footing of something the system has already recorded as observed reality.

This is the sternest turn in the protocol so far. The aggregate stops treating replay as a thought experiment and turns it into a guardrail.

Interactive companion: [`../livebooks/09_observed_history_is_immutable.livemd`](../livebooks/09_observed_history_is_immutable.livemd)

## What Changes

- how to turn a replay report into an aggregate invariant
- how to reject commands that invalidate observed history
- why events can outrank commands in a Commanded model
- how the reactor paradox becomes a true consistency rule

## The Story

The reactor failure at 10:00 was not speculation. It was observed. Operators saw it. The wormhole exists because of it. The stream recorded it.

So when the 09:50 shutdown command arrives, the protocol refuses to treat it as just another interesting possibility. It asks replay whether the shutdown would invalidate the observed failure. When the answer is yes, the command is rejected.

Reality is no longer defined only by what a command asks for. It is defined by what the event history has already anchored as true.

## Under The Hood

The boundary is clean:

- commands are proposals
- events are accepted facts
- observed facts may constrain what later commands are allowed to rewrite

The aggregate uses replay to inspect the candidate history, then rejects commands that would invalidate anchored observations.

## Protocol Changes

The reactor model remains, and the protocol adds one crucial rule:

- past reactor shutdowns in rewrite mode must pass `ensure_observed_history_survives/3`

Earlier capabilities remain:

- replay reports still exist
- reactor paradoxes can still be previewed
- the public API and module names remain unchanged

## The Code

The new invariant lives in [`lib/aggregates/timeline_aggregate.ex`](./lib/aggregates/timeline_aggregate.ex).

The aggregate converts the paradox report into a rejection:

```elixir
if report.invalidated_failures == [] do
  :ok
else
  {:error, {:violates_observed_history, invalidated_failures: report.invalidated_failures}}
end
```

That check sits in the shutdown execution path after the aggregate has already confirmed that the command is otherwise well formed and historically positioned.

## Trying It Out

```bash
cd 09_observed_history_is_immutable
mix test
iex -S mix
```

In `iex`, paste:

```elixir
WormholeProtocol.observed_history_story!()
```

You should see the paradox preview still reporting `"wormhole_origin"` as invalidated, but the actual shutdown command now returns `{:error, {:violates_observed_history, ...}}`.

## What the Tests Prove

The test proves two things:

- replay still shows the alternate history clearly
- the aggregate refuses to admit that history into the stream once it would invalidate an observed failure

That is the moment the protocol becomes anchored instead of merely descriptive.

## Why This Matters

Event-sourced systems become dangerous if every command can reopen every fact.

The principle is durable: once a fact has become anchored observed history, later commands may have to yield to it. Commanded gives you the tools to encode that principle directly inside the aggregate.

## What Holds

Commands can ask for change. Events decide what the system is willing to keep as reality.

## What Still Hurts

Rejecting the shutdown preserves one timeline, but it does not solve the operator's original desire to explore the alternate branch.

The command may be too dangerous for the anchored stream, yet still worth examining somewhere else.

## Next Shift

Next, the protocol stops forcing a single answer and materializes a second timeline instead.
