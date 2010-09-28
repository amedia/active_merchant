module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    module Integrations #:nodoc:
      module DibsFlexwin
        class Helper < ActiveMerchant::Billing::Integrations::Helper
          include RequiresParameters
          include Common

          def initialize(order, account, options = {})
            requires!(options, :recurring, :security_key1, :security_key2)
            @recurring = options.delete(:recurring)
            @key1 = options.delete(:security_key1)
            @key2 = options.delete(:security_key2)
            super

            # Force usage of unique orderid. It will be better in the long run.
            add_field( mappings[:unique_orderid], "yes")
            add_field( "test", "yes") if ActiveMerchant::Billing::Base.integration_mode == :test
            security_key( true )
            make_preauth() if recurring?
          end

          def currency=( currency_code )
            raise StandardError, "Invalid currency code #{currency_code} specified." unless CURRENCY_CODES.include?(currency_code.to_s.downcase.to_sym)
            add_field(mappings[:currency], CURRENCY_CODES[currency_code.to_s.downcase.to_sym])
          end

          def amount=( amount )
            raise ArgumentError, 'Amount must be a positive integer in cents.' unless amount.is_a?(Fixnum)
            add_field( mappings[:amount], amount.to_i)
          end

          def language( lang )
            raise StandardError, "Unsupported language #{lang} specified." unless LANGUAGE_CODES.include?(lang)
            add_field(mappings[:language], lang)
          end

          def terminal_color( color )
            raise StandardError, "Unsupported color #{color} specified." unless TERMINAL_COLORS.include?(color)
            add_field(mappings[:terminal_color], color)
          end

          def force_payment_method( method )
            raise StandardError, "Unsupported payment method #{method} specified." unless PAYMENT_METHODS.include?(method)
            add_field( mappings[:force_payment_method], method)
          end

          def unique_orderid( use = true )
            # Force usage of unique orderid. It will be better in the long run.
            add_field( mappings[:unique_orderid], "Y")
          end

          def decorator( decorator )
            raise StandardError, "Unsupported decorator #{decorator} specified." unless DECORATOR_TYPES.include?(decorator)
            add_field( mappings[:decorator], decorator)
          end

          def security_key( use = true )
            delete_field( mappings[:security_key] ) and return unless use
            raise StandardError, "Missing :security_key1 or :security_key2." unless @key1 and @key2
            key = md5_checksum( @key1, @key2,
                                fields[mappings[:account]],
                                fields[mappings[:order]],
                                fields[mappings[:currency]],
                                fields[mappings[:amount]]
            )
            add_field( mappings[:security_key], key)
          end

          # Add advanced order lines. Format:
          # [["Product Name", "Quantity", "Price"],["iPod Nano", 4, 49], ["iPod Classic", 2, 299]]
          def order_lines( lines )
            raise ArgumentError, "Too many orderlines. Max 3 including headers" if lines.size > 3
            (0..lines.size-1).each do |i|
              raise ArgumentError, "Uneven columns in order line ##{i}. Should be 3 columns." unless lines[i].size == 3
              (0..lines[i].size).each do |j|
                add_field( "ordline#{i}-#{j+1}", lines[i][j] )
              end
            end
          end

          def make_preauth
            add_field( mappings[:preauth], "yes")
          end

          def make_ticket( use = false )
            raise NotImplementedError, "Make ticket doesn't support 3D Secure, unique order id and md5sum."
          end

          def recurring?
            @recurring ||= false
          end

          mapping :customer, :name => 'delivery1.Name', :comment => 'delivery3.Comment'
          mapping :billing_address, :street => 'delivery2.Address'

          mapping :account, 'merchant'
          mapping :department, 'account'
          mapping :amount, 'amount'
          mapping :order, 'orderid'
          mapping :currency, "currency"
          mapping :language, 'lang'
          mapping :calculate_fee, 'calcfee'
          mapping :notify_url, 'callbackurl'
          mapping :return_url, 'accepturl'
          mapping :cancel_return_url, 'cancelurl'
          mapping :description, 'ordertext'
          mapping :decorator, 'decorator'
          mapping :instant_capture, 'capturenow'
          mapping :ip, 'ip'
          mapping :unique_orderid, 'uniqueoid'
          mapping :http_cookie, 'HTTP_COOKIE'
          mapping :terminal_color, 'color'
          mapping :force_payment_method, 'paytype'
          mapping :skip_last_page, 'skiplastpage'
          mapping :security_key, 'md5key'
          mapping :make_ticket, 'maketicket'
          mapping :preauth, 'preauth'
        end
      end
    end
  end
end
