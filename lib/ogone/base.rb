require 'digest'

module Ogone
  class Base
    VALID_ENVIRONMENTS = %w[test prod].freeze unless const_defined? :VALID_ENVIRONMENTS
    SIGNING_ALGORITHMS = %w[SHA1 SHA256 SHA512].freeze unless const_defined? :SIGNING_ALGORITHMS

    class ConfigurationError < StandardError; end
    class MandatoryParameterMissing < StandardError; end
    class OutboundSignatureMismatch < StandardError; end

    attr_accessor :sha_in, :sha_out

    def initialize(options = {})
      @parameters = {}
      %i[sha_algo environment pspid sha_in sha_out].each do |config|
        send :"#{config}=", options[config] unless options[config].nil?
      end
    end

    def sha_algo=(sha_algo)
      raise ArgumentError, "Unsupported signature algorithm: #{sha_algo}" unless SIGNING_ALGORITHMS.include?(sha_algo)
      @sha_algo = sha_algo
    end

    def environment=(environment)
      unless VALID_ENVIRONMENTS.include? environment.to_s
        raise ArgumentError, "Unsupported Ogone environment: #{environment}"
      end
      @environment = environment
    end

    def pspid=(pspid)
      raise ArgumentError, 'PSPID cannot be empty' if pspid.nil? || pspid == ''
      @pspid = pspid
    end

    def add_parameters(parameters)
      @parameters.merge! parameters
    end

    def fields_for_payment(parameters = {}, shasign_key = 'SHASIGN')
      add_parameters(parameters || {})
      check_mandatory_parameters!

      upcase_keys(@parameters).merge(shasign_key.to_sym => sha_in_sign)
    end

    def check_shasign_out!(params)
      params = upcase_keys(params)
      raise OutboundSignatureMismatch if sha_out_sign(params) != params[:SHASIGN]
    end

    def upcase_keys(hash)
      hash.each_with_object({}) { |(k, v), h| h[k.upcase.to_sym] = v; }
    end

    def add_single_return_url(return_url)
      %i[ACCEPTURL DECLINEURL EXCEPTIONURL CANCELURL].each do |field|
        @parameters[field] = return_url
      end
    end

    protected

    def ogone_host
      @environment == 'test' ? 'ogone.test.v-psp.com' : 'secure.ogone.com'
    end

    private

    def sha_in_sign
      to_hash = sorted_upcased_parameters.each_with_object([]) do |(k, v), a|
        a << "#{k}=#{v}#{@sha_in}" unless v.nil? || v == ''
      end.join
      sign to_hash
    end

    def sha_out_sign(params)
      to_hash = self.class.const_get('OUTBOUND_SIGNATURE_PARAMETERS').each_with_object([]) do |p, a|
        a << "#{p}=#{params[p]}#{@sha_out}" unless params[p].nil? || params[p] == ''
      end.join
      sign to_hash
    end

    def sign(to_hash)
      unless SIGNING_ALGORITHMS.include?(@sha_algo)
        raise ArgumentError, "Unsupported signature algorithm: '#{@sha_algo}'"
      end
      Digest.const_get(@sha_algo).hexdigest(to_hash).upcase
    end

    def sorted_upcased_parameters
      upcase_keys(@parameters).sort
    end

    def check_mandatory_parameters!
      keys = @parameters.keys.map(&:to_sym)
      self.class.const_get('MANDATORY_PARAMETERS').each do |parameter|
        raise MandatoryParameterMissing, parameter unless keys.include? parameter.to_sym
      end
    end
  end
end
