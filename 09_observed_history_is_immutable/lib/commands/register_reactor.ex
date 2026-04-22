defmodule WormholeProtocol.Commands.RegisterReactor do
  @moduledoc """
  Creates a reactor that later events can act upon.
  """

  @derive Jason.Encoder
  defstruct [:timeline_id, :reactor_id, :created_at]
end
