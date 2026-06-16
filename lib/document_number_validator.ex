defmodule CentrixCore.DocumentNumberValidator do
  @moduledoc """
  Validates the format of Ecuadorian electronic document numbers.
  The format is: XXX-XXX-XXXXXXXXX (Establishment-EmissionPoint-Sequential).
  """

  @regex ~r/^\d{3}-\d{3}-\d{9}$/

  @doc """
  Returns true if the document number is valid, false otherwise.
  """
  def valid?(number) when is_binary(number) do
    Regex.match?(@regex, number)
  end

  def valid?(_), do: false

  @doc """
  Returns the regex used for validation.
  """
  def regex, do: @regex
end
