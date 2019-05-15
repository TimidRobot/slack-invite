require 'spec_helper'

describe Invitation do
  let(:team) { Fabricate(:team, admin_token: 'token') }
  let!(:admin) { Fabricate(:user, team: team, is_admin: true) }
  let!(:user) { Fabricate(:user, team: team) }
  let(:invitation) { Fabricate(:invitation, team: team) }
  context 'send!' do
    it 'updates sent_at' do
      allow_any_instance_of(Slack::Web::Client).to receive(:users_admin_invite).with(email: invitation.email)
      expect {
        invitation.send!
      }.to change(invitation, :sent_at)
    end
  end
  context 'approve!' do
    it 'updates and sends' do
      expect(invitation).to receive(:send!)
      invitation.approve!(user)
      expect(invitation.handled_by).to eq user
    end
  end
  context 'ignore!' do
    it 'updates and does not send' do
      expect(invitation).to_not receive(:send!)
      invitation.ignore!(user)
      expect(invitation.handled_by).to eq user
    end
  end
  context 'request!' do
    it 'DMs admins' do
      expect_any_instance_of(User).to receive(:dm!).with(invitation.to_slack)
      invitation.request!
    end
  end
  context 'to_slack' do
    it 'returns a set of interactive buttons' do
      expect(invitation.to_slack).to eq(
        text: "Hi, #{invitation.name_and_email} is asking to join #{team.name}!",
        attachments: [
          callback_id: 'invitation',
          fallback: 'You cannot approve invitations.',
          attachment_type: 'default',
          actions: [{
            name: 'approve',
            text: 'Approve',
            type: 'button',
            value: invitation.id.to_s
          }, {
            name: 'ignore',
            text: 'Ignore',
            type: 'button',
            value: invitation.id.to_s
          }]
        ]
      )
    end
  end
end
