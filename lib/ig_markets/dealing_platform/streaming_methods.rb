module IGMarkets
  class DealingPlatform
    # Provides methods for working with streaming of IG Markets data. Returned by {DealingPlatform#streaming}.
    class StreamingMethods
      # Initializes this class with the specified dealing platform.
      #
      # @param [DealingPlatform] dealing_platform The dealing platform.
      def initialize(dealing_platform)
        @dealing_platform = dealing_platform
        @queue = Queue.new
      end

      # Connects the streaming session. Raises a `Lightstreamer::LightstreamerError` if an error occurs.
      def connect
        @lightstreamer.disconnect if @lightstreamer
        @queue.clear

        @lightstreamer = Lightstreamer::Session.new username: username, password: password, server_url: server_url
        @lightstreamer.on_error(&method(:on_error))

        @lightstreamer.connect
      end

      # Disconnects the streaming session.
      def disconnect
        @lightstreamer.disconnect if @lightstreamer
        @lightstreamer = nil
      end

      # Creates a new Lightstreamer subscription for balance updates on the specified account(s). The returned
      # `Lightstreamer::Subscription` must be passed to {#start_subscriptions} in order to actually start streaming its
      # data.
      #
      # @param [Array<#account_id>, nil] accounts The accounts to create a subscription for. If this is `nil` then the
      #        new subscription will apply to all the accounts for the active client.
      #
      # @return [Lightstreamer::Subscription]
      def build_accounts_subscription(accounts = nil)
        accounts ||= @dealing_platform.client_account_summary.accounts

        items = accounts.map { |account| "ACCOUNT:#{account.account_id}" }
        fields = [:available_cash, :available_to_deal, :deposit, :equity, :funds, :margin, :pnl]

        build_subscription items, fields, :merge, :on_account_data
      end

      # Creates a new Lightstreamer subscription for updates to the specified market(s). The returned
      # `Lightstreamer::Subscription` must be passed to {#start_subscriptions} in order to actually start streaming its
      # data.
      #
      # @param [Array<String>] epics The EPICs of the markets to create a subscription for.
      #
      # @return [Lightstreamer::Subscription]
      def build_markets_subscription(epics)
        items = epics.map { |epic| "MARKET:#{epic}" }
        fields = [:bid, :high, :low, :mid_open, :odds, :offer, :strike_price]

        build_subscription items, fields, :merge, :on_market_data
      end

      # Creates a new Lightstreamer subscription for trade, position and working order updates on the specified
      # account(s). The returned `Lightstreamer::Subscription` must be passed to {#start_subscriptions} in order to
      # actually start streaming its data.
      #
      # @param [Array<#account_id>, nil] accounts The accounts to create a subscription for. If this is `nil` then the
      #        new subscription will apply to all the accounts for the active client.
      #
      # @return [Lightstreamer::Subscription]
      def build_trades_subscription(accounts = nil)
        accounts ||= @dealing_platform.client_account_summary.accounts

        items = accounts.map { |account| "TRADE:#{account.account_id}" }
        fields = [:confirms, :opu, :wou]

        build_subscription items, fields, :distinct, :on_trade_data
      end

      # Creates a new Lightstreamer subscription for chart tick data for the specified EPICs. The returned
      # `Lightstreamer::Subscription` must be passed to {#start_subscriptions} in order to actually start streaming its
      # data.
      #
      # @param [Array<String>] epics The EPICs of the markets to create a chart tick data subscription for.
      #
      # @return [Lightstreamer::Subscription]
      def build_chart_ticks_subscription(epics)
        items = epics.map { |epic| "CHART:#{epic}:TICK" }
        fields = [:bid, :day_high, :day_low, :day_net_chg_mid, :day_open_mid, :day_perc_chg_mid, :ltp, :ltv, :ofr, :ttv,
                  :utm]

        build_subscription items, fields, :distinct, :on_chart_tick_data
      end

      # Creates a new Lightstreamer subscription for consolidated chart data for the specified EPIC and scale. The
      # returned `Lightstreamer::Subscription` must be passed to {#start_subscriptions} in order to actually start
      # streaming its data.
      #
      # @param [String] epic The EPIC of the market to create a consolidated chart data subscription for.
      # @param [:one_second, :one_minute, :five_minutes, :one_hour] scale The scale of the consolidated data.
      #
      # @return [Lightstreamer::Subscription]
      def build_consolidated_chart_data_subscription(epic, scale)
        scale = { one_second: 'SECOND', one_minute: '1MINUTE', five_minutes: '5MINUTE', one_hour: 'HOUR' }.fetch scale
        items = ["CHART:#{epic}:#{scale}"]

        fields = [:bid_close, :bid_high, :bid_low, :bid_open, :cons_end, :cons_tick_count, :day_high, :day_low,
                  :day_net_chg_mid, :day_open_mid, :day_perc_chg_mid, :ltp_close, :ltp_high, :ltp_low, :ltp_open, :ltv,
                  :ofr_close, :ofr_high, :ofr_low, :ofr_open, :ttv, :utm]

        build_subscription items, fields, :merge, :on_consolidated_chart_data
      end

      # Starts streaming data from the passed Lightstreamer subscriptions. The return value indicates the error state,
      # if any, for each subscription.
      #
      # @param [Array<Lightstreamer::Subscription>] subscriptions
      # @param [Hash] options The options to start the subscriptions with. See the documentation for
      #        `Lightstreamer::Subscription#start` for details of the accepted options.
      #
      # @return [Array<Lightstreamer::LightstreamerError, nil>] An array with one entry per subscription which indicates
      #         the error state returned for that subscription's start request, or `nil` if no error occurred.
      def start_subscriptions(subscriptions, options = {})
        @lightstreamer.bulk_subscription_start subscriptions, options
      end

      # Stops streaming data for the specified subscription. It can be restarted later using {start_subscriptions}.
      #
      # @param [Lightstreamer::Subscription] subscription The subscription to stop.
      def stop_subscription(subscription)
        @lightstreamer.remove_subscription subscription
      end

      # Returns the next piece of streaming data, or `nil` if there is no active streaming session. If there is no new
      # streaming data available then this method will block the calling thread until some is available. The return
      # value can take several forms. If an error occurs then a `Lightstreamer::Error` subclass will be returned. If a
      # new piece of data is available then a hash will be returned with a key of `:new_data`, and also `:merged_data`
      # for updates containing account data, market data, or consolidated chart data.
      #
      # The data will be an instance of {Streaming::AccountUpdate}, {Streaming::MarketUpdate}, {DealConfirmation},
      # {Streaming::PositionUpdate}, {Streaming::WorkingOrderUpdate}, {Streaming::ConsolidatedChartDataUpdate} or
      # {Streaming::ChartTickUpdate}.
      #
      # @return [Hash, Lightstreamer::LightstreamerError, nil]
      def pop_data
        return nil unless @lightstreamer && @lightstreamer.connected?

        @queue.pop
      end

      # Returns whether there is streaming data available and waiting to be read off the queue with {#pop_data}.
      #
      # @return [Boolean]
      def data_available?
        !@queue.empty?
      end

      private

      def username
        @dealing_platform.client_account_summary.client_id
      end

      def password
        "CST-#{@dealing_platform.session.client_security_token}|XST-#{@dealing_platform.session.x_security_token}"
      end

      def server_url
        @dealing_platform.client_account_summary.lightstreamer_endpoint
      end

      def on_error(error)
        @queue.push error
      end

      def build_subscription(items, fields, mode, on_data_method)
        subscription = @lightstreamer.build_subscription items: items, fields: fields, mode: mode
        subscription.on_data(&method(on_data_method))
        subscription
      end

      def on_account_data(_subscription, item_name, item_data, new_data)
        item_data = @dealing_platform.instantiate_models Streaming::AccountUpdate, item_data
        new_data = @dealing_platform.instantiate_models Streaming::AccountUpdate, new_data

        item_data.account_id = item_name.match(/^ACCOUNT:(.*)$/).captures.first
        new_data.account_id = item_data.account_id

        @queue.push data: new_data, merged_data: item_data
      end

      def on_market_data(_subscription, item_name, item_data, new_data)
        item_data = @dealing_platform.instantiate_models Streaming::MarketUpdate, item_data
        new_data = @dealing_platform.instantiate_models Streaming::MarketUpdate, new_data

        item_data.epic = item_name.match(/^MARKET:(.*)$/).captures.first
        new_data.epic = item_data.epic

        @queue.push data: new_data, merged_data: item_data
      end

      def on_trade_data(_subscription, item_name, _item_data, new_data)
        account_id = item_name.match(/^TRADE:(.*)$/).captures.first

        { confirms: DealConfirmation,
          opu: Streaming::PositionUpdate,
          wou: Streaming::WorkingOrderUpdate }.each do |key, model_class|

          next unless new_data[key]

          data = @dealing_platform.instantiate_models_from_json model_class, new_data[key]
          data.account_id = account_id

          @queue.push data: data
        end
      end

      def on_chart_tick_data(_subscription, item_name, _item_data, new_data)
        new_data = @dealing_platform.instantiate_models Streaming::ChartTickUpdate, new_data

        new_data.epic = item_name.match(/^CHART:(.*):TICK$/).captures.first

        @queue.push data: new_data
      end

      def on_consolidated_chart_data(_subscription, item_name, item_data, new_data)
        item_data = @dealing_platform.instantiate_models Streaming::ConsolidatedChartDataUpdate, item_data
        new_data = @dealing_platform.instantiate_models Streaming::ConsolidatedChartDataUpdate, new_data

        captures = item_name.match(/^CHART:(.*):(SECOND|1MINUTE|5MINUTE|HOUR)$/).captures
        item_data.epic = new_data.epic = captures[0]
        item_data.scale = new_data.scale = { 'SECOND' => :one_second, '1MINUTE' => :one_minute,
                                             '5MINUTE' => :five_minutes, 'HOUR' => :one_hour }.fetch captures[1]

        @queue.push data: new_data, merged_data: item_data
      end
    end
  end
end