defmodule WormholeProtocolTest do
  use ExUnit.Case
  doctest WormholeProtocol

  setup_all do
    {:ok, _} = Application.ensure_all_started(:wormhole_protocol)
    :ok
  end

  test "replay reports still show how the present changes after a rewind" do
    report = WormholeProtocol.rebuilding_time_story!()

    assert report.current_available_oxygen == 40
    assert report.replayed_available_oxygen == 25
  end

  test "duplicate commands are still rejected across time" do
    story = WormholeProtocol.duplicates_across_time_story!()

    assert story.duplicate == {:error, {:duplicate_command, command_id: "absolute-1"}}
  end

  test "a past reactor shutdown can create a paradox" do
    story = WormholeProtocol.reactor_paradox_story!()

    assert story.shutdown == :ok
    assert story.invalidated_failures == ["wormhole_origin"]
    assert story.wormhole_origin_erased?
    assert story.reactor_status == :failed
  end
end
