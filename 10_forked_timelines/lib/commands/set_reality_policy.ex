defmodule WormholeProtocol.Commands.SetRealityPolicy do
  @moduledoc """
  Declares how a timeline should react when a command arrives from the past.
  """

  @derive Jason.Encoder
  defstruct [:timeline_id, :policy, :decided_at]

  @type t :: %__MODULE__{
          timeline_id: String.t(),
          policy: :reject_past | :rewrite_history | :fork_on_past,
          decided_at: String.t()
        }
end
