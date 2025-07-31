require "sequel/plugins/insert_ignore"
require "sequel"

module Sequel
  module Plugins
    module InsertIgnore
      class ApplicationNoInsertIgnore < Sequel::Model(:applications)
        plugin :timestamps, update_on_create: true
      end

      class Application < Sequel::Model
        plugin :insert_ignore, identifying_columns: [:name]
        plugin :timestamps, update_on_create: true
      end

      class Version < Sequel::Model
        plugin :insert_ignore, identifying_columns: [:application_id, :number]
        plugin :timestamps, update_on_create: true
      end

      context "when a duplicate is inserted with no insert_ignore" do
        before do
          ApplicationNoInsertIgnore.new(name: "Foo").save
        end

        subject do
          ApplicationNoInsertIgnore.new(name: "Foo").save
        end

        it "raises an error" do
          expect { subject }.to raise_error Sequel::UniqueConstraintViolation
        end
      end

      # This doesn't work on MSQL because the _insert_raw method
      # does not return the row ID of the duplicated row when insert_ignore is used
      # May have to go back to the old method of doing this
      context "when a duplicate Application is inserted with insert_ignore" do
        before do
          Application.new(name: "Foo", repository_url: "http://foo").insert_ignore
        end

        subject do
          Application.new(name: "Foo").insert_ignore
        end

        it "does not raise an error" do
          expect { subject }.to_not raise_error
        end

        it "sets the values on the object" do
          expect(subject.repository_url).to eq "http://foo"
        end

        it "does not insert another row" do
          expect { subject }.to_not change { Application.count }
        end
      end

      context "when a duplicate Version is inserted with insert_ignore" do
        let!(:application) { Application.new(name: "Foo").save }
        let!(:original_version) { Version.new(number: "1", application_id: application.id).insert_ignore }

        subject do
          Version.new(number: "1", application_id: application.id).insert_ignore
        end

        it "does not raise an error" do
          expect { subject }.to_not raise_error
        end

        it "sets the values on the object" do
          expect(subject.id).to eq original_version.id
        end

        it "does not insert another row" do
          expect { subject }.to_not change { Version.count }
        end
      end
    end
  end
end
