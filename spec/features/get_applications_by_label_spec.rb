describe "Get applications by label" do

  let(:path) { "/applications/label/ios" }
  let(:response_body_hash) { JSON.parse(subject.body, symbolize_names: true) }
  let(:expected_response_body) { {name: "Foo"} }

  subject { get path; last_response }

  context "when the pacts exist" do

    before do
      TestDataBuilder.new
        .create_application("Foo")
        .create_label("ios")
        .create_application("Bar")
        .create_label("android")
    end

    it "returns a 200 OK" do
      expect(subject).to be_a_hal_json_success_response
    end

    it "returns a list of applications" do
      expect(response_body_hash[:_embedded][:applications].first).to include expected_response_body
    end
  end
end
