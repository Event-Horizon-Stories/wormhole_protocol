defmodule WormholeProtocol.Router do
  @moduledoc """
  Routes tutorial commands to the timeline aggregate.
  """

  use Commanded.Commands.Router

  alias WormholeProtocol.{
    AllocateOxygen,
    OpenTimeline,
    RegisterSector,
    SetRealityPolicy,
    TimelineAggregate
  }

  identify(TimelineAggregate, by: :timeline_id)

  dispatch([OpenTimeline, RegisterSector, AllocateOxygen, SetRealityPolicy],
    to: TimelineAggregate
  )
end
