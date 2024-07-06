defmodule QuickConnect.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: QuickConnect.Supervisor]

    setup_wifi()

    children =
      [
        # Children for all targets
        # Starts a worker by calling: QuickConnect.Worker.start_link(arg)
        # {QuickConnect.Worker, arg},
      ] ++ children(target())

    Supervisor.start_link(children, opts)
  end

  if Mix.target() == :host do
    defp setup_wifi(), do: :ok
  else
    defp setup_wifi() do
      kv = Nerves.Runtime.KV.get_all()

      unless wlan0_configured?() do
        ssid = kv["quick_connect_wifi_ssid"]
        passphrase = kv["quick_connect_wifi_passphrase"]

        unless empty?(ssid) do
          _ = VintageNetWiFi.quick_configure(ssid, passphrase)
          :ok
        end
      end
    end

    defp wlan0_configured?() do
      "wlan0"
      |> VintageNet.get_configuration()
      |> VintageNetWiFi.network_configured?()
    catch
      _, _ -> false
    end

    defp empty?(""), do: true
    defp empty?(nil), do: true
    defp empty?(_), do: false
  end

  # List all child processes to be supervised
  def children(:host) do
    [
      # Children that only run on the host
      # Starts a worker by calling: QuickConnect.Worker.start_link(arg)
      # {QuickConnect.Worker, arg},
    ]
  end

  def children(_target) do
    [
      # Children for all targets except host
      # Starts a worker by calling: QuickConnect.Worker.start_link(arg)
      # {QuickConnect.Worker, arg},
    ]
  end

  def target() do
    Application.get_env(:connect_to_nerves_hub, :target)
  end
end
