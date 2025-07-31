describe "deleting unreferenced applications with no name", migration: true do
  before do
    PactBroker::TestDatabase.migrate(20220622)
  end

  let(:now) { DateTime.new(2017, 1, 1) }
  let!(:has_name) { create(:applications, { name: "aaa", created_at: now, updated_at: now }) }
  let!(:no_name_1) { create(:applications, { created_at: now, updated_at: now }) }
  let!(:no_name_2) { create(:applications, { created_at: now, updated_at: now }) }

  let!(:integration) { create(:integrations, { consumer_id: has_name[:id], provider_id: no_name_1[:id], created_at: now }) }

  it "deletes the application with no name that has no other rows referencing it" do
    expect(database[:applications].count).to eq 3
    expect(database[:applications].where(name: nil).count).to eq 2
    PactBroker::TestDatabase.migrate(20220625)
    expect(database[:applications].where(name: nil).count).to eq 0
    expect(database[:applications].count).to eq 2
  end
end
