module Ogone
  class Base
    VALID_ENVIRONMENTS = %w(test prod) unless const_defined? :VALID_ENVIRONMENTS
    SIGNING_ALGORITHMS = %w(SHA1 SHA256 SHA512) unless const_defined? :SIGNING_ALGORITHMS

    class ConfigurationError < StandardError; end
    class MandatoryParameterMissing < StandardError; end
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
      raise ArgumentError.new('PSPID cannot be empty') if pspid.nil? || pspid == ''
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
      raise OutboundSignatureMismatch.new if sha_out_sign(params) != params[:SHASIGN]
    end

    def upcase_keys(hash)
      hash.inject({}) { |h, (k, v)| h[k.upcase.to_sym] = v; h }
    end

    def mandatory_parameters
      raise 'method not implemented'
    end

    def outbound_signature_parameters
      raise 'method not implemented'
    end

    protected

    def ogone_host
      @environment == 'test' ? 'ogone.test.v-psp.com' : 'secure.ogone.com'
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
      to_hash = outbound_signature_parameters.inject([]) {
                  |a, p| a << "#{p}=#{params[p]}#{@sha_out}" unless params[p].nil? || params[p] == ""
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

    def check_mandatory_parameters!
      simbolysed_parameters = @parameters.symbolize_keys
      mandatory_parameters.each do |parameter|
        unless simbolysed_parameters.include? parameter.to_sym
          raise MandatoryParameterMissing.new parameter
        end
      end
    end
  end
end