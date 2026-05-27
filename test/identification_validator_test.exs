defmodule BillingCore.IdentificationValidatorTest do
  use ExUnit.Case, async: true

  alias BillingCore.IdentificationValidator

  describe "valid_identification?/2" do
    test "validates cedula" do
      assert IdentificationValidator.valid_identification?(:cedula, "1710034065") == :ok
      assert {:error, _} = IdentificationValidator.valid_identification?(:cedula, "1710034066")
    end

    test "validates ruc" do
      assert IdentificationValidator.valid_identification?(:ruc, "1710034065001") == :ok
      assert {:error, _} = IdentificationValidator.valid_identification?(:ruc, "1710034065000")
    end

    test "validates consumidor_final (to be implemented)" do
      assert IdentificationValidator.valid_identification?(:consumidor_final, "9999999999999") == :ok

      assert {:error, :invalid_consumidor_final} =
               IdentificationValidator.valid_identification?(:consumidor_final, "1234567890123")
    end

    test "validates pasaporte (to be implemented)" do
      assert IdentificationValidator.valid_identification?(:pasaporte, "ABC123456") == :ok
      assert IdentificationValidator.valid_identification?(:pasaporte, "any_string") == :ok
    end

    test "returns error for invalid input" do
      assert IdentificationValidator.valid_identification?(:cedula, 123) == {:error, :invalid_input}
    end
  end
end
