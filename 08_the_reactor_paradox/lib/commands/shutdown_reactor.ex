defmodule WormholeProtocol.Commands.ShutdownReactor do
  @moduledoc """
  Requests that a reactor be shut down, possibly from the past.
  """

  @derive Jason.Encoder
  defstruct [:timeline_id, :reactor_id, :effective_at, :command_id]
end
