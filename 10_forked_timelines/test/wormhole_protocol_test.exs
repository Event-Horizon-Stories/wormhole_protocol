defmodule WormholeProtocolTest do
  use ExUnit.Case
  doctest WormholeProtocol

  setup_all do
    {:ok, _} = Application.ensure_all_started(:wormhole_protocol)
    :ok
  end

  test "observed failures still anchor reality against paradoxical shutdowns" do
    story = WormholeProtocol.observed_history_story!()

    assert story.shutdown ==
             {:error, {:violates_observed_history, invalidated_failures: ["wormhole_origin"]}}
  end

  test "forked timelines preserve the original branch and materialize a new one" do
    story = WormholeProtocol.forked_timelines_story!()

    assert story.attempted ==
             {:error,
              {:requires_timeline_fork, attempted_at: "09:55", latest_accepted_time: "10:05"}}

    assert story.timeline_a_available_oxygen == 40
    assert story.timeline_b_available_oxygen == 25

    assert Enum.map(story.timeline_b_allocations, & &1.command_id) == [
             "wormhole-1",
             "alloc-1",
             "alloc-2"
           ]
  end
end
