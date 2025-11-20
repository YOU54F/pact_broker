RSpec.describe "index resource", validate_oas: true do
  let(:rack_headers) { { "HTTP_ACCEPT" => "*/*" } }
  let(:path) { "/" }

  subject { get(path, nil, rack_headers) }

  it "returns a 200 response" do
    expect(subject.status).to eq 200
  end

  it "returns application/hal+json" do
    expect(subject.media_type).to eq "application/hal+json"
  end

  it "includes the expected HAL links" do
    body = JSON.parse(subject.body)
    expect(body).to have_key("_links")
    links = body["_links"]
    expect(links).to include("self")
    expect(links).to include("pb:publish-pact")
    expect(links).to include("pb:publish-contracts")
    expect(links).to include("pb:latest-pact-versions")
    expect(links).to include("pb:tagged-pact-versions")
    expect(links).to include("pb:pacticipants")
    expect(links).to include("pb:pacticipant")
    expect(links).to include("pb:latest-provider-pacts")
    expect(links).to include("pb:latest-provider-pacts-with-tag")
    expect(links).to include("pb:provider-pacts-with-tag")
    expect(links).to include("pb:provider-pacts")
    expect(links).to include("pb:latest-version")
    expect(links).to include("pb:latest-tagged-version")
    expect(links).to include("pb:webhooks")
    expect(links).to include("pb:webhook")
    expect(links).to include("pb:integrations")
    expect(links).to include("pb:pacticipant-version-tag")
    expect(links).to include("pb:pacticipant-branch")
    expect(links).to include("pb:pacticipant-branch-version")
    expect(links).to include("pb:pacticipant-version")
    expect(links).to include("pb:metrics")
    expect(links).to include("pb:can-i-deploy-pacticipant-version-to-tag")
    expect(links).to include("pb:can-i-deploy-pacticipant-version-to-environment")
    expect(links).to include("pb:provider-pacts-for-verification")
    expect(links).to include("beta:provider-pacts-for-verification")
    expect(links).to include("curies")
    expect(links).to include("pb:environments")
    expect(links).to include("pb:environment")
  end
end
