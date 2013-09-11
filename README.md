# Ogone

This gem helps you to quickly get a `form` that can be submitted and redirect
your users to the ogone ecommerce form where they can pay. This gem is flexible
as it does not rely on a hard-coded configuration to be used. Therefore you can
dynamically handle several PSPIDs.

## Installation

Add this line to your application's Gemfile:

    gem 'ogone'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ogone

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

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
