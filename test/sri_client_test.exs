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

  describe "check_health/2" do
    setup do
      reception_response = File.read!("test/fixtures/error_reception_response.xml")
      authorization_response = File.read!("test/fixtures/unauthorized_response.xml")

      {:ok, reception_response: reception_response, authorization_response: authorization_response}
    end

    test "returns :up for both when they respond with valid SOAP responses", %{
      reception_response: reception_response,
      authorization_response: authorization_response
    } do
      expect(Client, :post, 2, fn url, _body, _opts ->
        cond do
          String.contains?(url, "Recepcion") -> {:ok, reception_response}
          String.contains?(url, "Autorizacion") -> {:ok, authorization_response}
        end
      end)

      assert {:ok, %{reception: :up, authorization: :up}} = SriClient.check_health(@environment)
    end

    test "returns :down for reception if reception request fails", %{
      authorization_response: authorization_response
    } do
      expect(Client, :post, 2, fn url, _body, _opts ->
        cond do
          String.contains?(url, "Recepcion") -> {:error, "timeout"}
          String.contains?(url, "Autorizacion") -> {:ok, authorization_response}
        end
      end)

      assert {:ok, %{reception: :down, authorization: :up}} = SriClient.check_health(@environment)
    end

    test "returns :down for authorization if authorization request fails", %{
      reception_response: reception_response
    } do
      expect(Client, :post, 2, fn url, _body, _opts ->
        cond do
          String.contains?(url, "Recepcion") -> {:ok, reception_response}
          String.contains?(url, "Autorizacion") -> {:error, "closed"}
        end
      end)

      assert {:ok, %{reception: :up, authorization: :down}} = SriClient.check_health(@environment)
    end

    test "returns :down for both if both fail" do
      expect(Client, :post, 2, fn _url, _body, _opts -> {:error, "timeout"} end)

      assert {:ok, %{reception: :down, authorization: :down}} = SriClient.check_health(@environment)
    end
  end
end
