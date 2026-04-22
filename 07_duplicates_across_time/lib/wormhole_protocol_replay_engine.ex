defmodule WormholeProtocol.ReplayEngine do
  @moduledoc """
  Rebuilds timeline state from the accepted domain events.

  Lesson 6 makes replay explicit by returning a report that compares the
  current present to the present created after a wormhole command is inserted.
  """

  @type sector_state :: %{
          sector_id: String.t(),
          created_at: String.t(),
          initial_oxygen: non_neg_integer(),
          available_oxygen: integer(),
          allocations: [map()],
          latest_effective_at: String.t()
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

  @doc """
  Rebuilds state as if a new event had been inserted into history.
  """
  @spec preview([map()], struct()) :: %{optional(String.t()) => sector_state()}
  def preview(facts, event) do
    rebuild(facts ++ [%{recorded_order: length(facts) + 1, event: event}])
  end

  @doc """
  Builds a report showing how the present changes after replay.
  """
  @spec rebuild_report([map()], struct()) :: map()
  def rebuild_report(facts, event) do
    current = rebuild(facts)
    replayed = preview(facts, event)
    sector_id = Map.fetch!(event, :sector_id)

    current_sector = Map.fetch!(current, sector_id)
    replayed_sector = Map.fetch!(replayed, sector_id)

    %{
      sector_id: sector_id,
      inserted_at: Map.fetch!(event, :effective_at),
      current_available_oxygen: current_sector.available_oxygen,
      replayed_available_oxygen: replayed_sector.available_oxygen,
      current_allocations: current_sector.allocations,
      replayed_allocations: replayed_sector.allocations,
      shifted_commands: shifted_commands(current_sector.allocations, replayed_sector.allocations)
    }
  end

  defp shifted_commands(current_allocations, replayed_allocations) do
    current_order = Enum.map(current_allocations, & &1.command_id)
    replayed_order = Enum.map(replayed_allocations, & &1.command_id)

    replayed_order
    |> Enum.with_index()
    |> Enum.filter(fn {command_id, index} ->
      Enum.at(current_order, index) != command_id
    end)
    |> Enum.map(fn {command_id, _index} -> command_id end)
  end

  defp apply_event(%{event: %WormholeProtocol.TimelineOpened{}}, sectors), do: sectors

  defp apply_event(%{event: %WormholeProtocol.SectorRegistered{} = event}, sectors) do
    Map.put(sectors, event.sector_id, %{
      sector_id: event.sector_id,
      created_at: event.created_at,
      initial_oxygen: event.initial_oxygen,
      available_oxygen: event.initial_oxygen,
      allocations: [],
      latest_effective_at: event.created_at
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
          available_oxygen: sector.available_oxygen - event.amount,
          latest_effective_at: event.effective_at
      }
    end)
  end

  defp event_time(%{effective_at: effective_at}), do: effective_at
  defp event_time(%{created_at: created_at}), do: created_at
end
