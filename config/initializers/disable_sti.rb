ActiveSupport.on_load(:active_record) do
  class ::ActiveRecord::Base
    # disable STI to allow columns named "type"
    self.inheritance_column = :_type_disabled
  end
end
