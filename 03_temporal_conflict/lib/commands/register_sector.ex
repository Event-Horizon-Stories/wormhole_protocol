defmodule WormholeProtocol.Commands.RegisterSector do
  @moduledoc """
  Command to create an oxygen sector inside a timeline.
  """

  @derive Jason.Encoder
  @enforce_keys [:timeline_id, :sector_id, :initial_oxygen, :created_at]
  defstruct [:timeline_id, :sector_id, :initial_oxygen, :created_at]

  @type t :: %__MODULE__{
          timeline_id: String.t(),
          sector_id: String.t(),
          initial_oxygen: non_neg_integer(),
          created_at: String.t()
        }
end
