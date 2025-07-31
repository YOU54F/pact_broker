module PactBroker
  module Domain
    class Group < Array

      def initialize *index_items
        self.concat index_items.flatten
      end

      def == other
        Group === other && super
      end

      def include_application? application
        any? { | index_item | index_item.include? application }
      end

    end
  end
end
