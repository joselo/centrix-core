defmodule CentrixCore.AuthorizationParserTest do
  use ExUnit.Case

  alias CentrixCore.AuthorizationParser

  setup do
    success_response = File.read!("test/fixtures/success_authorization_response.xml")
    error_response = File.read!("test/fixtures/error_authorization_response.xml")
    unauthorized_response = File.read!("test/fixtures/unauthorized_response.xml")

    unauthorized_response_without_state =
      File.read!("test/fixtures/unauthorized_response_without_state.xml")

    {:ok,
     success_response: success_response,
     error_response: error_response,
     unauthorized_response: unauthorized_response,
     unauthorized_response_without_state: unauthorized_response_without_state}
  end

  describe "parse_response/1" do
    test "returns success response", %{success_response: response} do
      assert {:ok, %{status: "AUTORIZADO", response: _response}} =
               AuthorizationParser.parse_response(response)
    end

    test "returns rejected response", %{error_response: response} do
      assert {:ok, %{status: "RECHAZADA", response: _response}} =
               AuthorizationParser.parse_response(response)
    end

    test "returns unauthorized response", %{unauthorized_response: response} do
      assert {:ok, %{status: "NO AUTORIZADO", response: _response}} =
               AuthorizationParser.parse_response(response)
    end

    test "returns unauthorized response if the response state is nil or empty", %{
      unauthorized_response_without_state: response
    } do
      assert {:ok, %{status: "NO ENCONTRADO O PENDIENTE", response: _response}} =
               AuthorizationParser.parse_response(response)
    end

    test "returns error parsing " do
      assert {:error, "foo"} == AuthorizationParser.parse_response("foo")
    end
  end
end
