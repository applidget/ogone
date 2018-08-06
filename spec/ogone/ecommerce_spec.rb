require 'ogone/ecommerce'

module Ogone
  describe Ecommerce do
    before(:each) do
      @ogone = Ogone::Ecommerce.new
    end

    it 'should raise an error if incorrect sha algorithm given' do
      lambda { @ogone.sha_algo = 'WRONG_SHA' }.should raise_error ArgumentError
    end

    it 'should raise an error if incorrect ogone environment given' do
      lambda { @ogone.environment = 'WRONG_ENV' }.should raise_error ArgumentError
    end

    it 'should raise an error if an empty PSPID is specified' do
      lambda { @ogone.pspid = '' }.should raise_error ArgumentError
    end

    it 'should render the test Ogone url' do
      @ogone.environment = 'test'
      @ogone.form_action.should eq 'https://secure.ogone.com/ncol/test/orderstandard_utf8.asp'
    end

    it 'should render the production Ogone url' do
      @ogone.environment = 'prod'
      @ogone.form_action.should eq 'https://secure.ogone.com/ncol/prod/orderstandard_utf8.asp'
    end

    it 'should have the PSPID stored in the parameters' do
      @ogone.pspid = 'pspid'
      parameters[:PSPID].should eq 'pspid'
    end

    describe '#check_shasign_out!' do
      before(:each) do
        @ogone = Ogone::Ecommerce.new sha_out: 'sha_out', sha_algo: 'SHA1'
      end

      it 'should check an inbound signature' do
        params = ogone_return_parameters
        lambda { @ogone.check_shasign_out! params }.should_not raise_error Ogone::Ecommerce::OutboundSignatureMismatch
      end

      it 'should throw an error if the outbound shasign does not match' do
        params = {
          'amonut' => '160',
          'SHASIGN' => 'FOO'
        }
        lambda { @ogone.check_shasign_out! params }.should raise_error Ogone::Ecommerce::OutboundSignatureMismatch
      end
    end

    describe '#fields_for_payment' do
      before(:each) do
        @ogone = Ogone::Ecommerce.new pspid: 'pspid', sha_in: 'sha_in', sha_algo: 'SHA1'
      end

      it 'should give a hash ready to be used in `hidden_field_tag`' do
        fields = @ogone.fields_for_payment AMOUNT: 100,
                                           CURRENCY: 'EUR',
                                           ORDERID: '123',
                                           LANGUAGE: 'en_US'

        fields[:SHASIGN].should eq 'AA7CA1F98159D14D0943311092F5435F239B4B36'
      end

      it 'should also work if parameters were given with #add_parameters' do
        @ogone.add_parameters AMOUNT: 100, CURRENCY: 'EUR', ORDERID: '123', LANGUAGE: 'en_US'

        fields = @ogone.fields_for_payment
        fields[:SHASIGN].should eq 'AA7CA1F98159D14D0943311092F5435F239B4B36'
      end
    end

    describe '#add_single_return_url' do
      it 'should allow lazy folks to give just one back url' do
        @ogone.add_single_return_url 'http://iamsola.zy'
        parameters[:ACCEPTURL].should eq 'http://iamsola.zy'
        parameters[:DECLINEURL].should eq 'http://iamsola.zy'
        parameters[:EXCEPTIONURL].should eq 'http://iamsola.zy'
        parameters[:CANCELURL].should eq 'http://iamsola.zy'
      end
    end

    private

    def parameters
      @ogone.instance_variable_get :@parameters
    end

    # rubocop:disable Metrics/MethodLength
    def ogone_return_parameters
      {
        'orderID' => 'r_511b52f7230b430b3f000003_19',
        'currency' => 'EUR',
        'amount' => '160',
        'PM' => 'CreditCard',
        'ACCEPTANCE' => '',
        'STATUS' => '1',
        'CARDNO' => '',
        'ED' => '',
        'CN' => 'Sebastien Saunier',
        'TRXDATE' => '02/13/13',
        'PAYID' => '19113975',
        'NCERROR' => '',
        'BRAND' => '',
        'COMPLUS' => 'registration_511b52f7230b430b3f000003',
        'IP' => '80.12.86.33',
        'SHASIGN' => 'F3F5F963C700F56B69EA36173F5BFB3B28CA25E5'
      }
    end
    # rubocop:enable Metrics/MethodLength
  end
end
