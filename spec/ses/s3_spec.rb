# TODO: Allow to wait until the spec is true
# TODO: Parse the bucket setup from terraform.tfstate
# TODO: Figure out how to send email
require 'awspec'

context "should have s3 bucket for emails" do
  describe s3_bucket('co-partner-reports') do
    it { should exist }
    it { should have_object('emails/1ql5d1ki6qm5qdgo6e2r5rdp1nmb3gjv4n1l6r81') }
    it { should_not have_object('emails/not-existing-thing') }
  end
end
