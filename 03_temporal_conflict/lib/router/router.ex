defmodule WormholeProtocol.Router do
  @moduledoc """
  Routes tutorial commands to the timeline aggregate.
  """

  use Commanded.Commands.Router

  alias WormholeProtocol.{Aggregates, Commands}

  identify(Aggregates.TimelineAggregate, by: :timeline_id)

  dispatch([Commands.OpenTimeline, Commands.RegisterSector, Commands.AllocateOxygen],
    to: Aggregates.TimelineAggregate
  )
end
