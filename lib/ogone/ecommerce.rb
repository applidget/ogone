require 'digest/sha1'
require 'digest/sha2'

module Ogone
  class Ecommerce
    VALID_ENVIRONMENTS = %w(test prod) unless const_defined? :VALID_ENVIRONMENTS
    SIGNING_ALGORITHMS = %w(SHA1 SHA256 SHA512) unless const_defined? :SIGNING_ALGORITHMS

    MANDATORY_PARAMETERS = %w(PSPID ORDERID AMOUNT CURRENCY LANGUAGE) unless const_defined? :MANDATORY_PARAMETERS
    class MandatoryParameterMissing < StandardError; end

    OUTBOUND_SIGNATURE_PARAMETERS = %w(AAVADDRESS AAVCHECK AAVZIP ACCEPTANCE ALIAS AMOUNT BIN \
                                       BRAND CARDNO CCCTY CN COMPLUS CREATION_STATUS CURRENCY \
                                       CVCCHECK DCC_COMMPERCENTAGE DCC_CONVAMOUNT DCC_CONVCCY \
                                       DCC_EXCHRATE DCC_EXCHRATESOURCE DCC_EXCHRATETS DCC_INDICATOR \
                                       DCC_MARGINPERCENTAGE DCC_VALIDHOURS DIGESTCARDNO ECI ED \
                                       ENCCARDNO FXAMOUNT FXCURRENCY IP IPCTY NBREMAILUSAGE NBRIPUSAGE\
                                       NBRIPUSAGE_ALLTX NBRUSAGE NCERROR ORDERID PAYID PM SCO_CATEGORY \
                                       SCORING STATUS SUBBRAND SUBSCRIPTION_ID TRXDATE VC).collect &:to_sym unless const_defined? :OUTBOUND_SIGNATURE_PARAMETERS
    class OutboundSignatureMismatch < StandardError; end

    attr_accessor :sha_in, :sha_out

    def initialize(options)
      @parameters = Hash.new
      [:sha_algo, :environment, :pspid].each do |config|
        self.send :"#{config}=", options[config]
      end
    end

    def add_parameters(parameters)
      parameters.each do |key, value|
        method = key.to_s.downcase.to_sym
        if self.respond_to? method
          self.send :"#{method}=", value
        else
          @parameters[key] = value
        end
      end
    end

    def sha_algo=(sha_algo)
      unless SIGNING_ALGORITHMS.include?(sha_algo)
        raise ArgumentError.new("Unsupported signature algorithm: #{sha_algo}")
      end
      @sha_algo = sha_algo
    end

    def environment=(environment)
      unless VALID_ENVIRONMENTS.include? environment.to_s
        raise ArgumentError.new("Unsupported Ogone environment: #{environment}")
      end
      @environment = environment
    end

    def pspid=(pspid)
      raise ArgumentError.new("PSPID cannot be empty") if pspid.nil? || pspid == ""
      @parameters[:PSPID] = pspid
    end

    def amount=(amount)
      @parameters[:AMOUNT] = (amount * 100).round  # Need to pass the price in cents
    end

    def form_action
      "https://secure.ogone.com/ncol/#{@environment}/orderstandard_utf8.asp"
    end

    def add_single_return_url(return_url)
      [:ACCEPTURL, :DECLINEURL, :EXCEPTIONURL, :CANCELURL].each do |field|
        @parameters[field] = return_url
      end
    end

    def hidden_fields
      check_mandatory_parameters!

      fields = []
      sorted_upcased_parameters.each do |key, value|
        fields << hidden_field_tag(key, value)
      end
      fields << hidden_field_tag(:SHASIGN, sha_in_sign)

      # Fields not to be included in the sha signature
      fields << hidden_field_tag(:HOME, "NONE")  # No 'Back to merchant store' button
      # TODO(ssaunier):
      # - CATALOGURL
      # - BACKURL

      fields
    end

    def check_shasign_out!(params)
      params = upcase_keys(params)
      raise OutboundSignatureMismatch.new if sha_out_sign(params) != params[:SHASIGN]
    end

    private

    def sha_in_sign
      to_hash = sorted_upcased_parameters.inject([]) {
                  |a, (k, v)| a << "#{k}=#{v}#{@sha_in}" unless v.nil? || v == ""
                  a
                }.join
      sign to_hash
    end

    def sha_out_sign(params)
      to_hash = OUTBOUND_SIGNATURE_PARAMETERS.inject([]) {
                  |a, p| a << "#{p}=#{params[p]}#{@sha_out}" unless params[p].nil? || v == ""
                  a
                }.join
      sign to_hash
    end

    def sign(to_hash)
      Digest.const_get(@sha_algo).hexdigest(to_hash).upcase
    end

    def sorted_upcased_parameters
      upcase_keys(@parameters).sort
    end

    def upcase_keys(hash)
      hash.inject({}) { |h, (k, v)| h[k.upcase.to_sym] = v; h }
    end

    def check_mandatory_parameters!
      MANDATORY_PARAMETERS.each do |parameter|
        unless @parameters.include? parameter.to_sym
          raise MandatoryParameterMissing.new parameter
        end
      end
    end

    def hidden_field_tag(name, value)
      if defined?(ActionView)
        ActionView::Helpers::FormTagHelper.hidden_field_tag(name, value)
      else
        "<input type=\"hidden\" name=\"#{name}\" value=\"#{value} />"
      end
    end

  end
end