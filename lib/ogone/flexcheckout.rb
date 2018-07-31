require 'ogone/base'

module Ogone
  class Flexcheckout < Base
    def mandatory_parameters
      %w(ACCOUNT.PSPID PARAMETERS.ACCEPTURL PARAMETERS.EXCEPTIONURL CARD.PAYMENTMETHOD LANGUAGE)
    end

    def outbound_signature_parameters
      %i(
        ALIAS.ALIASID
        ALIAS.NCERROR
        ALIAS.NCERRORCARDNO
        ALIAS.NCERRORCN
        ALIAS.NCERRORCVC
        ALIAS.NCERRORED
        ALIAS.ORDERID
        ALIAS.STATUS
        ALIAS.STOREPERMANENTLY
        CARD.BIC
        CARD.BIN
        CARD.BRAND
        CARD.CARDHOLDERNAME
        CARD.CARDNUMBER
        CARD.CVC
        CARD.EXPIRYDATE
      )
    end

    def pspid=(pspid)
      super(pspid)
      @parameters[:'ACCOUNT.PSPID'] = pspid
    end

    def fields_for_payment(parameters = {})
      super(parameters, 'SHASIGNATURE.SHASIGN')
    end

    def form_url
      "https://#{ogone_host}/Tokenization/HostedPage?#{URI.encode_www_form(fields_for_payment)}"
    end
  end
end
