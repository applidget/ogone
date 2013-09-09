require "ogone/ecommerce"

module Ogone
  describe Ecommerce do

    before(:each) do
      @ogone = Ogone::Ecommerce.new :pspid => "pspid", :sha_in => "sha_in", :sha_out => "sha_out", :sha_algo => "SHA1", :environment => "test"
    end

    it "should throw an error if incorrect sha algorithm given" do
      lambda { @ogone.sha_algo = 'WRONG_SHA' }.should raise_error ArgumentError
    end

    it "should throw an error if incorrect ogone environment given" do
      lambda { @ogone.environment = 'WRONG_ENV' }.should raise_error ArgumentError
    end

    it "should render the test Ogone url" do
      @ogone.form_action.should eq "https://secure.ogone.com/ncol/test/orderstandard_utf8.asp"
    end

    it "should render the production Ogone url" do
      @ogone.environment = 'prod'
      @ogone.form_action.should eq "https://secure.ogone.com/ncol/prod/orderstandard_utf8.asp"
    end

    it "should have the PSPID stored in the parameters" do
      parameters[:PSPID].should eq 'pspid'
    end

    it "should check an inbound signature" do
      params = ogone_return_parameters
      lambda { @ogone.check_shasign_out! params }.should_not raise_error Ogone::Ecommerce::OutboundSignatureMismatch
    end

    it "should throw an error if the outbound shasign does not match" do
      params = {
        "amonut" => "160",
        "SHASIGN" => "FOO"
      }
      lambda { @ogone.check_shasign_out! params }.should raise_error Ogone::Ecommerce::OutboundSignatureMismatch
    end

    private

    def parameters
      @ogone.instance_variable_get :@parameters
    end

    def ogone_return_parameters
      {
        "orderID" => "r_511b52f7230b430b3f000003_19",
        "currency" => "EUR",
        "amount" => "160",
        "PM" => "CreditCard",
        "ACCEPTANCE" => "",
        "STATUS" => "1",
        "CARDNO" => "",
        "ED" => "",
        "CN" => "Sebastien Saunier",
        "TRXDATE" => "02/13/13",
        "PAYID" => "19113975",
        "NCERROR" => "",
        "BRAND" => "",
        "COMPLUS" => "registration_511b52f7230b430b3f000003",
        "IP" => "80.12.86.33",
        "SHASIGN" => "F3F5F963C700F56B69EA36173F5BFB3B28CA25E5",
        "action" => "ogone_return",
        "controller" => "public/registrations",
        "locale" => "fr",
        "event_id" => "5118c7d4230b430f56000005",
        "guest_category_id" => "5118c7d4230b430f56000008"
      }
    end
  end
end