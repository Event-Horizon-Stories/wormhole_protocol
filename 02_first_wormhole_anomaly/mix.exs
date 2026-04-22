defmodule WormholeProtocol.MixProject do
  use Mix.Project

  def project do
    [
      app: :wormhole_protocol,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      preferred_envs: [precommit: :test]
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {WormholeProtocol.Application, []}
    ]
  end

  defp deps do
    [
      {:commanded, "~> 1.4"},
      {:jason, "~> 1.4"}
    ]
  end

  defp aliases do
    [
      precommit: ["format", "test"]
    ]
  end

  def cli do
    [preferred_envs: [precommit: :test]]
  end
end
