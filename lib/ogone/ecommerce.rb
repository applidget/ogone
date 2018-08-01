require 'ogone/base'

module Ogone
  class Ecommerce < Base
    MANDATORY_PARAMETERS = %w[PSPID ORDERID AMOUNT CURRENCY LANGUAGE].freeze

    OUTBOUND_SIGNATURE_PARAMETERS = %i[
      AAVADDRESS
      AAVCHECK
      AAVZIP
      ACCEPTANCE
      ALIAS
      AMOUNT
      BIN
      BRAND
      CARDNO
      CCCTY
      CN
      COMPLUS
      CREATION_STATUS
      CURRENCY
      CVCCHECK
      DCC_COMMPERCENTAGE
      DCC_CONVAMOUNT
      DCC_CONVCCY
      DCC_EXCHRATE
      DCC_EXCHRATESOURCE
      DCC_EXCHRATETS
      DCC_INDICATOR
      DCC_MARGINPERCENTAGE
      DCC_VALIDHOURS
      DIGESTCARDNO
      ECI
      ED
      ENCCARDNO
      FXAMOUNT
      FXCURRENCY
      IP
      IPCTY
      NBREMAILUSAGE
      NBRIPUSAGE
      NBRIPUSAGE_ALLTX
      NBRUSAGE
      NCERROR
      ORDERID
      PAYID
      PM
      SCO_CATEGORY
      SCORING
      STATUS
      SUBBRAND
      SUBSCRIPTION_ID
      TRXDATE
      VC
    ].freeze

    def pspid=(pspid)
      super(pspid)
      @parameters[:PSPID] = pspid
    end

    def form_action
      unless VALID_ENVIRONMENTS.include? @environment.to_s
        raise ConfigurationError, "Unsupported Ogone environment: '#{@environment}'."
      end
      "https://secure.ogone.com/ncol/#{@environment}/orderstandard_utf8.asp"
    end

    def add_single_return_url(return_url)
      %i[ACCEPTURL DECLINEURL EXCEPTIONURL CANCELURL].each do |field|
        @parameters[field] = return_url
      end
    end
  end
end
