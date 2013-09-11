module Ogone
  class Ecommerce
    VALID_ENVIRONMENTS = %w(test prod) unless const_defined? :VALID_ENVIRONMENTS
    SIGNING_ALGORITHMS = %w(SHA1 SHA256 SHA512) unless const_defined? :SIGNING_ALGORITHMS

    class ConfigurationError < StandardError; end

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

    def initialize(options = {})
      @parameters = Hash.new
      [:sha_algo, :environment, :pspid, :sha_in, :sha_out].each do |config|
        self.send :"#{config}=", options[config] unless options[config].nil?
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

    def form_action
      unless VALID_ENVIRONMENTS.include? @environment.to_s
        raise ConfigurationError.new("Unsupported Ogone environment: '#{@environment}'.")
      end
      "https://secure.ogone.com/ncol/#{@environment}/orderstandard_utf8.asp"
    end

    def add_single_return_url(return_url)
      [:ACCEPTURL, :DECLINEURL, :EXCEPTIONURL, :CANCELURL].each do |field|
        @parameters[field] = return_url
      end
    end

    def add_parameters(parameters)
      @parameters.merge! parameters
    end

    def fields_for_payment(parameters = {})
      add_parameters(parameters || {})
      check_mandatory_parameters!

      upcase_keys(@parameters).merge :SHASIGN => sha_in_sign
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
      unless SIGNING_ALGORITHMS.include?(@sha_algo)
        raise ArgumentError.new("Unsupported signature algorithm: '#{@sha_algo}'")
      end
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

  end
end