# Lesson 01: Linear Time

The network is quiet enough to trust.

Mars opens a timeline. A habitat registers its oxygen reserve. Mission control issues an allocation command, and the event lands exactly where everyone expects it to land. The present feels stable because nothing has challenged the order of things yet.

That calm is useful. Before the wormholes start bending the protocol, Commanded should first feel clean and ordinary in your hands. This lesson builds that baseline and lets the timeline move forward without argument.

Interactive companion: [`../livebooks/01_linear_time.livemd`](../livebooks/01_linear_time.livemd)

## What You'll Learn

- how a Commanded application routes commands into an aggregate stream
- how commands and events differ in the baseline linear flow
- how aggregate state is rebuilt from recorded events
- how to expose a small public API around a Commanded app

## The Story

The colony does not begin in crisis. It begins in routine.

Habitat `hab-3` draws oxygen at 10:00. It draws again at 10:05. Operators do not question whether those requests belong in the past or the future. They simply trust that each command describes intent for the present moment and that each resulting event becomes part of a steady, accumulating history.

That is the first shape of the Wormhole Command Protocol: intent enters the stream, fact leaves it, and state advances one accepted event at a time.

## The Commanded Concept

This lesson focuses on the core Commanded loop:

1. dispatch a command
2. let the aggregate decide whether it is valid
3. record an event when it is
4. rebuild state by applying the event history

The important mental split is simple. A command says what someone wants. An event says what the system accepted as true.

## What We're Building

We build the first version of `WormholeProtocol`:

- a `WormholeProtocol.CommandedApp`
- a `WormholeProtocol.Router`
- a `WormholeProtocol.Aggregates.TimelineAggregate`
- a tiny public API in [`lib/wormhole_protocol.ex`](./lib/wormhole_protocol.ex)

The protocol can:

- open a timeline
- register an oxygen sector
- allocate oxygen in time order

## The Code

This lesson's core files are:

- [`lib/wormhole_protocol.ex`](./lib/wormhole_protocol.ex)
- [`lib/router/router.ex`](./lib/router/router.ex)
- [`lib/aggregates/timeline_aggregate.ex`](./lib/aggregates/timeline_aggregate.ex)
- [`lib/projectors/replay_engine.ex`](./lib/projectors/replay_engine.ex)

The public API keeps the first chapter readable:

```elixir
def open_timeline(timeline_id) do
  dispatch(%OpenTimeline{timeline_id: timeline_id})
end

def register_sector(timeline_id, sector_id, initial_oxygen, created_at) do
  dispatch(%RegisterSector{
    timeline_id: timeline_id,
    sector_id: sector_id,
    initial_oxygen: initial_oxygen,
    created_at: created_at
  })
end
```

Inside the aggregate, accepted intent becomes recorded fact:

```elixir
def execute(%__MODULE__{} = state, %AllocateOxygen{} = command) do
  with {:ok, sector} <- fetch_sector(state, command.sector_id),
       :ok <- ensure_effective_after_creation(sector, command),
       :ok <- ensure_available_oxygen(sector, command) do
    %OxygenAllocated{
      timeline_id: command.timeline_id,
      sector_id: command.sector_id,
      amount: command.amount,
      effective_at: command.effective_at,
      command_id: command.command_id
    }
  end
end
```

## Trying It Out

```bash
cd 01_linear_time
mix deps.get
mix test
iex -S mix
```

In `iex`, paste:

```elixir
WormholeProtocol.linear_story!()
```

You should get a map showing the accepted facts, the current sector state, and `40` oxygen remaining.

## What the Tests Prove

[`test/wormhole_protocol_test.exs`](./test/wormhole_protocol_test.exs) proves that:

- valid oxygen commands become events and reduce the sector's available oxygen
- invalid allocations are rejected when the sector does not have enough supply

That second test matters because the aggregate is already doing more than storing data. It is deciding what history is allowed to exist.

## Why This Matters

When Commanded is new, it helps to start where nothing is strange.

Linear time makes the event-sourced contract visible without extra noise. You can see the command boundary, the event boundary, and the rebuilt state before any temporal anomaly tries to blur them together.

## Commanded Takeaway

In Commanded, state is not the source of truth. Accepted events are.

The aggregate reads the current history, decides whether a command is valid, and emits the next fact.

## What Still Hurts

The timeline only feels safe because every command arrives in order.

The moment a command appears with a timestamp earlier than the accepted present, the baseline rules stop being enough.

## Next Lesson

In lesson 2, the first wormhole anomaly arrives: a command reaches the system too late for the time it claims to belong to.
