FactoryGirl.define do
  factory :transaction, class: IGMarkets::Transaction do
    cash_transaction false
    close_level '0.8'
    currency 'US'
    date '23/06/15'
    instrument_name 'instrument'
    open_level '0.8'
    period '-'
    profit_and_loss 'US-1.00'
    reference 'reference'
    size '+1'
    transaction_type 'DEAL'
  end
end