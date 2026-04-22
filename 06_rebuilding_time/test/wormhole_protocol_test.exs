defmodule WormholeProtocolTest do
  use ExUnit.Case
  doctest WormholeProtocol

  setup_all do
    {:ok, _} = Application.ensure_all_started(:wormhole_protocol)
    :ok
  end

  test "commands append events and state evolves forward through time" do
    story = WormholeProtocol.linear_story!()

    assert story.available_oxygen == 40

    assert story.allocations == [
             %{amount: 40, command_id: "alloc-1", effective_at: "10:00"},
             %{amount: 20, command_id: "alloc-2", effective_at: "10:05"}
           ]
  end

  test "cannot allocate more oxygen than the sector contains" do
    :ok = WormholeProtocol.open_timeline("pressure-test")
    :ok = WormholeProtocol.register_sector("pressure-test", "hab-3", 100, "09:50")

    assert {:error, :insufficient_oxygen} =
             WormholeProtocol.allocate_oxygen(
               "pressure-test",
               "hab-3",
               101,
               "10:00",
               command_id: "alloc-3"
             )
  end

  test "rejects a command that arrives earlier than the accepted present" do
    story = WormholeProtocol.anomaly_story!()

    assert story.anomaly ==
             {:error, {:command_arrived_in_the_past, latest_accepted_time: "10:05"}}

    assert Enum.map(story.allocations, & &1.command_id) == ["alloc-1", "alloc-2"]
  end

  test "can preview the timeline split caused by a past command" do
    story = WormholeProtocol.temporal_conflict_story!()

    assert story.current_available_oxygen == 10
    assert story.projected_available_oxygen == -5
    assert story.would_go_negative?

    assert Enum.map(story.projected_allocations, & &1.command_id) == [
             "wormhole-1",
             "alloc-1",
             "alloc-2"
           ]
  end

  test "rewriting history without validation is no longer allowed" do
    story = WormholeProtocol.historical_validation_story!()

    assert story.impossible ==
             {:error,
              {:causality_violation, attempted_at: "09:55", projected_available_oxygen: -5}}

    assert story.available_oxygen == 10
    assert Enum.map(story.allocations, & &1.command_id) == ["alloc-1", "alloc-2"]
  end

  test "replay reports show how the present changes after a rewind" do
    report = WormholeProtocol.rebuilding_time_story!()

    assert report.current_available_oxygen == 40
    assert report.replayed_available_oxygen == 25
    assert report.inserted_at == "09:55"
    assert report.shifted_commands == ["wormhole-1", "alloc-1", "alloc-2"]
  end
end
