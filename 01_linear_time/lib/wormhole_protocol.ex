defmodule WormholeProtocol do
  @moduledoc """
  Public entry points for the Wormhole Command Protocol lessons.

  Lesson 1 establishes the linear-time baseline: commands express intent,
  events record what happened, and aggregate state is rebuilt from event
  history.
  """

  alias WormholeProtocol.{
    AllocateOxygen,
    CommandedApp,
    OpenTimeline,
    RegisterSector,
    TimelineAggregate
  }

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
    dispatch(%OpenTimeline{timeline_id: timeline_id})
  end

  @doc """
  Registers an oxygen sector in the timeline.
  """
  @spec register_sector(String.t(), String.t(), non_neg_integer(), String.t()) ::
          :ok | {:error, term()}
  def register_sector(timeline_id, sector_id, initial_oxygen, created_at) do
    dispatch(%RegisterSector{
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

    dispatch(%AllocateOxygen{
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
  @spec timeline_state!(String.t()) :: TimelineAggregate.t()
  def timeline_state!(timeline_id) do
    Commanded.aggregate_state(CommandedApp, TimelineAggregate, timeline_id)
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

  defp unique_timeline_id(prefix) do
    "#{prefix}-#{System.unique_integer([:positive, :monotonic])}"
  end
end
