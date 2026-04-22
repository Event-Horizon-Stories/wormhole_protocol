defmodule WormholeProtocol.Events.RealityPolicySet do
  @moduledoc """
  Records the policy that the aggregate will use when wormhole commands arrive.
  """

  @derive Jason.Encoder
  defstruct [:timeline_id, :policy, :decided_at]

  @type t :: %__MODULE__{
          timeline_id: String.t(),
          policy: :reject_past | :rewrite_history | :fork_on_past,
          decided_at: String.t()
        }
end
