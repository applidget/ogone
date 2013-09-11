module Ogone

  STATUS = {
    0  => 'Incomplete or invalid',
    1  => 'Cancelled by client',
    2  => 'Authorization refused',
    4  => 'Order stored',
    41 => 'Waiting client payment',
    5  => 'Authorized',
    51 => 'Authorization waiting',
    52 => 'Authorization not known',
    55 => 'Stand-by',
    59 => 'Authoriz. to get manually',
    6  => 'Authorized and cancelled',
    61 => 'Author. deletion waiting',
    62 => 'Author. deletion uncertain',
    63 => 'Author. deletion refused',
    64 => 'Authorized and cancelled',
    7  => 'Payment deleted',
    71 => 'Payment deletion pending',
    72 => 'Payment deletion uncertain',
    73 => 'Payment deletion refused',
    74 => 'Payment deleted',
    75 => 'Deletion processed by merchant',
    8  => 'Refund',
    81 => 'Refund pending',
    82 => 'Refund uncertain',
    83 => 'Refund refused',
    84 => 'Payment declined by the acquirer',
    85 => 'Refund processed by merchant',
    9  => 'Payment requested',
    91 => 'Payment processing',
    92 => 'Payment uncertain',
    93 => 'Payment refused',
    94 => 'Refund declined by the acquirer',
    95 => 'Payment processed by merchant',
    99 => 'Being processed'
  } unless const_defined? :STATUS

  PAID_STATUSES = [4, 5, 9] unless const_defined? :PAID_STATUSES
  PENDING_STATUSES = [41, 51, 52, 91, 92, 99] unless const_defined? :PENDING_STATUSES
  CANCELLED_STATUSES = [1] unless const_defined? :CANCELLED_STATUSES
  REFUNDED_STATUSES = [8] unless const_defined? :REFUNDED_STATUSES

end