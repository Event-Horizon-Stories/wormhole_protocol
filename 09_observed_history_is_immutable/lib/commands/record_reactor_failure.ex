defmodule WormholeProtocol.Commands.RecordReactorFailure do
  @moduledoc """
  Records an observed reactor failure that later commands must respect.
  """

  @derive Jason.Encoder
  defstruct [:timeline_id, :reactor_id, :failed_at, :reason]
end
