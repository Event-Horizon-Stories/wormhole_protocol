defmodule WormholeProtocol.ReactorShutdown do
  @moduledoc """
  Records that a reactor shutdown became part of accepted history.
  """

  @derive Jason.Encoder
  defstruct [:timeline_id, :reactor_id, :effective_at, :command_id]
end
