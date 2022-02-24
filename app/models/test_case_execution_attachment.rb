class TestCaseExecutionAttachment < Attachment
  belongs_to :container, :polymorphic => true
end
