defmodule WormholeProtocol.CommandedApp do
  @moduledoc """
  The Commanded application used by the tutorial.

  The series uses Commanded's in-memory event store adapter so each lesson stays
  runnable without external infrastructure.
  """

  use Commanded.Application,
    otp_app: :wormhole_protocol,
    event_store: [
      adapter: Commanded.EventStore.Adapters.InMemory,
      serializer: Commanded.Serialization.JsonSerializer
    ],
    pubsub: :local,
    registry: :local

  router(WormholeProtocol.Router)
end
