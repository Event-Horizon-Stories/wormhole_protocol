# Lesson 04: Rules Of Reality

The question is no longer whether the past can be different. The replay preview already proved that it can.

The real question now is who decides whether that difference is allowed to count.

Here, the answer moves into the aggregate itself. The timeline declares a policy. It can reject commands from the past, or it can accept them and rewrite history. The same incoming command now produces different outcomes depending on the rule the aggregate is enforcing.

Interactive companion: [`../livebooks/04_rules_of_reality.livemd`](../livebooks/04_rules_of_reality.livemd)

## What Changes

- how aggregates can encode domain policy, not just input validation
- how to model configuration changes as commands and events
- how the same past-arriving command can be rejected or accepted depending on aggregate state
- what stayed true from the earlier replay-based chapters

## The Story

Mission control has to choose how strict the protocol should be. One school argues that the accepted present must never be disturbed. Another argues that a wormhole command is still real intent and should be allowed to reshape the timeline if the system can bear it.

That choice cannot live in a comment or in an operator handbook. It has to live in the same place all the other consistency rules live: the aggregate.

So the protocol becomes more honest. It records the policy it is using, then applies that policy when the next impossible command arrives.

## Under The Hood

The aggregate is no longer just checking values. It is defining the rules of reality for its consistency boundary.

In Commanded, that does not just mean checking values. It also means making policy part of the stream. A configuration change like “rewrite history when past commands arrive” becomes its own command and event, and the aggregate's later decisions depend on that recorded choice.

## Protocol Changes

The protocol extends the existing app with:

- `SetRealityPolicy`
- `RealityPolicySet`
- a `reality_policy` field in the aggregate state

Earlier behavior still holds:

- in-order oxygen allocations still work
- replay still previews alternate history
- past commands are still rejected by default

The new layer is that the aggregate can switch to `:rewrite_history`.

## The Code

The new pieces live in:

- [`lib/commands/set_reality_policy.ex`](./lib/commands/set_reality_policy.ex)
- [`lib/events/reality_policy_set.ex`](./lib/events/reality_policy_set.ex)
- [`lib/aggregates/timeline_aggregate.ex`](./lib/aggregates/timeline_aggregate.ex)

The policy command becomes part of the aggregate's decision surface:

```elixir
def execute(%__MODULE__{} = state, %SetRealityPolicy{} = command) do
  policy = normalize_policy(command.policy)

  if state.reality_policy == policy do
    {:error, :policy_already_set}
  else
    %RealityPolicySet{
      timeline_id: command.timeline_id,
      policy: policy,
      decided_at: command.decided_at
    }
  end
end
```

And past command handling now depends on that state:

```elixir
defp allow_past_command?(%__MODULE__{reality_policy: :reject_past}, sector, _command) do
  {:error, {:command_arrived_in_the_past, latest_accepted_time: sector.latest_effective_at}}
end

defp allow_past_command?(%__MODULE__{reality_policy: :rewrite_history}, _sector, _command), do: :ok
```

## Trying It Out

```bash
cd 04_rules_of_reality
mix test
iex -S mix
```

In `iex`, paste:

```elixir
WormholeProtocol.rules_of_reality_story!()
```

You should see the same wormhole allocation rejected once, then accepted after the policy changes to `:rewrite_history`.

## What the Tests Prove

The test suite proves that the aggregate can move from rejecting a past command to accepting it after the policy event is recorded.

That matters because the protocol is now evolving through its own event history, not through hidden runtime flags.

## Why This Matters

This is where Commanded begins to feel like a real domain model.

The aggregate is no longer just checking arithmetic. It is naming the rule that decides whether a changed past is even allowed into the stream.

## What Holds

In Commanded, policy can be evented too.

If a rule matters to later decisions, it belongs in the aggregate's history.

## What Still Hurts

Accepting a past command under a rewrite policy is dramatic, but it is still careless.

The protocol can now bend time on purpose, yet it still does not ask whether the rewritten past was actually possible.

## Next Shift

Next, the aggregate stops validating against the current present and starts validating against replayed historical state.
