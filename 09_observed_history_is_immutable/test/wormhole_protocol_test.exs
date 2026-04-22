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

  test "observed failures anchor reality against paradoxical shutdowns" do
    story = WormholeProtocol.observed_history_story!()

    assert story.invalidated_failures == ["wormhole_origin"]
    assert story.wormhole_origin_erased?

    assert story.shutdown ==
             {:error, {:violates_observed_history, invalidated_failures: ["wormhole_origin"]}}

    assert story.reactor_status == :failed
  end
end
