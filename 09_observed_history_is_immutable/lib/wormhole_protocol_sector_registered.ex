defmodule WormholeProtocol.SectorRegistered do
  @moduledoc """
  Event recording the initial oxygen available in a sector.
  """

  @derive Jason.Encoder
  @enforce_keys [:timeline_id, :sector_id, :initial_oxygen, :created_at]
  defstruct [:timeline_id, :sector_id, :initial_oxygen, :created_at]
end
