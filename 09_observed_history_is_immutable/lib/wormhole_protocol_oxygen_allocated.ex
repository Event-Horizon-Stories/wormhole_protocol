defmodule WormholeProtocol.OxygenAllocated do
  @moduledoc """
  Event recording that oxygen was successfully allocated.
  """

  @derive Jason.Encoder
  @enforce_keys [:timeline_id, :sector_id, :amount, :effective_at, :command_id]
  defstruct [:timeline_id, :sector_id, :amount, :effective_at, :command_id]
end
