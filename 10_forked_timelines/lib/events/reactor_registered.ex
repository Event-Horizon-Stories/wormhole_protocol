defmodule WormholeProtocol.Events.ReactorRegistered do
  @moduledoc """
  Records that a reactor entered the timeline.
  """

  @derive Jason.Encoder
  defstruct [:timeline_id, :reactor_id, :created_at]
end
