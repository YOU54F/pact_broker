describe "Get applications" do

  let(:path) { "/applications" }
  let(:response_body_hash) { JSON.parse(subject.body, symbolize_names: true) }
  let(:expected_response_body) { { name: "Foo" } }

  subject { get(path) }

  context "when applications exist" do

    before do
      td.create_application("Foo")
        .create_application("Bar")
        .create_application("someOther")
    end

    it "returns a 200 OK" do
      expect(subject).to be_a_hal_json_success_response
    end

    it "does not to contain page details" do
      expect(response_body_hash).not_to have_key(:page)
    end

    context "with pagination options" do
      subject { get(path, { "size" => "2", "page" => "1" }) }

      it "only returns the number of items specified in the page" do
        expect(response_body_hash[:_links][:"applications"].size).to eq 2
      end

      it_behaves_like "a paginated response"
    end
  end
end

