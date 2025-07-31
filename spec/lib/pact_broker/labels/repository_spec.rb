require "pact_broker/labels/repository"

module PactBroker
  module Labels
    describe Repository do

      describe ".get_all_unique_labels" do
        before do
          td.create_application("bar")
            .create_label("ios")
            .create_application("foo")
            .create_label("android")
            .create_application("wiffle")
            .create_label("ios")
        end

        let(:labels_repository) { Repository.new }

        context "when there are no pagination options" do
          subject { labels_repository.get_all_unique_labels }

          it "returns all the unique ordered labels" do
            expect(subject.collect(&:name)).to contain_exactly("android", "ios")
          end
        end

        context "when there are pagination options" do
          let(:pagination_options) do
            {
              :page_number => 1,
              :page_size => 1
            }
          end
          subject { labels_repository.get_all_unique_labels pagination_options }

          it "returns paginated unique ordered labels" do
            expect(subject.collect(&:name)).to contain_exactly("android")
          end
        end
      end

      describe ".find" do

        let(:application_name) { "foo" }
        let(:label_name) { "ios" }

        subject { Repository.new }
        let(:options) { {application_name: application_name, label_name: label_name} }
        let(:find_label) { subject.find options }

        let!(:test_data_builder) do
          td
            .create_application("wiffle")
            .create_label(label_name)
            .create_application(application_name)
            .create_label("wrong label")
        end

        context "when the label exists" do

          before do
            test_data_builder.create_label(label_name)
          end

          it "returns the label" do
            expect(find_label.name).to eq label_name
            expect(find_label.application.name).to eq application_name
            expect(find_label.created_at).to be_datey
            expect(find_label.updated_at).to be_datey
          end

          context "when case sensitivity is turned off and a name with different case is used" do
            before do
              allow(PactBroker.configuration).to receive(:use_case_sensitive_resource_names).and_return(false)
            end

            let(:options) { {application_name: application_name.upcase, label_name: label_name.upcase} }

            it "returns the label" do
              expect(find_label).to_not be nil
              expect(find_label.name).to eq label_name
            end
          end

          context "when case sensitivity is turned on and a label name with different case is used" do
            before do
              allow(PactBroker.configuration).to receive(:use_case_sensitive_resource_names).and_return(true)
            end

            let(:options) { {application_name: application_name, label_name: label_name.upcase} }

            it "returns nil" do
              expect(find_label).to be nil
            end
          end

          context "when case sensitivity is turned on and a application name with different case is used" do
            before do
              allow(PactBroker.configuration).to receive(:use_case_sensitive_resource_names).and_return(true)
            end

            let(:options) { {application_name: application_name.upcase, label_name: label_name} }

            it "returns nil" do
              expect(find_label).to be nil
            end
          end
        end

        context "when the tag does not exist" do
          it "returns nil" do
            expect(find_label).to be_nil
          end
        end
      end

      describe "delete" do
        let(:application_name) { "foo" }
        let(:label_name) { "ios" }

        let!(:application) do
          td
            .create_application("Ignore")
            .create_label("ios")
            .create_application(application_name)
            .create_label("ios")
            .create_label("bar")
            .and_return(:application)
        end
        let(:options) { {application_name: application_name, label_name: label_name} }

        subject { Repository.new.delete(options) }

        it "deletes the label" do
          expect{ subject }.to change { PactBroker::Domain::Label.count }.by(-1)
        end
      end

      describe "delete_by_application_id" do
        let!(:application) do
          td
            .create_application("Ignore")
            .create_label("ios")
            .create_application("Foo")
            .create_label("ios")
            .create_label("bar")
            .and_return(:application)
        end

        subject { Repository.new.delete_by_application_id(application.id) }

        it "deletes the labels" do
          expect{ subject }.to change { PactBroker::Domain::Label.count }.by(-2)
        end
      end
    end
  end
end
