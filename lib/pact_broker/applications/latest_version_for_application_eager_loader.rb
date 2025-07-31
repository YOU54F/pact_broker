module PactBroker
  module Applications
    class LatestVersionForApplicationEagerLoader
      def self.call(eo, **_other)
        populate_associations(eo[:rows])
      end

      def self.populate_associations(applications)
        applications.each { | application | application.associations[:latest_version] = nil }
        application_ids = applications.collect(&:id)

        max_orders = PactBroker::Domain::Version
                      .where(application_id: application_ids)
                      .select_group(:application_id)
                      .select_append { max(order).as(latest_order) }

        max_orders_join = {
          Sequel[:max_orders][:latest_order] => Sequel[:versions][:order],
          Sequel[:max_orders][:application_id] => Sequel[:versions][:application_id]
        }

        latest_versions = PactBroker::Domain::Version
                            .select_all_qualified
                            .join(max_orders, max_orders_join, { table_alias: :max_orders})

        latest_versions.each do | version |
          application = applications.find{ | p | p.id == version.application_id }
          application.associations[:latest_version] = version
        end
      end
    end
  end
end
