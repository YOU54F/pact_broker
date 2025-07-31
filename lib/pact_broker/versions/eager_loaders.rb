module PactBroker
  module Versions
    module EagerLoaders
      class LatestVersionForApplication
        def self.call(eo, **_other)
          populate_associations(eo[:rows])
        end

        def self.populate_associations(versions)
          group_by_application(versions).each do | application, participant_versions |
            populate_associations_by_application(application, participant_versions)
          end
        end

        def self.group_by_application(versions)
          versions.to_a.group_by(&:application)
        end

        def self.populate_associations_by_application(application, versions)
          latest_version = versions.first.class.latest_version_for_application(application).single_record

          versions.each do | version |
            version.associations[:latest_version_for_application] = latest_version
          end
        end
      end
    end
  end
end
