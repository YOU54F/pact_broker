describe "Creating a application" do
  let(:path) { "/applications" }
  let(:headers) { {"CONTENT_TYPE" => "application/json"} }
  let(:response_body) { JSON.parse(last_response.body, symbolize_names: true)}
  let(:application_hash) do
    {
      name: "Foo Thing",
      mainBranch: "main",
      repositoryUrl: "http://url",
      repositoryName: "foo-thing",
      repositoryNamespace: "some-group"
    }
  end

  subject { post(path, application_hash.to_json, headers) }

  it "returns a 201 response" do
    subject
    expect(last_response.status).to be 201
  end

  it "returns the Location header" do
    subject
    expect(last_response.headers["Location"]).to eq "http://example.org/pacticpants/Foo%20Thing"
  end

  it "returns a JSON Content Type" do
    subject
    expect(last_response.headers["Content-Type"]).to eq "application/hal+json;charset=utf-8"
  end

  it "returns the newly created application" do
    subject
    expect(response_body).to include application_hash
  end

  context "with an empty JSON document" do
    let(:application_hash) { {} }

    its(:status) { is_expected.to eq 400 }
  end
end
