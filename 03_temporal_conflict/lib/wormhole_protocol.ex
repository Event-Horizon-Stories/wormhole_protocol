defmodule WormholeProtocol do
  @moduledoc """
  Public entry points for the Wormhole Command Protocol lessons.

  Lesson 3 adds a temporal conflict preview so the app can show how rewriting
  the past would change the present before the aggregate agrees to it.
  """

  alias WormholeProtocol.{Aggregates, CommandedApp, Commands, Events, Projectors}

  @doc """
  Dispatches a command through the Commanded application.
  """
  @spec dispatch(struct()) :: :ok | {:error, term()}
  def dispatch(command) do
    CommandedApp.dispatch(command, consistency: :strong)
  end

  @doc """
  Opens a timeline so commands can be routed to its aggregate stream.
  """
  @spec open_timeline(String.t()) :: :ok | {:error, term()}
  def open_timeline(timeline_id) do
    dispatch(%Commands.OpenTimeline{timeline_id: timeline_id})
  end

  @doc """
  Registers an oxygen sector in the timeline.
  """
  @spec register_sector(String.t(), String.t(), non_neg_integer(), String.t()) ::
          :ok | {:error, term()}
  def register_sector(timeline_id, sector_id, initial_oxygen, created_at) do
    dispatch(%Commands.RegisterSector{
      timeline_id: timeline_id,
      sector_id: sector_id,
      initial_oxygen: initial_oxygen,
      created_at: created_at
    })
  end

  @doc """
  Allocates oxygen within a single linear timeline.
  """
  @spec allocate_oxygen(String.t(), String.t(), pos_integer(), String.t(), keyword()) ::
          :ok | {:error, term()}
  def allocate_oxygen(timeline_id, sector_id, amount, effective_at, opts \\ []) do
    command_id =
      Keyword.get(opts, :command_id, "cmd-#{timeline_id}-#{sector_id}-#{effective_at}-#{amount}")

    dispatch(%Commands.AllocateOxygen{
      timeline_id: timeline_id,
      sector_id: sector_id,
      amount: amount,
      effective_at: effective_at,
      command_id: command_id
    })
  end

  @doc """
  Returns the aggregate state for a timeline.
  """
  @spec timeline_state!(String.t()) :: Aggregates.TimelineAggregate.t()
  def timeline_state!(timeline_id) do
    Commanded.aggregate_state(CommandedApp, Aggregates.TimelineAggregate, timeline_id)
  end

  @doc """
  Builds the first lesson scenario.
  """
  @spec linear_story!() :: map()
  def linear_story! do
    timeline_id = unique_timeline_id("linear")

    :ok = open_timeline(timeline_id)
    :ok = register_sector(timeline_id, "hab-3", 100, "09:50")
    :ok = allocate_oxygen(timeline_id, "hab-3", 40, "10:00", command_id: "alloc-1")
    :ok = allocate_oxygen(timeline_id, "hab-3", 20, "10:05", command_id: "alloc-2")

    state = timeline_state!(timeline_id)
    sector = state.sectors["hab-3"]

    %{
      timeline_id: timeline_id,
      facts: state.facts,
      sector: sector,
      available_oxygen: sector.available_oxygen,
      allocations: sector.allocations
    }
  end

  @doc """
  Demonstrates the first past-arriving command anomaly.
  """
  @spec anomaly_story!() :: map()
  def anomaly_story! do
    timeline_id = unique_timeline_id("anomaly")

    :ok = open_timeline(timeline_id)
    :ok = register_sector(timeline_id, "hab-3", 100, "09:50")
    :ok = allocate_oxygen(timeline_id, "hab-3", 40, "10:00", command_id: "alloc-1")
    :ok = allocate_oxygen(timeline_id, "hab-3", 20, "10:05", command_id: "alloc-2")

    anomaly =
      allocate_oxygen(timeline_id, "hab-3", 15, "09:55", command_id: "wormhole-1")

    state = timeline_state!(timeline_id)

    %{
      anomaly: anomaly,
      latest_effective_at: state.sectors["hab-3"].latest_effective_at,
      allocations: state.sectors["hab-3"].allocations
    }
  end

  @doc """
  Simulates what would happen if a wormhole command were inserted into the past.
  """
  @spec temporal_conflict_story!() :: map()
  def temporal_conflict_story! do
    timeline_id = unique_timeline_id("conflict")

    :ok = open_timeline(timeline_id)
    :ok = register_sector(timeline_id, "hab-3", 100, "09:50")
    :ok = allocate_oxygen(timeline_id, "hab-3", 70, "10:00", command_id: "alloc-1")
    :ok = allocate_oxygen(timeline_id, "hab-3", 20, "10:05", command_id: "alloc-2")

    state = timeline_state!(timeline_id)

    preview =
      Projectors.ReplayEngine.preview(
        state.facts,
        %Events.OxygenAllocated{
          timeline_id: timeline_id,
          sector_id: "hab-3",
          amount: 15,
          effective_at: "09:55",
          command_id: "wormhole-1"
        }
      )

    %{
      current_available_oxygen: state.sectors["hab-3"].available_oxygen,
      projected_available_oxygen: preview["hab-3"].available_oxygen,
      projected_allocations: preview["hab-3"].allocations,
      would_go_negative?: preview["hab-3"].available_oxygen < 0
    }
  end

  defp unique_timeline_id(prefix) do
    "#{prefix}-#{System.unique_integer([:positive, :monotonic])}"
  end
end
