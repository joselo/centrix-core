defmodule BillingCore.SriClientTest do
  use ExUnit.Case
  use Mimic

  alias BillingCore.SriClient
  alias BillingCore.Ws.Client

  @environment 1

  describe "send_document/1" do
    setup do
      success_response = File.read!("test/fixtures/success_reception_response.xml")
      error_response = File.read!("test/fixtures/error_reception_response.xml")

      {:ok, success_response: success_response, error_response: error_response}
    end

    test "returns success response", %{success_response: success_response} do
      expect(Client, :post, fn _wsdl_url, _request -> {:ok, success_response} end)

      assert {:ok, %{status: "RECIBIDA"}} = SriClient.send_document("<xml />", @environment)
    end

    test "returns error 500" do
      expect(Client, :post, fn _wsdl_url, _request -> {:error, "some error"} end)

      assert {:error, _error} = SriClient.send_document("<xml />", @environment)
    end

    test "returns unknown error" do
      expect(Client, :post, fn _wsdl_url, _request -> {:error, "bad request"} end)

      assert {:error, _error} = SriClient.send_document("<xml />", @environment)
    end

    test "returns timeout" do
      expect(Client, :post, fn _wsdl_url, _request -> {:error, "timeout"} end)

      assert {:error, "timeout"} = SriClient.send_document("<xml />", @environment)
    end

    test "returns connection closed" do
      expect(Client, :post, fn _wsdl_url, _request -> {:error, "closed"} end)
      assert {:error, "closed"} = SriClient.send_document("<xml />", @environment)
    end
  end

  describe "is_authorized/1" do
    setup do
      success_response = File.read!("test/fixtures/success_authorization_response.xml")
      error_response = File.read!("test/fixtures/error_authorization_response.xml")
      unauthorized_response = File.read!("test/fixtures/unauthorized_response.xml")

      {:ok,
       success_response: success_response, error_response: error_response, unauthorized_response: unauthorized_response}
    end

    test "returns success response", %{success_response: success_response} do
      expect(Client, :post, fn _wsdl_url, _request -> {:ok, success_response} end)

      assert {:ok,
              %{
                status: "AUTORIZADO",
                response: _
              }} = SriClient.is_authorized("123456789", @environment)
    end

    test "is_authorized/1 with unauthorized response", %{
      unauthorized_response: unauthorized_response
    } do
      expect(Client, :post, fn _wsdl_url, _request -> {:ok, unauthorized_response} end)

      assert {:ok, %{status: "NO AUTORIZADO"}} =
               SriClient.is_authorized("123456789", @environment)
    end

    test "returns error 500" do
      expect(Client, :post, fn _wsdl_url, _request -> {:error, "some error"} end)

      assert {:error, _error} = SriClient.is_authorized("123456789", @environment)
    end

    test "returns unknown error" do
      expect(Client, :post, fn _wsdl_url, _request -> {:error, "bad request"} end)

      assert {:error, _error} = SriClient.is_authorized("123456789", @environment)
    end

    test "returns timeout" do
      expect(Client, :post, fn _wsdl_url, _request -> {:error, "timeout"} end)

      assert {:error, "timeout"} = SriClient.is_authorized("123456789", @environment)
    end

    test "returns connection closed" do
      expect(Client, :post, fn _wsdl_url, _request -> {:error, "closed"} end)

      assert {:error, "closed"} = SriClient.is_authorized("123456789", @environment)
    end
  end
end
