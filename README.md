# Ogone

This gem helps you to quickly get a `form` that can be submitted and redirect
your users to the ogone ecommerce form where they can pay. This gem is flexible
as it does not rely on a hard-coded configuration to be used. Therefore you can
dynamically handle several PSPIDs.

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
  <% @ogone.fields_for_payment do |name, value| %>
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
      # TODO: update database with payment info.
    rescue Ogone::Ecommerce::OutboundSignatureMismatch
      # The request did not come from Ogone, or there is a misconfiguration of sha_out.
    end
  end
end
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
