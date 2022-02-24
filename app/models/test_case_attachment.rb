class TestCaseAttachment < Attachment
  belongs_to :container, :polymorphic => true
end
