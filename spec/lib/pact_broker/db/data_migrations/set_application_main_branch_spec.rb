require "pact_broker/db/data_migrations/set_application_main_branch"

module PactBroker
  module DB
    module DataMigrations
      describe SetApplicationMainBranch, data_migration: true  do
        describe ".call" do
          before(:all) do
            PactBroker::TestDatabase.migrate(20210529)
          end

          let(:now) { DateTime.new(2018, 2, 2) }
          let!(:application_1) { create(:applications, { name: "P1", created_at: now, updated_at: now }) }
          let!(:application_2) { create(:applications, { name: "P2", created_at: now, updated_at: now }) }

          def create_version_with_tag(version_number, order, tag_name, application_id)
            version = create(:versions, { number: version_number, order: order, application_id: application_id, created_at: now, updated_at: now })
            create(:tags, { name: tag_name, application_id: application_id, version_id: version[:id], created_at: now, updated_at: now }, nil)
          end

          before do
            create_version_with_tag("1", 1, "main", application_1[:id])
            create_version_with_tag("2", 2, "main", application_1[:id])
            create_version_with_tag("3", 3, "develop", application_1[:id])
            create_version_with_tag("4", 4, "feat/x", application_1[:id])

            create_version_with_tag("5", 5, "foo", application_2[:id])
          end

          subject { SetApplicationMainBranch.call(database) }

          it "sets the main branch where it can" do
            subject
            expect(database[:applications].where(id: application_1[:id]).single_record[:main_branch]).to eq "main"
            expect(database[:applications].where(id: application_2[:id]).single_record[:main_branch]).to eq nil
          end
        end
      end
    end
  end
end
