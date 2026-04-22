defmodule WormholeProtocolTest do
  use ExUnit.Case
  doctest WormholeProtocol

  setup_all do
    {:ok, _} = Application.ensure_all_started(:wormhole_protocol)
    :ok
  end

  test "replay reports show how the present changes after a rewind" do
    report = WormholeProtocol.rebuilding_time_story!()

    assert report.current_available_oxygen == 40
    assert report.replayed_available_oxygen == 25
    assert report.inserted_at == "09:55"
    assert report.shifted_commands == ["wormhole-1", "alloc-1", "alloc-2"]
  end

  test "duplicate commands are rejected even when they arrive at a different time" do
    story = WormholeProtocol.duplicates_across_time_story!()

    assert story.duplicate == {:error, {:duplicate_command, command_id: "absolute-1"}}
    assert story.seen_command_ids == ["absolute-1"]

    assert story.allocations == [
             %{amount: 30, command_id: "absolute-1", effective_at: "10:00"}
           ]
  end
end
