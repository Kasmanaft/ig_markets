require 'base64'
require 'date'
require 'json'
require 'securerandom'
require 'time'
require 'yaml'

require 'colorize'
require 'excon'
require 'lightstreamer'
require 'pry'
require 'terminal-table'
require 'thor'

require 'ig_markets/boolean'
require 'ig_markets/model'
require 'ig_markets/model/typecasters'
require 'ig_markets/regex'

require 'ig_markets/account'
require 'ig_markets/activity'
require 'ig_markets/api_versions'
require 'ig_markets/application'
require 'ig_markets/client_account_summary'
require 'ig_markets/client_sentiment'
require 'ig_markets/deal_confirmation'
require 'ig_markets/dealing_platform'
require 'ig_markets/dealing_platform/account_methods'
require 'ig_markets/dealing_platform/client_sentiment_methods'
require 'ig_markets/dealing_platform/market_methods'
require 'ig_markets/dealing_platform/position_methods'
require 'ig_markets/dealing_platform/sprint_market_position_methods'
require 'ig_markets/dealing_platform/watchlist_methods'
require 'ig_markets/dealing_platform/working_order_methods'
require 'ig_markets/errors'
require 'ig_markets/format'
require 'ig_markets/instrument'
require 'ig_markets/historical_price_result'
require 'ig_markets/market'
require 'ig_markets/market_overview'
require 'ig_markets/market_hierarchy_result'
require 'ig_markets/password_encryptor'
require 'ig_markets/position'
require 'ig_markets/request_body_formatter'
require 'ig_markets/request_printer'
require 'ig_markets/response_parser'
require 'ig_markets/session'
require 'ig_markets/sprint_market_position'
require 'ig_markets/transaction'
require 'ig_markets/version'
require 'ig_markets/watchlist'
require 'ig_markets/working_order'

require 'ig_markets/cli/commands/orders_command'
require 'ig_markets/cli/commands/positions_command'
require 'ig_markets/cli/commands/sprints_command'
require 'ig_markets/cli/commands/watchlists_command'
require 'ig_markets/cli/main'
require 'ig_markets/cli/config_file'
require 'ig_markets/cli/commands/account_command'
require 'ig_markets/cli/commands/activities_command'
require 'ig_markets/cli/commands/confirmation_command'
require 'ig_markets/cli/commands/console_command'
require 'ig_markets/cli/commands/markets_command'
require 'ig_markets/cli/commands/performance_command'
require 'ig_markets/cli/commands/prices_command'
require 'ig_markets/cli/commands/search_command'
require 'ig_markets/cli/commands/self_test_command'
require 'ig_markets/cli/commands/sentiment_command'
require 'ig_markets/cli/commands/stream_command'
require 'ig_markets/cli/commands/transactions_command'
require 'ig_markets/cli/tables/table'
require 'ig_markets/cli/tables/accounts_table'
require 'ig_markets/cli/tables/activities_table'
require 'ig_markets/cli/tables/client_sentiments_table'
require 'ig_markets/cli/tables/historical_price_result_snapshots_table'
require 'ig_markets/cli/tables/market_overviews_table'
require 'ig_markets/cli/tables/markets_table'
require 'ig_markets/cli/tables/performances_table'
require 'ig_markets/cli/tables/positions_table'
require 'ig_markets/cli/tables/sprint_market_positions_table'
require 'ig_markets/cli/tables/transactions_table'
require 'ig_markets/cli/tables/working_orders_table'

# This module contains all the code for the IG Markets gem. See `README.md` and the {DealingPlatform} class to get
# started with using this gem.
module IGMarkets
end
