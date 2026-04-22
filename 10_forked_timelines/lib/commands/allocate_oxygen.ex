defmodule WormholeProtocol.Commands.AllocateOxygen do
  @moduledoc """
  Command expressing the intent to allocate oxygen at a given effective time.
  """

  @derive Jason.Encoder
  @enforce_keys [:timeline_id, :sector_id, :amount, :effective_at, :command_id]
  defstruct [:timeline_id, :sector_id, :amount, :effective_at, :command_id]

  @type t :: %__MODULE__{
          timeline_id: String.t(),
          sector_id: String.t(),
          amount: pos_integer(),
          effective_at: String.t(),
          command_id: String.t()
        }
end
