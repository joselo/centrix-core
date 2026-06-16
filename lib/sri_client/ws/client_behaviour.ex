defmodule CentrixCore.Ws.ClientBehaviour do
  @moduledoc false
  @callback post(String.t(), String.t()) :: tuple()
  @callback post(String.t(), String.t(), keyword()) :: tuple()
  @callback put(String.t(), String.t()) :: tuple()
end
