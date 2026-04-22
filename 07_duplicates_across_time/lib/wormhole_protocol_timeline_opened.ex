defmodule WormholeProtocol.TimelineOpened do
  @moduledoc """
  Event recording that a timeline now exists.
  """

  @derive Jason.Encoder
  @enforce_keys [:timeline_id, :opened_at]
  defstruct [:timeline_id, :opened_at]
end
