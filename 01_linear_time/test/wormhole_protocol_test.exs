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
end
