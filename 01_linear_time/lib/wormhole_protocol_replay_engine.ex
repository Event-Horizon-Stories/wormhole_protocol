defmodule WormholeProtocol.ReplayEngine do
  @moduledoc """
  Rebuilds timeline state from the accepted domain events.

  The same mechanism becomes more interesting once later lessons allow commands
  to arrive with timestamps in the past.
  """

  @type sector_state :: %{
          sector_id: String.t(),
          created_at: String.t(),
          initial_oxygen: non_neg_integer(),
          available_oxygen: integer(),
          allocations: [map()]
        }

  @doc """
  Rebuilds the sector map from recorded facts.
  """
  @spec rebuild([map()]) :: %{optional(String.t()) => sector_state()}
  def rebuild(facts) do
    facts
    |> Enum.sort_by(&{event_time(&1.event), &1.recorded_order})
    |> Enum.reduce(%{}, &apply_event/2)
  end

  defp apply_event(%{event: %WormholeProtocol.TimelineOpened{}}, sectors), do: sectors

  defp apply_event(%{event: %WormholeProtocol.SectorRegistered{} = event}, sectors) do
    Map.put(sectors, event.sector_id, %{
      sector_id: event.sector_id,
      created_at: event.created_at,
      initial_oxygen: event.initial_oxygen,
      available_oxygen: event.initial_oxygen,
      allocations: []
    })
  end

  defp apply_event(%{event: %WormholeProtocol.OxygenAllocated{} = event}, sectors) do
    Map.update!(sectors, event.sector_id, fn sector ->
      allocation = %{
        command_id: event.command_id,
        amount: event.amount,
        effective_at: event.effective_at
      }

      %{
        sector
        | allocations: sector.allocations ++ [allocation],
          available_oxygen: sector.available_oxygen - event.amount
      }
    end)
  end

  defp event_time(%{effective_at: effective_at}), do: effective_at
  defp event_time(%{created_at: created_at}), do: created_at
end
