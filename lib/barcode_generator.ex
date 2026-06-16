defmodule CentrixCore.BarcodeGenerator do
  @moduledoc """
  Generates a Code128 barcode PNG from a string and saves it to a temp file.
  Returns {:ok, path} or {:error, reason}.
  """

  @doc """
  Generates a Code128 barcode for the given `value` and writes it to a
  temporary file. Returns `{:ok, path}` on success.
  """
  def generate(value) when is_binary(value) do
    path = tmp_path()

    try do
      value
      |> Barlix.Code128.encode!()
      |> Barlix.PNG.print(file: path, xdim: 1, height: 50)

      {:ok, path}
    rescue
      e -> {:error, Exception.message(e)}
    end
  end

  defp tmp_path do
    Path.join(System.tmp_dir!(), "barcode_#{:erlang.unique_integer([:positive])}.png")
  end
end
