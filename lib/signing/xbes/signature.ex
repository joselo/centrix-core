defmodule CentrixCore.Xbes.Signature do
  @moduledoc false

  alias CentrixCore.Xbes.Util

  def get(cfg, signed_info, signature_value, key_info, properties) do
    id = "Signature#{cfg.signature_number}"
    {attrs, _close_tag} = Util.attrs(id, true)

    {:"ds:Signature", attrs,
     [
       signed_info,
       {:"ds:SignatureValue", %{Id: "SignatureValue#{cfg.signature_value_number}"}, signature_value},
       key_info,
       {:"ds:Object", %{Id: "Signature#{cfg.signature_number}-Object#{cfg.object_number}"},
        [
          {:"etsi:QualifyingProperties", %{Target: "#Signature#{cfg.signature_number}"},
           [
             properties
           ]}
        ]}
     ]}
  end
end
