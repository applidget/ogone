# Ogone

This gem helps you to quickly get a `form` that can be submitted and redirect
your users to the ogone ecommerce form where they can pay. This gem is flexible
as it does not rely on a hard-coded configuration to be used. Therefore you can
dynamically handle several PSPIDs.

You can also use Flexcheckout combined with direct order (see Flexcheckout and direct order).

## Usage

In your controller,

```ruby
require "ogone"

class PaymentController
  def ogone_form
    @ogone = Ogone::Ecommerce.new :pspid => "your_pspid",
                                  :environment => "prod",
                                  :sha_algo => "SHA1",  # Configured in your back-office
                                  :sha_in => "......",  # Configured in your back-office
                                  :sha_out => "....."   # Configured in your back-office

    # Add mandatory parameters. Alternatively can be passed directly in `@ogone.fields_for_payment`
    @ogone.add_parameters(
      :CURRENCY => "EUR",
      :AMOUNT => 2000,  # Beware, that would be 20 EUR
      :ORDERID => "...",
      :LANGUAGE => "en_US"
      # And many more parameters, refer to the Ogone documentation
    )

    # Configure where the user should be redirected once the payment is completed
    # This sets the following urls:
    #  - ACCEPTURL
    #  - DECLINEURL
    #  - EXCEPTIONURL
    #  - CANCELURL
    @ogone.add_single_return_url "http://your_application/route/to/ogone/return"
  end
end
```

Then in your view, you can quickly get the form up and running:

```erb
<%# ogone_form.html.erb %>

<%= form_tag @ogone.form_action, :method => :post %>
  <% @ogone.fields_for_payment.each do |name, value| %>
    <%= hidden_field_tag name, value %>
  <% end %>

  <%= submit_tag "Pay" %>
<% end %>
```

When clicking on the `Pay` button, your user will be redirected to the Ogone
Ecommerce platform to enter his/her credit card info and pay. When the payment
is completed, the user will be redirected to your application.

This will be done via a `POST` request from Ogone to your app. This request contains
parameters that Ogone gives to you so that you can update your own database. Before
doing anything, you should check that the request signature is correct to make sure
it comes from Ogone. To do so, just call:

```ruby
require "ogone"

class PaymentController
  def ogone_return
    @ogone = Ogone::Ecommerce.new :sha_algo => "SHA1", :sha_out => "...."

    begin
      @ogone.check_shasign_out! params

      status = params[:STATUS].to_i
      if Ogone::PAID_STATUSES.include? status
        # TODO: update database with payment info.
      end
    rescue Ogone::Ecommerce::OutboundSignatureMismatch
      # The request did not come from Ogone, or there is a misconfiguration of sha_out.
    end
  end
end
```

## Flexcheckout and direct order

```ruby
@ogone = Ogone::Flexcheckout.new opts # same options than Ogone::Ecommerce

@ogone.add_parameters(
  'CARD.PAYMENTMETHOD' => 'CreditCard',
  'PARAMETERS.ACCEPTURL' => 'http://my_app/ogone_flexcheckout_success',
  'PARAMETERS.EXCEPTIONURL' => 'http://my_app/ogone_flexcheckout_failure',
  'LANGUAGE' => 'en_US',
)

@ogone.form_url # this is the URL with the Flexcheckout form, you shoudl redirect_to it
```

Once you fill the form, Ogone will redirect to the `ACCEPTURL` or `EXCEPTIONURL`. If you go to the `ACCEPTURL`,
you can proceed with the order :

```ruby
# first ensure sha_out matches
@ogone = Ogone::Flexcheckout.new opts # same options than Ogone::Ecommerce
@ogone.check_shasign_out!(params)

# ok sha_out matches proceed to the order
@ogone = Ogone::OrderDirect.new opts # same options than Ogone::Ecommerce

@ogone.add_parameters(
  'ORDERID' => params['Alias.OrderId'],
  'AMOUNT' => 10 * 100,
  'CURRENCY' => 'EUR',
  'ALIAS' => params['Alias.AliasId'], # comes from the HTTP params set in the flexcheckout redirect
  'USERID' => 'my_api_user', # you need to have an API user https://payment-services.ingenico.com/int/en/ogone/support/guides/integration%20guides/directlink
  'PSWD' => 'super_secret@',
  'OPERATION' => 'RES'
  # extra parameters may be set for 3D Secure : https://payment-services.ingenico.com/int/en/ogone/support/guides/integration%20guides/directlink-3-d/3-d-transaction-flow-via-directlink#comments
)

result = @ogone.perform_order

# handle result
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
