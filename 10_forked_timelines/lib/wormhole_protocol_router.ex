defmodule WormholeProtocol.Router do
  @moduledoc """
  Routes tutorial commands to the timeline aggregate.
  """

  use Commanded.Commands.Router

  alias WormholeProtocol.{
    AllocateOxygen,
    OpenTimeline,
    RecordReactorFailure,
    RegisterReactor,
    RegisterSector,
    SetRealityPolicy,
    ShutdownReactor,
    TimelineAggregate
  }

  identify(TimelineAggregate, by: :timeline_id)

  dispatch(
    [
      OpenTimeline,
      RegisterSector,
      SetRealityPolicy,
      AllocateOxygen,
      RegisterReactor,
      RecordReactorFailure,
      ShutdownReactor
    ],
    to: TimelineAggregate
  )
end
