defmodule CentrixCore.ReceptionParserTest do
  use ExUnit.Case

  alias CentrixCore.ReceptionParser

  setup do
    success_response = File.read!("test/fixtures/success_reception_response.xml")
    error_response = File.read!("test/fixtures/error_reception_response.xml")

    {:ok, success_response: success_response, error_response: error_response}
  end

  describe "parse_response/1" do
    test "parse_response/1 with success response", %{success_response: response} do
      assert {:ok, %{status: "RECIBIDA", response: response}} ==
               ReceptionParser.parse_response(response)
    end

    test "parse_response/1 with error response", %{error_response: response} do
      assert {:ok, %{status: "DEVUELTA", response: response}} ==
               ReceptionParser.parse_response(response)
    end

    test "parse_response/1 with error parsing" do
      assert {:error, "foo"} = ReceptionParser.parse_response("foo")
    end
  end
end
