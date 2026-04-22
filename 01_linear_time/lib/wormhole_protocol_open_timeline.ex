defmodule WormholeProtocol.OpenTimeline do
  @moduledoc """
  Command to open a new timeline.
  """

  @derive Jason.Encoder
  @enforce_keys [:timeline_id]
  defstruct [:timeline_id]

  @type t :: %__MODULE__{timeline_id: String.t()}
end
