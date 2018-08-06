require 'ogone/base'

module Ogone
  class OrderDirect < Base
    MANDATORY_PARAMETERS = %w[
      PSPID
      ORDERID
      AMOUNT
      CURRENCY
      ALIAS
      USERID
      PSWD
      OPERATION
    ].freeze

    def pspid=(pspid)
      super(pspid)
      @parameters[:PSPID] = pspid
    end

    def perform_order
      url = "https://#{ogone_host}/ncol/#{@environment}/orderdirect.asp"
      res = HTTParty.get("#{url}?#{URI.encode_www_form(fields_for_payment)}")
      res.body
    end
  end
end
