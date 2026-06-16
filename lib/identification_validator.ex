defmodule CentrixCore.IdentificationValidator do
  @moduledoc """
  Pure logic for validating Ecuadorian identification numbers (Cédula, RUC, Consumidor Final and Pasaporte).
  Returns `:ok` or `{:error, reason}` where reason is an atom or a tuple.
  """

  @doc """
  Pure function to check if an identification is valid for a given type.
  """
  def valid_identification?(type, number) when is_binary(number) do
    case type do
      :cedula -> validate_cedula(number)
      :ruc -> validate_ruc(number)
      :consumidor_final -> validate_consumidor_final(number)
      :pasaporte -> :ok
      _ -> :ok
    end
  end

  def valid_identification?(_, _), do: {:error, :invalid_input}

  defp validate_consumidor_final("9999999999999"), do: :ok
  defp validate_consumidor_final(_), do: {:error, :invalid_consumidor_final}

  # --- Cédula Validation ---

  def validate_cedula(number) do
    with :ok <- check_length(number, 10),
         :ok <- check_digits_only(number),
         :ok <- check_province_code(number),
         :ok <- check_third_digit(number, :cedula) do
      do_validate_cedula(number)
    end
  end

  defp do_validate_cedula(number) do
    digits = to_digits(number)
    check_digit = List.last(digits)
    coefficients = [2, 1, 2, 1, 2, 1, 2, 1, 2]

    sum =
      digits
      |> Enum.take(9)
      |> Enum.zip(coefficients)
      |> Enum.map(fn {d, c} ->
        prod = d * c
        if prod >= 10, do: prod - 9, else: prod
      end)
      |> Enum.sum()

    verifier = if rem(sum, 10) == 0, do: 0, else: 10 - rem(sum, 10)

    if verifier == check_digit do
      :ok
    else
      {:error, :invalid_check_digit}
    end
  end

  # --- RUC Validation ---

  def validate_ruc(number) do
    with :ok <- check_length(number, 13),
         :ok <- check_digits_only(number),
         :ok <- check_province_code(number) do
      third_digit = number |> String.at(2) |> String.to_integer()

      case third_digit do
        d when d < 6 -> validate_ruc_natural(number)
        6 -> validate_ruc_public(number)
        9 -> validate_ruc_private(number)
        _ -> {:error, :invalid_third_digit}
      end
    end
  end

  defp validate_ruc_natural(number) do
    cedula_part = String.slice(number, 0, 10)
    suffix = String.slice(number, 10, 3)

    if suffix == "000" do
      {:error, :invalid_suffix}
    else
      case validate_cedula(cedula_part) do
        :ok -> :ok
        {:error, _} -> {:error, :invalid_natural_ruc}
      end
    end
  end

  defp validate_ruc_private(number) do
    digits = to_digits(number)
    check_digit = Enum.at(digits, 9)
    suffix = String.slice(number, 10, 3)

    if suffix == "000" do
      {:error, :invalid_suffix}
    else
      coefficients = [4, 3, 2, 7, 6, 5, 4, 3, 2]

      sum =
        digits
        |> Enum.take(9)
        |> Enum.zip(coefficients)
        |> Enum.map(fn {d, c} -> d * c end)
        |> Enum.sum()

      verifier = calculate_modulo11(sum)

      if verifier == check_digit do
        :ok
      else
        {:error, :invalid_private_ruc}
      end
    end
  end

  defp validate_ruc_public(number) do
    digits = to_digits(number)
    check_digit = Enum.at(digits, 8)
    suffix = String.slice(number, 9, 4)

    if suffix == "0000" do
      {:error, :invalid_suffix}
    else
      coefficients = [3, 2, 7, 6, 5, 4, 3, 2]

      sum =
        digits
        |> Enum.take(8)
        |> Enum.zip(coefficients)
        |> Enum.map(fn {d, d_coeff} -> d * d_coeff end)
        |> Enum.sum()

      verifier = calculate_modulo11(sum)

      if verifier == check_digit do
        :ok
      else
        {:error, :invalid_public_ruc}
      end
    end
  end

  # --- Helpers ---

  defp check_length(number, length) do
    if String.length(number) == length,
      do: :ok,
      else: {:error, {:invalid_length, length}}
  end

  defp check_digits_only(number) do
    if Regex.match?(~r/^\d+$/, number),
      do: :ok,
      else: {:error, :invalid_format}
  end

  defp check_province_code(number) do
    province = number |> String.slice(0, 2) |> String.to_integer()

    if (province >= 1 && province <= 24) || province == 30,
      do: :ok,
      else: {:error, :invalid_province_code}
  end

  defp check_third_digit(number, :cedula) do
    third = number |> String.at(2) |> String.to_integer()
    if third < 6, do: :ok, else: {:error, :invalid_third_digit}
  end

  defp calculate_modulo11(sum) do
    residue = rem(sum, 11)
    if residue == 0, do: 0, else: 11 - residue
  end

  defp to_digits(number) do
    number |> String.graphemes() |> Enum.map(&String.to_integer/1)
  end
end
