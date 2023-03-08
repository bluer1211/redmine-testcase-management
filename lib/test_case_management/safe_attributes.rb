module TestCaseManagement
  module SafeAttributes
    def safe_attribute_names(user=nil)
      names = super
      names << "project_id" if new_record?
      names
    end

    def safe_attributes=(attrs, user=User.current)
      if attrs.respond_to?(:to_unsafe_hash)
        attrs = attrs.to_unsafe_hash
      end

      @attributes_set_by = user
      return unless attrs.is_a?(Hash)

      attrs = attrs.deep_dup

      if (given_project = attrs.delete("project_id")) && safe_attribute?("project_id")
        if given_project.is_a?(String) && !/^\d*$/.match?(given_project)
          given_project_id = Project.find_by_identifier(given_project).try(:id)
        else
          given_project_id = given_project.to_i
        end
        if allowed_target_projects(user).where(:id => given_project_id).exists?
          self.project_id = given_project_id
        end
      end

      assign_attributes attrs
    end

    def assign_attributes(new_attributes, *args)
      return if new_attributes.nil?

      attrs = new_attributes.dup
      attrs.stringify_keys!

      %w(project project_id).each do |attr|
        if attrs.has_key?(attr)
          send "#{attr}=", attrs.delete(attr)
        end
      end
      super attrs, *args
    end

    def attributes=(new_attributes)
      assign_attributes new_attributes
    end
  end
end
