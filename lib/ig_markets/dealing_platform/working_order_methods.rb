module IGMarkets
  class DealingPlatform
    # Provides methods for working with working orders. Returned by {DealingPlatform#working_orders}.
    class WorkingOrderMethods
      # Initializes this helper class with the specified dealing platform.
      #
      # @param [DealingPlatform] dealing_platform The dealing platform.
      def initialize(dealing_platform)
        @dealing_platform = WeakRef.new dealing_platform
      end

      # Returns all working orders.
      #
      # @return [Array<WorkingOrder>]
      def all
        @dealing_platform.session.get('workingorders', API_V2).fetch(:working_orders).map do |attributes|
          attributes = attributes.fetch(:working_order_data).merge market: attributes.fetch(:market_data)

          @dealing_platform.instantiate_models WorkingOrder, attributes
        end
      end

      # Returns the working order with the specified deal ID, or `nil` if there is no order with that deal ID.
      #
      # @param [String] deal_id The deal ID of the working order to return.
      #
      # @return [WorkingOrder]
      def [](deal_id)
        all.detect do |working_order|
          working_order.deal_id == deal_id
        end
      end

      # Creates a new working order with the specified attributes.
      #
      # @param [Hash] attributes The attributes for the new working order.
      # @option attributes [String] :currency_code The 3 character currency code, must be one of the instrument's
      #                    currencies (see {Instrument#currencies}). Required.
      # @option attributes [:buy, :sell] :direction Order direction. Required.
      # @option attributes [String] :epic The EPIC of the instrument for the order. Required.
      # @option attributes [Date] :expiry The expiry date of the instrument (if applicable). Optional.
      # @option attributes [Boolean] :force_open Whether a force open is required. Defaults to `true`.
      # @option attributes [Time] :good_till_date The date that the working order will live till. If not specified then
      #                    the working order will remain until it is cancelled.
      # @option attributes [Boolean] :guaranteed_stop Whether a guaranteed stop is required. Defaults to `false`.
      # @option attributes [Float] :level The level at which the order will be triggered. Required.
      # @option attributes [Integer] :limit_distance The distance away in pips to place the limit. If this is set then
      #                    the `:limit_level` option must be omitted. Optional.
      # @option attributes [Float] :limit_level The level at which to place the limit. If this is set then the
      #                    `:limit_distance` option must be omitted. Optional.
      # @option attributes [Float] :size The size of the working order. Required.
      # @option attributes [Integer] :stop_distance The distance away in pips to place the stop. If this is set then the
      #                    `:stop_level` option must be omitted. Optional.
      # @option attributes [Float] :stop_level The level at which to place the stop. If this is set then the
      #                    `:stop_distance` option must be omitted. Optional.
      # @option attributes [:limit, :stop] :type `:limit` means the working order is intended to buy at a price lower
      #                    than at present, or to sell at a price higher than at present, i.e. there is an expectation
      #                    of a market reversal at the specified `:level`. `:stop` means the working order is intended
      #                    to sell at a price lower than at present, or to buy at a price higher than at present, i.e.
      #                    there is no expectation of a market reversal at the specified `:level`. Required.
      #
      # @return [String] The resulting deal reference, use {DealingPlatform#deal_confirmation} to check the result of
      #         the working order creation.
      def create(attributes)
        model = WorkingOrderCreateAttributes.new attributes

        body = RequestBodyFormatter.format model, expiry: '-'

        @dealing_platform.session.post('workingorders/otc', body, API_V2).fetch :deal_reference
      end

      # Internal model used by {#create}.
      class WorkingOrderCreateAttributes < Model
        attribute :currency_code, String, regex: Regex::CURRENCY
        attribute :direction, Symbol, allowed_values: %i[buy sell]
        attribute :epic, String, regex: Regex::EPIC
        attribute :expiry, Date, format: '%d-%b-%y'
        attribute :force_open, Boolean
        attribute :good_till_date, Time, format: '%Y/%m/%d %R:%S'
        attribute :guaranteed_stop, Boolean
        attribute :level, Float
        attribute :limit_distance, Float
        attribute :limit_level, Float
        attribute :size, Float
        attribute :stop_distance, Float
        attribute :stop_level, Float
        attribute :time_in_force, Symbol, allowed_values: %i[good_till_cancelled good_till_date]
        attribute :type, Symbol, allowed_values: %i[limit stop]

        def initialize(attributes)
          super
          set_defaults
          validate
        end

        private

        def set_defaults
          self.force_open = true if force_open.nil?
          self.guaranteed_stop = false if guaranteed_stop.nil?
          self.time_in_force = good_till_date ? :good_till_date : :good_till_cancelled
        end

        # Runs a series of validations on this model's attributes to check whether it is ready to be sent to the IG
        # Markets API.
        def validate
          required = %i[currency_code direction epic guaranteed_stop level size time_in_force type]
          required.each do |attribute|
            raise ArgumentError, "#{attribute} attribute must be set" if send(attribute).nil?
          end

          if limit_distance && limit_level
            raise ArgumentError, 'do not specify both limit_distance and limit_level options'
          end

          raise ArgumentError, 'do not specify both stop_distance and stop_level options' if stop_distance && stop_level
        end
      end

      private_constant :WorkingOrderCreateAttributes
    end
  end
end
