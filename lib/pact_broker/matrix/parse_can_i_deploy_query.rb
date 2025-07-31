require "rack/utils"
require "pact_broker/matrix/unresolved_selector"

module PactBroker
  module Matrix
    class ParseCanIDeployQuery
      # rubocop: disable Metrics/CyclomaticComplexity
      def self.call params
        selector = PactBroker::Matrix::UnresolvedSelector.new
        options = {
          latestby: "cvp"
        }

        if params[:application].is_a?(String)
          selector.application_name = params[:application]
        end

        if params[:version].is_a?(String)
          selector.application_version_number = params[:version]
        end

        if params[:to].is_a?(String)
          options[:tag] = params[:to]
          options[:latest] = true
        end

        if params[:environment].is_a?(String)
          options[:environment_name] = params[:environment]
        end

        if params[:ignore].is_a?(Array)
          options[:ignore_selectors] = params[:ignore].collect do | param |
            if param.is_a?(String)
              PactBroker::Matrix::UnresolvedSelector.new(application_name: param)
            elsif param.is_a?(Hash) && param.key?(:application)
              PactBroker::Matrix::UnresolvedSelector.new({ application_name: param[:application], application_version_number: param[:version] }.compact)
            end
          end.compact
        else
          options[:ignore_selectors] = []
        end

        return [selector], options
      end
      # rubocop: enable Metrics/CyclomaticComplexity
    end
  end
end
