defmodule CentrixCore.Xbes.Cfg do
  @moduledoc false

  @enforce_keys [
    :certificate_number,
    :signature_number,
    :signed_properties_number,
    :signed_info_number,
    :signed_properties_id_number,
    :reference_id_number,
    :signature_value_number,
    :object_number,
    :signing_time,
    :signed_data_description,
    :crt_digest,
    :crt_issuer_name,
    :crt_serial_number,
    :crt_modulus,
    :crt_exponent,
    :crt_x509
  ]

  defstruct [
    :certificate_number,
    :signature_number,
    :signed_properties_number,
    :signed_info_number,
    :signed_properties_id_number,
    :reference_id_number,
    :signature_value_number,
    :object_number,
    :signing_time,
    :signed_data_description,
    :crt_digest,
    :crt_issuer_name,
    :crt_serial_number,
    :crt_modulus,
    :crt_exponent,
    :crt_x509
  ]
end
